//! Error handling for the package manager

use std::fmt;
use std::io;
use std::string::FromUtf8Error;
use reqwest;
use serde::{Deserialize, Serialize};
use serde_json;
use serde_yaml;
use rmp_serde;
use toml;

/// Main error type for the package manager
#[derive(Debug, Deserialize, Serialize)]
pub enum GetError {
    MissingDependency(String),
    NetworkError(String),
    CommandError(String),
    InvalidInput(String),
    IoError(String),
    ConfigError(String),
    ParseError(String),
    DeserializationError(String),
    SerializationError(String),
    ValidationError(String),
    PackageNotFound(String),
}

impl fmt::Display for GetError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            GetError::MissingDependency(msg) => write!(f, "Missing dependency: {}", msg),
            GetError::NetworkError(msg) => write!(f, "Network error: {}", msg),
            GetError::CommandError(msg) => write!(f, "Command error: {}", msg),
            GetError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            GetError::IoError(msg) => write!(f, "IO error: {}", msg),
            GetError::ConfigError(msg) => write!(f, "Configuration error: {}", msg),
            GetError::ParseError(msg) => write!(f, "Parse error: {}", msg),
            GetError::DeserializationError(msg) => write!(f, "Deserialization error: {}", msg),
            GetError::SerializationError(msg) => write!(f, "Serialization error: {}", msg),
            GetError::ValidationError(msg) => write!(f, "Validation error: {}", msg),
            GetError::PackageNotFound(msg) => write!(f, "Package not found: {}", msg),
            _ => unreachable!(), // This ensures all variants are covered
        }
    }
}

impl std::error::Error for GetError {}

impl From<io::Error> for GetError {
    fn from(err: io::Error) -> Self {
        GetError::IoError(err.to_string())
    }
}

impl From<reqwest::Error> for GetError {
    fn from(err: reqwest::Error) -> Self {
        GetError::NetworkError(err.to_string())
    }
}

impl From<toml::de::Error> for GetError {
    fn from(err: toml::de::Error) -> Self {
        GetError::ConfigError(err.to_string())
    }
}

impl From<serde_yaml::Error> for GetError {
    fn from(err: serde_yaml::Error) -> Self {
        GetError::ParseError(err.to_string())
    }
}

impl From<serde_json::Error> for GetError {
    fn from(err: serde_json::Error) -> Self {
        GetError::ParseError(err.to_string())
    }
}

impl From<rmp_serde::decode::Error> for GetError {
    fn from(err: rmp_serde::decode::Error) -> Self {
        GetError::DeserializationError(err.to_string())
    }
}

impl From<rmp_serde::encode::Error> for GetError {
    fn from(err: rmp_serde::encode::Error) -> Self {
        GetError::SerializationError(err.to_string())
    }
}

impl From<toml::ser::Error> for GetError {
    fn from(err: toml::ser::Error) -> Self {
        GetError::ConfigError(err.to_string())
    }
}

impl From<FromUtf8Error> for GetError {
    fn from(err: FromUtf8Error) -> Self {
        GetError::ParseError(err.to_string())
    }
}
