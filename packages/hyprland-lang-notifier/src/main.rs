use hyprland::event_listener::EventListener;
use notify_rust::{Notification, NotificationHandle};
use std::sync::{Arc, Mutex};

fn update_notification(notification_handle: &mut NotificationHandle, layout_name: &str) {
    // Updates the provided notification with the new text
    // # Arguments
    // * `notification_handle` - a mutable reference to a notification handle
    // * `layout_name` - name of the layout
    notification_handle.summary(layout_name);
    notification_handle.update();
}

fn main() -> hyprland::Result<()> {
    let mut listener = EventListener::new();

    // Notification needs to be turned into NotificationHandle to be updated later
    // Created with the "Arc" to provide thread safety
    // Currently generates an (arguably, unneeded) notification on start
    // Potential improvement -- set the ID, pass _Notification_ to update_notification and .show() there
    let notification_handle = Arc::new(Mutex::new(
        Notification::new()
            .summary("Started hyprland-lang-notifier")
            .show()
            .unwrap(),
    ));

    listener.add_keyboard_layout_change_handler(move |data| {
        let hyprland::event_listener::LayoutEvent {
            keyboard_name,
            layout_name: _,
        } = data;

        // For some reason it's _keyboard_ name that contains the layout name. IDK why :(
        let layout_name = keyboard_name.split(',').nth(1).unwrap();

        update_notification(&mut notification_handle.lock().unwrap(), layout_name)
    });

    listener.start_listener()
}
