use clap::{Parser, ValueEnum};
use core::fmt;
use serde::Deserialize;
use std::path::Path;
use std::{env, fs};

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
}

#[derive(Debug, Deserialize)]
struct CommitType {
    name: String,
    description: String,
}

impl fmt::Display for CommitType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {}", self.name, self.description)
    }
}

/// Shows commit types (feat/chore/etc.). Optionally looks for per-repository configuration in
/// .dev/commit-types. That file should be json-formatted like the bundled types.json
fn show_types() {
    for t in get_types() {
        println!("{}", t)
    }
}

fn get_types() -> Vec<CommitType> {
    let bundled_types_file = include_str!("types.json");
    let bundled_types_file: Vec<CommitType> = serde_json::from_str(bundled_types_file).unwrap();

    let am_in_project: bool = env::var("PRJ_ROOT").is_ok();

    return match am_in_project {
        true => {
            let project_commit_type_file_path =
                &format!("{}/.dev/commit-types", env::var("PRJ_ROOT").unwrap()).to_string();
            let project_commit_type_file = Path::new(project_commit_type_file_path);

            if project_commit_type_file.exists() {
                serde_json::from_str(&fs::read_to_string(project_commit_type_file).unwrap())
                    .unwrap()
            } else {
                bundled_types_file
            }
        }
        false => bundled_types_file,
    };
}

fn main() {
    let args = Args::parse();

    match args.mode {
        Mode::Type => show_types(),
        Mode::Scope => todo!(),
    };
}

/// Unit tests for the program
///
/// Using rstest to mimic the features of pytest -- fixtures, test parametrization
#[cfg(test)]
mod tests {
    use super::*;
    use rstest::{fixture, rstest};

    #[fixture]
    fn get_types_to_test() -> Vec<String> {
        let types = get_types();
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
}
