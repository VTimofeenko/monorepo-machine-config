use clap::{Parser, ValueEnum};
use git2::Repository;
use regex::Regex;
use std::collections::HashSet;
use std::path::Path;
use std::{env, fs};

mod common;
use crate::common::PrintableEntity;

mod types;
use crate::types::get_types;

#[derive(ValueEnum, Clone, Debug)]
enum Mode {
    Type,
    Scope,
}

/// Tiny helper for conventional commits (https://www.conventionalcommits.org).
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    ///Mode in which the program runs
    #[clap(value_enum, default_value_t=Mode::Type)]
    mode: Mode,

    #[arg(long)]
    json: bool,
}

/// Returns the possible commit scopes.
/// Possible sources:
/// * Per-project file in .dev/commit-scopes
/// * Parsed from git commit history
///
/// Note that there is no default list of scopes -- they are per-project by definition.
fn get_scopes(from_git_history: bool) -> Vec<PrintableEntity> {
    let am_in_project: bool = env::var("PRJ_ROOT").is_ok();

    let per_project_scopes: Vec<PrintableEntity> = match am_in_project {
        true => {
            let project_commit_scope_file_path =
                &format!("{}/.dev/commit-scopes.json", env::var("PRJ_ROOT").unwrap()).to_string();
            let project_commit_scope_file = Path::new(project_commit_scope_file_path);

            if project_commit_scope_file.exists() {
                serde_json::from_str(&fs::read_to_string(project_commit_scope_file).unwrap())
                    .unwrap()
            } else {
                Vec::new()
            }
        }
        false => Vec::new(),
    };

    if from_git_history {
        // Remove scopes if there is already a scope with a description
        // It might be worth using a hashset for this (turn per_project_scopes into a hashset and
        // append scopes from commit history), but that would require overriding hashing function
        // for PrintableEntity which is kinda meh.

        let known_scope_names: Vec<String> =
            per_project_scopes.iter().map(|x| x.clone().name).collect();
        let filtered_scopes_from_commit_history = get_scopes_from_commit_history()
            .iter()
            .filter(|x| !known_scope_names.contains(&x.name))
            .cloned()
            .collect();

        let mut scopes = [per_project_scopes, filtered_scopes_from_commit_history].concat();
        scopes.sort();
        scopes
    } else {
        per_project_scopes
    }
}

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
fn get_scopes_from_commit_history() -> Vec<PrintableEntity> {
    let repo = match Repository::open(env::var("PRJ_ROOT").unwrap()) {
        Ok(repo) => repo,
        Err(e) => panic!("failed to open: {}", e),
    };
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

fn main() {
    let args = Args::parse();

    let output = match args.mode {
        Mode::Type => get_types(),
        Mode::Scope => get_scopes(true),
    };

    match args.json {
        true => println!("{}", serde_json::to_string(&output).unwrap()),
        false => output.iter().for_each(|x| println!("{}", x)),
    }
}

/// Unit tests for the program
///
/// Using rstest to mimic the features of pytest -- fixtures, test parametrization
#[cfg(test)]
mod tests {
    use super::*;
    use rstest::rstest;

    /// Checks
    ///
    #[rstest]
    #[case::present("foo(bar): baz", Some("bar".to_string()))]
    #[case::absent("foo: baz", None)]
    fn can_extract_scope_from_commit_msg(#[case] msg: &str, #[case] result: Option<String>) {
        assert!(get_scope_from_commit_message(msg) == result)
    }
}
