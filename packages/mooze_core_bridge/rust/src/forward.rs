//! Forwards facade events to Dart stream sinks.
//!
//! Lives outside `api` so flutter_rust_bridge does not scan it.

use mooze_app::dto::SideSwapEventDto;
use mooze_app::events::{AppEvent, EventSink};

use crate::frb_generated::StreamSink;

/// Forwards the SideSwap items of the event stream to one Dart sink.
pub(crate) struct SinkForwarder(pub(crate) StreamSink<SideSwapEventDto>);

impl EventSink for SinkForwarder {
    fn send(&self, event: AppEvent) -> bool {
        match event {
            AppEvent::SideSwap(item) => self.0.add(item).is_ok(),
            _ => true,
        }
    }
}
