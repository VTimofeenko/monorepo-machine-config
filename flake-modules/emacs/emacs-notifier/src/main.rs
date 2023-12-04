use clap::Parser;
use notify_rust::{Notification, Timeout};

#[derive(Parser, Debug)]
#[clap(version)]
#[clap(about = "Platform-independent notification binary for Emacs")]
struct Args {
    #[clap(help = "Message to display")]
    message: String,
    #[clap(help = "Title of notification")]
    title: String,
}

#[cfg(target_os = "macos")]
fn main() -> Result<(), String> {
    let args = Args::parse();

    use notify_rust::{error::MacOSError, get_bundle_identifier_or_default, set_application};

    let app_id = get_bundle_identifier_or_default("Emacs");
    set_application(&app_id).map_err(|f| format!("{}", f))?;

    match set_application(&app_id) {
        Ok(_) => {}
        Err(MacOSError::Application(error)) => println!("{}", error),
        Err(MacOSError::Notification(error)) => println!("{}", error),
    }

    Notification::new()
        .summary(&args.title)
        .body(&args.message)
        .timeout(Timeout::Milliseconds(5000))
        .show()
        .map_err(|f| format!("{}", f))?;
    Ok(())
}

#[cfg(all(unix, not(target_os = "macos")))]
fn main() -> Result<(), String> {
    let args = Args::parse();

    Notification::new()
        .summary(&args.title)
        .body(&args.message)
        .timeout(Timeout::Milliseconds(5000))
        .icon("emacs")
        .show()
        .map_err(|f| format!("{}", f))?;

    Ok(())
}
