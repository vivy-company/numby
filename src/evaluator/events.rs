/// Events published when application state changes.
///
/// These events allow reactive components to respond to state mutations.
/// Subscribers implementing `EventSubscriber` will receive these events.
#[derive(Debug, Clone)]
#[allow(unused)]
pub enum StateEvent {
    /// A variable was changed or created. Contains the variable name.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::VariableChanged("x".to_string()));
    /// ```
    VariableChanged(String),

    /// A variable was deleted. Contains the variable name.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::VariableDeleted("x".to_string()));
    /// ```
    VariableDeleted(String),

    /// A value was added to history. Contains the value.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::HistoryAdded(42.0));
    /// ```
    HistoryAdded(f64),

    /// Configuration was reloaded.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::ConfigReloaded);
    /// ```
    ConfigReloaded,

    /// All variables were cleared.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::AllVariablesCleared);
    /// ```
    AllVariablesCleared,
}

/// Trait for components that react to state changes.
///
/// Implement this trait to create custom subscribers that respond to `StateEvent`s.
///
/// # Example
/// ```ignore
/// struct Logger;
///
/// impl EventSubscriber for Logger {
///     fn on_event(&self, event: &StateEvent) {
///         println!("Event: {:?}", event);
///     }
/// }
/// ```
pub trait EventSubscriber: Send + Sync {
    /// Called when an event is published.
    fn on_event(&self, event: &StateEvent);
}
