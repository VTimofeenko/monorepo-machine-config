use anyhow::{bail, Result};
use git2::Repository;
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;

use crate::common::PrintableEntity;

/// Retrieve repo-specific commit types. Fall back to bundled types.
pub fn try_get_types_from_repo_at_path(repo_path: PathBuf) -> Result<Vec<PrintableEntity>> {
    // If discover fails, just ignore it.
    // In future I might want to distinguish between "program ran without any parameters and
    // repo-path is explicitly specified -- so the user has some expectations"
    if let Ok(repo) = Repository::discover(repo_path) {
        // Repo exists and is, well, a a git repo
        // Try to get the repo specific commit types.
        // If there are no project-specific commit types (i.e. no file, file is empty) -- fall
        // back.
        // Parsing errors should be bubbled up
        if let Some(project_specific_commit_types) = get_repo_specific_commit_types(repo)? {
            return Ok(project_specific_commit_types);
        };
    };

    Ok(get_default_commit_types())
}

fn get_default_commit_types() -> Vec<PrintableEntity> {
    let bundled_types_file = include_str!("types.json");
    // If bundled commit types are bad -- we have a huge problem, panic.
    let bundled_commit_types: Vec<PrintableEntity> =
        serde_json::from_str(bundled_types_file).unwrap();

    bundled_commit_types
}

/// Returns the project-specific list of commit types or an error
fn get_repo_specific_commit_types(
    repo: Repository,
) -> anyhow::Result<Option<Vec<PrintableEntity>>> {
    let project_root = repo.workdir();

    let project_commit_type_file_path: PathBuf = match project_root {
        Some(y) => y.join(".dev/commit-types.json"),
        None => bail!("Looks like the repository at {:?} is bare", repo.path()),
    };

    let project_commit_types: Option<Vec<PrintableEntity>> =
        match project_commit_type_file_path.exists() {
            true => {
                // Open the file in read-only mode with buffer.
                let file = File::open(project_commit_type_file_path)?;
                let reader = BufReader::new(file);

                // If file exists, can be read but is invalid json -- better tell the user
                serde_json::from_reader(reader)?
            }
            // Absence of file is considered OK -- just treat it as "the project has no special
            // types"
            false => None,
        };

    Ok(project_commit_types)
}

#[cfg(test)]
mod tests {
    use super::*;
    use rstest::{fixture, rstest};
    use testdir::testdir;

    #[fixture]
    fn get_types_to_test() -> Vec<String> {
        let types = get_default_commit_types();
        types.iter().map(|x| x.to_string()).collect()
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
        let res = try_get_types_from_repo_at_path(dir).unwrap();
        assert!(!res.is_empty());
        // This test leaks implementation a bit but that's a quick way to make sure that default
        // types are present
        assert!(res == get_default_commit_types());
    }
}
