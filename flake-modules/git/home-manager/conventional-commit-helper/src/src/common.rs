use anyhow::{bail, Result};
use core::fmt;
use git2::Repository;
use log::debug;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

/// This is a generic printable thing. The concrete examples would be:
/// * Commit type
/// * Commit scope
#[derive(Debug, Deserialize, Clone, Eq, PartialEq, Hash, PartialOrd, Ord, Serialize)]
pub struct PrintableEntity {
    pub name: String,
    pub description: String,
}

impl fmt::Display for PrintableEntity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {}", self.name, self.description)
    }
}

/// Given a repository object and a path, return the path to the file inside the repo if the given
/// path is relative. Return absolute path as is.
pub fn try_resolve_path_in_repo<P>(repo: &Repository, path: P) -> Result<PathBuf>
where
    P: Into<PathBuf> + AsRef<Path> + std::marker::Copy,
{
    match &path.into().is_absolute() {
        true => {
            debug!("Path is absolute. Use as is.");
            Ok(path.into())
        }
        false => match repo.is_bare() {
            true => bail!("Repository is bare and specified path is relative. That won't work."),
            false => {
                debug!("Resolving the path inside the repository");
                Ok(repo
                    .workdir()
                    .expect("Could not find root dir of a non-bare repo. Looks like a bug?")
                    .join(path))
            }
        },
    }
}
