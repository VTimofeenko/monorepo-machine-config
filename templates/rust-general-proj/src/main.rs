use anyhow::Result;
use tracing::{error, info, warn};
use tracing_subscriber::{EnvFilter, fmt::format::FmtSpan};



#[tokio::main]
async fn main() -> Result<()> {
    setup_logging();
}

fn setup_logging() {
    tracing_subscriber::fmt()
        .compact()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_target(false)
        .with_span_events(FmtSpan::NEW)
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();
}

