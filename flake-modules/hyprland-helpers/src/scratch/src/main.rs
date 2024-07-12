use hyprland::data::*;
use hyprland::event_listener::EventListener;
use hyprland::prelude::*;
use std::collections::HashMap;

fn mod_mask_to_string(mod_mask: u16) -> Vec<String> {
    // TODO: Make this const
    let mod_masks = HashMap::from([
        (1, "SHIFT"),
        (2, "CAPS"),
	    (4, "CTRL"),
	    (8, "ALT"),
	    (16, "MOD2"),
	    (32, "MOD3"),
	    (64, "SUPER"),
	    (128, "MOD5"),
    ]);
    let mut cur_val = 7;
    let mut result: Vec<String> = Vec::new();
    let mut mod_mask = mod_mask;


    while mod_mask > 0 {
        let mod_val = 1 << cur_val;
        if mod_mask >= mod_val {
            mod_mask -= mod_val;
            result.push(mod_masks[&(1 << cur_val)].to_string());
        }
        cur_val -= 1;

    }
    result
}


// modmask: 1 = shift
fn main() -> hyprland::Result<()> {
    let mut listener = EventListener::new();

    listener.add_sub_map_change_handler(move |data| {
        println!("Mode: {data}");
        let binds = Binds::get().unwrap();

        // data is empty <=> global mode
        if !data.is_empty() {
            let mode_binds = binds
                .into_iter()
                .filter(|b| b.submap == data)
                .collect::<Vec<Bind>>();

            for bind in mode_binds {
                let mut key_combo = mod_mask_to_string(bind.modmask);
                key_combo.push(bind.key);

                println!("Key: {}, arg: {}, dispatcher: {}", key_combo.join("+"), bind.arg, bind.dispatcher);
            }
        }
    });

    listener.start_listener()
}
