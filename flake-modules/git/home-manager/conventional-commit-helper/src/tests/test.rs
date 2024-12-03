use assert_cmd::Command;

static BIN_NAME: &str = "conventional-commit-helper";
/// Ensure that the when run without parameters the program succeeds
#[test]
fn default_run_no_args() {
    let mut cmd = Command::cargo_bin(BIN_NAME).unwrap();
    cmd.assert().success();
}

