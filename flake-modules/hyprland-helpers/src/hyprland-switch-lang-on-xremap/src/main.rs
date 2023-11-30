use std::time::Duration;

use clap::Parser;
use hyprland::ctl::notify::Icon;
use hyprland::ctl::*;
use hyprland::ctl::{notify, Color};
use hyprland::data::*;
use hyprland::prelude::*;

#[derive(clap::ValueEnum, Clone, Debug)]
#[clap(rename_all = "snake_case")]
enum Action {
    Next,
    SetEn,
}

#[derive(Parser, Debug)]
#[clap(version)]
#[clap(about = "Switches language on a specific device in Hyprland")]
struct Args {
    #[clap(help = "How to switch layout")]
    #[clap(value_enum, default_value_t=Action::Next)]
    action: Action,

    #[clap(help = "Name of the device")]
    #[clap(default_value = "xremap")]
    device_name: String,
}

fn err_notify(value: String) {
    let _ = notify::call(
        Icon::Error,
        Duration::new(2, 0),
        Color::new(0, 0, 0, 0),
        format!("Error: {}", value),
    );
}

fn main() -> hyprland::Result<()> {
    let args = Args::parse();

    let devices = Devices::get()?;
    // Very naive:
    // Only works on the first device called "xremap" that is found. According to xremap's docs,
    // the first xremap device will be called "xremap", the other ones will be called "xremap=$pid"
    let binding = devices
        .keyboards
        .iter()
        .filter(|device| device.name.starts_with(&args.device_name))
        .collect::<Vec<_>>();
    let found_device = match &binding.first() {
        Some(x) => &x.name,
        None => {
            err_notify(format!("Could not find the device: {}", args.device_name));
            panic!("Could not find the device")
        }
    };

    let layout = match args.action {
        Action::Next => switch_xkb_layout::SwitchXKBLayoutCmdTypes::Next,
        Action::SetEn => switch_xkb_layout::SwitchXKBLayoutCmdTypes::Id(0),
    };

    match switch_xkb_layout::call(found_device, layout) {
        Ok(_) => Ok(()),
        Err(value) => {
            err_notify(value.to_string());
            Err(value)
        }
    }
}
