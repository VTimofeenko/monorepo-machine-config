use clap::{Parser, ValueEnum};
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

    #[arg(long)]
    json: bool,

    #[arg(long, default_value = ".")]
    repo_path: PathBuf,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    // If this raises an error -- it needs to be reported to the user
    let output = match args.mode {
        Mode::Type => try_get_types_from_repo_at_path(args.repo_path),
        Mode::Scope => try_get_scopes_from_repo_at_path(args.repo_path),
    }?;

    match args.json {
        true => println!("{}", serde_json::to_string(&output).unwrap()),
        false => output.iter().for_each(|x| println!("{}", x)),
    }

    Ok(())
}
