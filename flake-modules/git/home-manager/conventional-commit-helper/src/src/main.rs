use core::fmt;
use serde::Deserialize;
use std::path::Path;
use std::{env, fs};

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

fn main() {
    let bundled_types_file = include_str!("types.json");
    let bundled_types_file: Vec<CommitType> = serde_json::from_str(bundled_types_file).unwrap();

    let am_in_project: bool = env::var("PRJ_ROOT").is_ok();

    let shown_types: Vec<CommitType> = match am_in_project {
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

    for t in shown_types {
        println!("{}", t)
    }
}
