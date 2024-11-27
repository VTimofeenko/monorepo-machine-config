use core::fmt;
use serde::{Deserialize, Serialize};
use std::env;

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

/// Returns true if the program is run from a git repo
///
/// Current implementation relies on devenv's PRJ_ROOT
pub fn am_in_project() -> bool {
    env::var("PRJ_ROOT").is_ok()
}
