use log::{debug, info, warn};
use regex::Regex;
use std::process::Command;

static PAST_SIGNATURE_KEY: &str = "HYPRLAND_HELPERS_PAST_HYPRLAND_INSTANCE_SIGNATURE";

fn restart_session() {
    // TODO: match success/failure
    debug!("Restarting hyprland-session.target");
    let _ = Command::new("/run/current-system/sw/bin/systemctl")
        .args(["--user", "restart", "hyprland-session.target"])
        .output();
}

fn record_past_signature(signature: &str) {
    // TODO: match success/failure
    debug!("Recording the value of past signature. It will be {signature}");
    let _ = Command::new("/run/current-system/sw/bin/systemctl")
        .args([
            "--user",
            "set-environment",
            &(PAST_SIGNATURE_KEY.to_owned() + "=" + signature),
        ])
        .output();
}

fn get_option_from_systemd(option_name: &str, systemd_output: &str) -> Option<String> {
    let regex_string = format!("(?m)^{}=(.*)$", option_name);
    let re = Regex::new(&regex_string);

    match re {
        Ok(regex) => regex
            .captures(systemd_output)
            .map(|caps| caps.get(1).unwrap().as_str().to_string()),
        Err(_) => None,
    }
}

fn main() {
    // NOTE: NixOS only
    //
    // This is probably better rewritten with a proper systemd rust binding
    env_logger::init();

    let output = Command::new("/run/current-system/sw/bin/systemctl")
        .args(["--user", "show-environment"])
        .output()
        .expect("Failed to run systemctl.");

    let stdout = String::from_utf8_lossy(&output.stdout);

    let current_instance_signature =
        get_option_from_systemd("HYPRLAND_INSTANCE_SIGNATURE", &stdout)
            .expect("Cannot get current instance signature. Did Hyprland start?");

    let past_instance_signature =
        get_option_from_systemd(PAST_SIGNATURE_KEY, &stdout).unwrap_or("".to_string());

    match past_instance_signature.is_empty() {
        true => {
            info!("No past signature recorded; I think this is the first time Hyprland started => not restarting hyprland session");
            record_past_signature(&current_instance_signature)
        }
        false => match past_instance_signature == current_instance_signature {
            true => info!("Current signature matches the past one => this will be a no-op"),
            false => {
                warn!("Signatures don't match => I will restart hyprland session");
                restart_session();
                record_past_signature(&current_instance_signature)
            }
        },
    };
}
