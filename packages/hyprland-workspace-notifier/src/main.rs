use hyprland::ctl::notify::Icon;
use hyprland::event_listener::EventListener;
use hyprland::ctl::notify;
use std::time::Duration;
use hyprland::ctl::Color;

fn main() -> hyprland::Result<()> {
    let mut listener = EventListener::new();

    listener.add_workspace_change_handler(|ws| {
        let _ = notify::call(Icon::Info, Duration::new(1, 0), Color::new(0, 0, 0, 0), format!("Changed workspace to: {}", ws));
    });
    listener.start_listener()
}
