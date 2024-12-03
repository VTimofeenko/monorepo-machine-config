use anyhow::{bail, Result};
use git2::Repository;
use log::debug;
use std::fs::File;
use std::io::BufReader;
use std::path::{Path, PathBuf};

use crate::common::{try_resolve_path_in_repo, PrintableEntity};

/// Retrieve repo-specific commit types. Fall back to bundled types.
pub fn try_get_types_from_repo_at_path<P>(
    repo_path: P,
    config_path: Option<P>,
) -> Result<Vec<PrintableEntity>>
where
    P: Into<PathBuf> + AsRef<Path> + std::fmt::Debug,
{
    // Repo may or may not exist
    // The config_path that is passed here

    debug!("Looking for repository at {:?}...", &repo_path);
    // If discover fails, just ignore it.
    // In future I might want to distinguish between "program ran without any parameters and
    // repo-path is explicitly specified -- so the user has some expectations"
    // Path 1: repo does not exist,
    let repo: Option<Repository> = match Repository::discover(repo_path) {
        Ok(x) => Some(x),
        Err(_) => None,
    };

    match config_path {
        Some(config_path_unwrapped) => {
            if let Some(project_specific_commit_types) =
                get_repo_specific_commit_types(repo, &config_path_unwrapped.into())?
            {
                debug!("Found the repo-specific commit types, returning them");
                return Ok(project_specific_commit_types);
            };
        }
        None => {
            debug!("No project-specific type file passed. Returning only the default commit types");
            return Ok(get_default_commit_types());
        }
    };

    debug!("Returning only the default commit types");
    Ok(get_default_commit_types())
}

fn get_default_commit_types() -> Vec<PrintableEntity> {
    debug!("Retrieving the bundled commit types");
    let bundled_types_file = include_str!("types.json");
    // If bundled commit types are bad -- we have a huge problem, panic.
    let bundled_commit_types: Vec<PrintableEntity> =
        serde_json::from_str(bundled_types_file).unwrap();

    bundled_commit_types
}

/// Returns the project-specific list of commit types or an error
fn get_repo_specific_commit_types(
    repo: Option<Repository>,
    config_path: &Path,
) -> anyhow::Result<Option<Vec<PrintableEntity>>> {
    debug!(
        "Trying to get repo-specific commit types from file at {:?}",
        config_path
    );
    let project_commit_type_file_path: PathBuf = match repo {
        Some(x) => try_resolve_path_in_repo(&x, config_path)?,
        None => {
            if config_path.is_relative() {
                bail!("The config path is relative but no repo was found.");
            };
            config_path.to_path_buf()
        }
    };
    let project_commit_types: Option<Vec<PrintableEntity>> =
        match project_commit_type_file_path.exists() {
            true => {
                // Open the file in read-only mode with buffer.
                let file = File::open(project_commit_type_file_path)?;
                let reader = BufReader::new(file);

                // If file exists, can be read but is invalid json -- better tell the user
                debug!("Found the file, parsing it and returning the types");
                serde_json::from_reader(reader)?
            }
            // Absence of file is considered OK -- just treat it as "the project has no special
            // types"
            false => {
                debug!(
                    "No file found at {:?}. That's OK, program should return default types.",
                    project_commit_type_file_path
                );
                None
            }
        };

    Ok(project_commit_types)
}

#[cfg(test)]
mod tests {
    use super::*;
    use git2::{Oid, Signature};
    use rstest::{fixture, rstest};
    use std::fs;
    use std::sync::Once;
    use testdir::testdir;

    // Ensure logger is initialized only once for all tests
    static INIT: Once = Once::new();

    // To be used when neeeded by the tests, otherwise too spammy.
    fn init_logger() {
        INIT.call_once(|| {
            env_logger::Builder::new()
                .filter_level(log::LevelFilter::Debug)
                .is_test(true) // Ensures output is test-friendly
                .init();
        });
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

    #[fixture]
    fn get_types_to_test() -> Vec<String> {
        let types = get_default_commit_types();
        types.iter().map(|x| x.to_string()).collect()
    }

    #[fixture]
    fn mk_types() -> String {
        r#"[ { "name": "foo", "description": "some desc" } ]"#.to_string()
    }

    ///Checks that the default commit types contain some basic things
    #[rstest]
    #[case::feat("feat")]
    #[case::chore("chore")]
    fn default_commit_types_contain_expected_type(
        #[case] expected_type: &str,
        get_types_to_test: Vec<String>,
    ) {
        assert!(get_types_to_test.join("\n").contains(expected_type));
    }

    ///Checks that the default output is as expected
    #[rstest]
    fn test_all_default_types_printed_as_expected(get_types_to_test: Vec<String>) {
        let re = regex::Regex::new(r"\w: .*").unwrap();
        assert!(get_types_to_test.iter().all(|x| re.is_match(x)))
    }

    /// Checks that fallback works for various paths
    #[rstest]
    #[case::empty_dir(testdir!())]
    #[case::nonexistent_dir(PathBuf::from("/foobar"))]
    fn default_fallback(#[case] dir: PathBuf) {
        init_logger();
        let res = try_get_types_from_repo_at_path(dir, None).unwrap();
        assert!(!res.is_empty());
        // This test leaks implementation a bit but that's a quick way to make sure that default
        // types are present
        assert!(res == get_default_commit_types());
    }

    /// Checks that types can be read when path to types config is specified explicitly
    #[rstest]
    #[case::empty_dir_abspath(testdir!(), "./commit-types.json")]
    #[case::nonexistent_dir_abspath(PathBuf::from("/foobar"), "/commit-types.json")]
    #[case::empty_dir_relpath(testdir!(), "./commit-types.json")]
    fn check_types_from_path(#[case] dir: PathBuf, #[case] config_file: &str, mk_types: String) {
        init_logger();

        // For absolute paths join overwrites whatever preceeds it.
        //
        // For tests, I don't want to create random things in random places, so absolute path
        // coming in as a parameter should be rewritten relative to testdir.
        //
        // However, this is effectively an integration test, so the parameter passed to the main
        // function should maintain its "relative" status
        let passed_config = PathBuf::from(config_file);
        let mut tested_config_file = match dir.exists() {
            true => dir.clone(),
            false => testdir!().to_path_buf(),
        };
        // "force join" for paths. Join right path to the left path by reconstructing its
        // components.
        for component in passed_config
            .components()
            .skip_while(|c| c == &std::path::Component::RootDir)
        {
            tested_config_file.push(component);
        }
        if dir.exists() {
            // This will prevent discover() from running away from the test directory
            // A bit leaky, but I like testdir()
            setup_repo_with_commits(&dir, &["init"]);
        };
        debug!("Writing fixture commit types to {:?}", tested_config_file);
        std::fs::write(&tested_config_file, mk_types).ok();

        let tested_config_file_path = match passed_config.is_absolute() {
            true => tested_config_file,
            false => passed_config,
        };

        let res = try_get_types_from_repo_at_path(dir, Some(tested_config_file_path)).unwrap();
        assert!(!res.is_empty());
        println!("{:?}", res);
        assert_eq!(res.first().unwrap().name, "foo");
    }

}
