use clap::{ArgAction, Parser, ValueEnum};
use log::debug;
use std::path::PathBuf;

mod common;

mod types;
use crate::types::try_get_types_from_repo_at_path;

use self::scopes::try_get_scopes_from_repo_at_path;

mod scopes;

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

    /// Print output in JSON format
    #[arg(long)]
    json: bool,

    /// Path to the non-bare git repository.
    #[arg(long, default_value = ".")]
    repo_path: PathBuf,

    #[arg(long, action=ArgAction::SetTrue)]
    debug: bool,

    /// Path to the file containing conventional commit types for the repository.
    ///
    /// Can be specified as relative to the repo workdir root (default value)
    #[arg(long, default_value = ".dev/commit-types.json")]
    commit_types_file: PathBuf,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    if args.debug {
        env_logger::Builder::from_default_env()
            .filter_level(log::LevelFilter::Debug)
            .init();

        debug!("Launched with args: {:?}", args);
    }

    // If this raises an error -- it needs to be reported to the user
    let output = match args.mode {
        Mode::Type => {
            if args.commit_types_file == PathBuf::from(".dev/commit-types.json") {
                debug!("Using the default value for commit types path");
                try_get_types_from_repo_at_path(args.repo_path, None)
            } else {
                debug!("Using the provided value for commit types path");
                try_get_types_from_repo_at_path(args.repo_path, Some(args.commit_types_file))
            }
        }

        Mode::Scope => try_get_scopes_from_repo_at_path(args.repo_path),
    }?;

    match args.json {
        true => println!("{}", serde_json::to_string(&output).unwrap()),
        false => output.iter().for_each(|x| println!("{}", x)),
    }

    Ok(())
}
