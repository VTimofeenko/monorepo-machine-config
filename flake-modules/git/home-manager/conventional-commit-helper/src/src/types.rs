use std::path::Path;
use std::{env, fs};

use crate::common::PrintableEntity;

pub fn get_types() -> Vec<PrintableEntity> {
    let bundled_types_file = include_str!("types.json");
    let bundled_types_file: Vec<PrintableEntity> =
        serde_json::from_str(bundled_types_file).unwrap();

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
