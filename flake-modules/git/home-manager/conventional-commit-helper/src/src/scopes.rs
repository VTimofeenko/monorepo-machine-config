use anyhow::{Context, Result};
use git2::Repository;
use log::debug;
use regex::Regex;
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use crate::common::PrintableEntity;

/// Returns the possible commit scopes.
/// Possible sources:
/// * Per-project file in .dev/commit-scopes
/// * Parsed from git commit history
///
/// Note that there is no default list of scopes -- they are per-project by definition
pub fn try_get_scopes_from_repo_at_path<P>(repo_path: P) -> Result<Vec<PrintableEntity>>
where
    P: Into<PathBuf> + AsRef<Path> + std::fmt::Debug,
{
    debug!("Looking for repository at {:?}...", &repo_path);
    // If discover fails, there's a problem with the repo
    let repo = Repository::discover(repo_path)?;
    debug!("Success! Found the repo at {:?}", repo.workdir());

    // Ok, we have a proper repo
    // Get the list of scopes defined in a special file
    debug!("Getting the project-specific scopes...");
    let project_commit_scopes: Vec<PrintableEntity> = get_scopes_from_file(
        repo.workdir()
            .expect("Could not find root dir of the repo. Is the repo bare?")
            .join(".dev/commit-scopes.json"),
    )?;

    debug!("Getting the scopes from git history...");
    let commit_scopes_from_history: Vec<PrintableEntity> = get_scopes_from_commit_history(&repo);

    // Remove scopes if there is already a scope with a description
    // It might be worth using a hashset for this (turn per_project_scopes into a hashset and
    // append scopes from commit history), but that would require overriding hashing function
    // for PrintableEntity which is kinda meh.

    debug!("Merging the scopes from git history with the project-specific ones");
    let known_scope_names: Vec<String> = project_commit_scopes
        .iter()
        .map(|x| x.clone().name)
        .collect();
    let filtered_scopes_from_commit_history = commit_scopes_from_history
        .iter()
        .filter(|x| !known_scope_names.contains(&x.name))
        .cloned()
        .collect();

    let mut scopes = [project_commit_scopes, filtered_scopes_from_commit_history].concat();
    scopes.sort();

    debug!("Success! Returning the final list of scopes");
    Ok(scopes)
}

/// Retrieves list of scopes from a file
fn get_scopes_from_file<P>(file_path: P) -> Result<Vec<PrintableEntity>>
where
    P: Into<PathBuf> + AsRef<Path> + std::fmt::Debug,
{
    debug!("Loading the scopes from project file");
    let file_contents = &fs::read_to_string(&file_path)
        .with_context(|| format!("Failed to read {:?}", file_path))?;
    let scopes: Vec<PrintableEntity> = serde_json::from_str(file_contents)?;

    Ok(scopes)
}

/// Given a single commit message, tries to find a scope in it
fn get_scope_from_commit_message(message: &str) -> Option<String> {
    // Regex to find the scope
    // Typically scopes are found in the brackets:
    // refactor(conventional-commit-helper): Change CommitType -> PrintableEntity to make it more generic
    let scope_finder_regex = Regex::new(r"\w+\((.*)\).*").unwrap();

    // The point is "Find the first match of a capture group. If it exists -- return it as Some.
    // Otherwise return None"
    // This is a bit ugly, there's probably a better way to destructure this.
    let (_, [captured]) = match scope_finder_regex.captures_iter(message).next() {
        Some(x) => x.extract(),
        None => return None,
    };

    Some(captured.to_string())
}

