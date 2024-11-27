use clap::{Parser, ValueEnum};

mod common;

mod types;
use crate::types::get_types;

mod scopes;
use crate::scopes::get_scopes;

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
