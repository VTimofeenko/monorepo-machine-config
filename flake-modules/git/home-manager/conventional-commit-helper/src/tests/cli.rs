// https://rust-cli.github.io/book/tutorial/testing.html
use assert_cmd::prelude::*; // Add methods on commands
use predicates::prelude::*; // Used for writing assertions
use std::process::Command; // Run programs
use std::sync::Once;
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

#[test]
fn default_run_no_args() -> Result<(), Box<dyn std::error::Error>> {
    init_logger();
    let mut cmd = Command::cargo_bin("semantic-commit-helper")?;

    cmd.arg("--debug");
    // Run without args -- OK
    cmd.assert().success();

    Ok(())
}