/// Retrieves potential matches of scopes from the git history
fn get_scopes_from_commit_history(repo: &Repository) -> Vec<PrintableEntity> {
    let reflog = repo.reflog("HEAD").unwrap();

    reflog
        .iter()
        .filter_map(|entry| get_scope_from_commit_message(entry.message().unwrap()))
        // dedup by turning it into a hashset
        .collect::<HashSet<String>>()
        .iter()
        // Turn into needed structs
        .map(|x| PrintableEntity {
            name: x.to_string(),
            description: "".to_string(),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use git2::{Oid, Signature};
    use rstest::rstest;
    use testdir::testdir;

    /// Checks extraction of scope from commit message
    #[rstest]
    #[case::present("foo(bar): baz", Some("bar".to_string()))]
    #[case::absent("foo: baz", None)]
    fn can_extract_scope_from_commit_msg(#[case] msg: &str, #[case] result: Option<String>) {
        assert!(get_scope_from_commit_message(msg) == result)
    }

    /// Create and extract scopes from a file
    #[rstest]
    fn default_fallback() {
        let tmpdir = testdir!();
        let path = tmpdir.join("scopes.json");

        // Manually construct scopes.json
        std::fs::write(&path, r#"[ { "name": "foo", "description": "" } ]"#).ok();

        let expected_scope = "foo";

        let read_scopes: Vec<PrintableEntity> = get_scopes_from_file(path).unwrap();

        // Truns the output into a single string, checks that the expected scope is in it
        assert!(read_scopes
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join("\n")
            .contains(expected_scope))
    }

    /// Set up a fake repo with commits based on the argument
    /// tmpdir is passed as a param so that it's created in the calling test
    fn setup_repo_with_commits(tmpdir: &Path, commit_msgs: &[&str]) -> Repository {
        let repo = Repository::init(tmpdir).unwrap();

        let mut parent_commit: Option<Oid> = None;

        commit_msgs.iter().for_each(|commit_msg| {
            let file_path = tmpdir.join("helloworld");
            fs::write(file_path, commit_msg).unwrap();

            let mut index = repo.index().unwrap();
            let _ = index.add_path(Path::new("helloworld"));
            let _ = index.write();

            let sig = Signature::now("nobody", "nobody@example.com").unwrap();

            let tree_id = index.write_tree().unwrap();

            let tree = repo.find_tree(tree_id).unwrap();

            let parents = match parent_commit {
                Some(parent_id) => vec![repo.find_commit(parent_id).unwrap()],
                None => vec![], // No parent for the first commit
            };
            let commit_id = repo
                .commit(
                    Some("HEAD"),                        // Update HEAD
                    &sig,                                // Author
                    &sig,                                // Committer
                    commit_msg,                          // Commit message
                    &tree,                               // Tree
                    &parents.iter().collect::<Vec<_>>(), // Parent commits
                )
                .unwrap();

            // Update the parent_commit for the next iteration
            parent_commit = Some(commit_id);
        });

        repo
    }

    /// Creates a fake repo, populates it with commits and then extracts scopes
    #[rstest]
    #[case::no_commits(vec![], vec![])]
    #[case::one_commit_one_scope(vec!["feat(foo): bar"], vec!["foo"])]
    #[case::many_commits_one_scope(vec!["feat(foo): bar", "foz"], vec!["foo"])]
    #[case::many_commits_many_scopes(vec!["feat(foo): bar", "feat(foz): baz"], vec!["foo", "foz"])]
    fn extract_scopes_from_commit_history(
        #[case] commit_history: Vec<&str>,
        #[case] expected_scope_names: Vec<&str>,
    ) {
        // Prepare a test repo
        let repo = setup_repo_with_commits(&testdir!(), &commit_history);

        // Extract scopes
        let extracted_scopes: Vec<PrintableEntity> = get_scopes_from_commit_history(&repo);

        let extracted_scope_names: Vec<String> =
            extracted_scopes.iter().map(|x| x.name.to_owned()).collect();

        // Check that the extracted_scope_names and expected_scope_names contain same elements
        assert!(extracted_scope_names
            .iter()
            .all(|x| expected_scope_names.contains(&x.as_str())))
    }

    /// Creates a fake repo with a per-project scope file
    /// Check that the scopes from history are appended (if needed)
    #[rstest]
    #[case::no_commits_merge(vec![], vec!["foo"])]
    // This testcase tests deduplication
    #[case::one_commit_one_scope_one_result(vec!["feat(foo): bar"], vec!["foo"])]
    // This testcase tests concatenation
    #[case::one_commit_one_scope_two_results(vec!["feat(foz): bar"], vec!["foo", "foz"])]
    fn merge_scopes_from_commit_history(
        #[case] commit_history: Vec<&str>,
        #[case] expected_scope_names: Vec<&str>,
    ) {
        // Prepare a test repo
        let tmpdir = testdir!();
        let _ = setup_repo_with_commits(&tmpdir, &commit_history);

        // Manually construct realistic commit-scopes.json
        let path = tmpdir.join(".dev/commit-scopes.json");
        let _ = fs::create_dir_all(path.parent().unwrap());
        std::fs::write(path, r#"[ { "name": "foo", "description": "" } ]"#).ok();

        // Extract scopes
        let extracted_scopes: Vec<PrintableEntity> =
            try_get_scopes_from_repo_at_path(tmpdir).unwrap();

        let extracted_scope_names: Vec<String> =
            extracted_scopes.iter().map(|x| x.name.to_owned()).collect();

        // Check that the extracted_scope_names and expected_scope_names contain same elements
        assert!(extracted_scope_names
            .iter()
            .all(|x| expected_scope_names.contains(&x.as_str())))
    }

    /// Create a fake repo with a per-project scope file
    /// Make sure the scope from the scope file "wins" when merging
    #[rstest]
    fn check_desc_from_file_wins() {
        // Prepare a test repo
        let tmpdir = testdir!();
        let _ = setup_repo_with_commits(&tmpdir, &["foz(foo): bar"]);

        // Manually construct realistic commit-scopes.json
        let path = tmpdir.join(".dev/commit-scopes.json");
        let _ = fs::create_dir_all(path.parent().unwrap());
        std::fs::write(path, r#"[ { "name": "foo", "description": "some desc" } ]"#).ok();

        assert_eq!(
            try_get_scopes_from_repo_at_path(tmpdir).unwrap(),
            vec![PrintableEntity {
                name: "foo".to_owned(),
                description: "some desc".to_owned()
            }]
        )
    }
}
