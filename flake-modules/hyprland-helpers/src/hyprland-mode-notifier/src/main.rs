use hyprland::event_listener::EventListener;
use notify_rust::{Notification, NotificationHandle, Timeout, Urgency};
use std::sync::{Arc, Mutex};

fn show_global_mode_notification(notification_handle: &mut NotificationHandle) {
    notification_handle
        .summary("Entered global mode")
        .urgency(Urgency::Normal)
        .timeout(Timeout::Default); // looks like swaync does not like ::Never

    notification_handle.update();
}

fn show_mode_notification(notification_handle: &mut NotificationHandle, mode_name: &str) {
    let summary = "Entered mode ".to_owned() + mode_name;

    notification_handle
        .summary(&summary)
        .urgency(Urgency::Critical)
        .timeout(Timeout::Milliseconds(2000)); // looks like swaync does not like ::Never

    notification_handle.update();
}

fn main() -> hyprland::Result<()> {
    let mut listener = EventListener::new();

    // Notification needs to be turned into NotificationHandle to be updated later
    // Created with the "Arc" to provide thread safety
    // Currently generates an (arguably, unneeded) notification on start
    let notification_handle = Arc::new(Mutex::new(
        Notification::new()
            .summary("Started hyprland-mode-notifier")
            .urgency(Urgency::Low)
            .show()
            .unwrap(),
    ));

    listener.add_sub_map_change_handler(move |data| {
        if data.is_empty() {
            show_global_mode_notification(&mut notification_handle.lock().unwrap())
        } else {
            show_mode_notification(&mut notification_handle.lock().unwrap(), &data);
        };
    });

    listener.start_listener()
}
