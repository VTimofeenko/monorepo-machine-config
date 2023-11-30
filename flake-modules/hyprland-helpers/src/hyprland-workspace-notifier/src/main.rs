use hyprland::ctl::notify;
use hyprland::ctl::notify::Icon;
use hyprland::ctl::Color;
use hyprland::event_listener::EventListener;
use std::time::Duration;

fn main() -> hyprland::Result<()> {
    let mut listener = EventListener::new();

    listener.add_workspace_change_handler(|ws| {
        let _ = notify::call(
            Icon::Info,
            Duration::new(1, 0),
            Color::new(0, 0, 0, 0),
            format!("Changed workspace to: {}", ws),
        );
    });
    listener.start_listener()
}
