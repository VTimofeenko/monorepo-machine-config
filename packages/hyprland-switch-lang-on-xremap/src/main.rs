use hyprland::data::*;
use hyprland::prelude::*;
use hyprland::ctl::*;

fn main() -> hyprland::Result<()> {
    let devices = Devices::get()?;
    // Very naive:
    // 1. Relies on not documented fact that xremap creates a keyboard with the name "xremap"
    // 2. Relies on the fact that one and only one xremap exists
    let binding = devices.keyboards.iter().filter(|device| device.name.starts_with("xremap")).collect::<Vec<_>>();
    let xremap_device = match &binding.first() {
        Some(x) => &x.name,
        None => panic!("Could not find xremap device"),
    };

    switch_xkb_layout::call(xremap_device, switch_xkb_layout::SwitchXKBLayoutCmdTypes::Next).unwrap();
    Ok(())
}
