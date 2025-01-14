//! Logging utilities for the package manager

use crate::config::Config;

/// Log level for the application
#[derive(Debug, PartialEq)]
pub enum LogLevel {
    Minimal,
    Verbose,
}

/// Logger implementation
pub struct Logger {
    level: LogLevel,
}

impl Logger {
    /// Create a new logger with the specified log level
    pub fn new(level: LogLevel) -> Self {
        Logger { level }
    }

    /// Log a message (cyan color)
    pub fn log(&self, message: &str) {
        println!("\x1b[36m{}\x1b[0m", message);
    }

    /// Log an info message (cyan color)
    pub fn info(&self, message: &str) {
        println!("\x1b[36m{}\x1b[0m", message);
    }

    /// Log an error message (red color)
    pub fn error(&self, message: &str) {
        eprintln!("\x1b[31mError: {}\x1b[0m", message);
    }

    /// Log a warning message (yellow color)
    pub fn warn(&self, message: &str) {
        eprintln!("\x1b[33mWarning: {}\x1b[0m", message);
    }
}

impl Config {
    /// Get the log level from configuration
    pub fn get_log_level(&self) -> LogLevel {
        if let Some(ref level) = self.log_verbosity {
            match level.to_lowercase().as_str() {
                "verbose" => LogLevel::Verbose,
                _ => LogLevel::Minimal,
            }
        } else {
            LogLevel::Minimal
        }
    }
}
