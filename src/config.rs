//! Configuration management for the package manager

use std::env;
use std::path::{Path, PathBuf};
use dirs::home_dir;
use serde::{Deserialize, Serialize};
use crate::error::GetError;

/// Application configuration
#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    pub default_package_manager: Option<String>,
    pub default_download_dir: Option<String>,
    pub log_verbosity: Option<String>,
    pub github_token: Option<String>,
    pub choco_repo_url: Option<String>,
    pub choco_repo_path: Option<String>,
    pub repositories: Vec<Repository>,
}

/// Repository configuration
#[derive(Debug, Deserialize, Serialize)]
pub struct Repository {
    pub name: String,
    pub url: String,
    pub package_format: PackageFormat,
    pub authentication: Option<RepositoryAuth>,
}

/// Supported package formats
#[derive(Debug, Deserialize, Serialize)]
pub enum PackageFormat {
    Json,
    Yaml,
    Toml,
    MsgPack,
}

/// Repository authentication methods
#[derive(Debug, Deserialize, Serialize)]
pub enum RepositoryAuth {
    Basic { username: String, password: String },
    Token { token: String },
    OAuth2 { client_id: String, client_secret: String },
}

impl Config {
    /// Load configuration from file and environment variables
    pub fn load() -> Self {
        let mut config = Config {
            default_package_manager: None,
            default_download_dir: None,
            log_verbosity: None,
            github_token: None,
            choco_repo_url: None,
            choco_repo_path: None,
            repositories: Vec::new(),
        };

        // Load from config file if exists
        if let Some(home) = home_dir() {
            let config_path = home.join(".get_config.toml");
            if config_path.exists() {
                if let Ok(content) = std::fs::read_to_string(&config_path) {
                    if let Ok(parsed) = toml::from_str(&content) {
                        config = parsed;
                    }
                }
            }
        }

        // Override with environment variables
        if let Ok(manager) = env::var("GET_PREFERRED_MANAGER") {
            config.default_package_manager = Some(manager);
        }

        if let Ok(download_path) = env::var("GET_DOWNLOAD_PATH") {
            config.default_download_dir = Some(download_path);
        }

        if let Ok(log_level) = env::var("GET_LOG_VERBOSITY") {
            config.log_verbosity = Some(log_level);
        }

        if let Ok(token) = env::var("GET_GITHUB_TOKEN") {
            config.github_token = Some(token);
        }

        config
    }

    /// Get the preferred package manager
    pub fn get_preferred_manager(&self) -> Option<&str> {
        self.default_package_manager.as_deref()
    }

    /// Get the download directory
    pub fn get_download_dir(&self) -> PathBuf {
        self.default_download_dir
            .as_ref()
            .map(PathBuf::from)
            .unwrap_or_else(|| {
                home_dir()
                    .map(|h| h.join("Downloads"))
                    .unwrap_or_else(|| PathBuf::from("."))
            })
    }

    /// Get the repositories directory
    pub fn get_repos_dir(&self) -> PathBuf {
        home_dir()
            .map(|h| h.join(".get_repos"))
            .unwrap_or_else(|| PathBuf::from("."))
    }

    /// Get the list of repositories
    pub fn get_repositories(&self) -> &Vec<Repository> {
        &self.repositories
    }

    /// Save the configuration to file
    pub fn save(&self) -> Result<(), GetError> {
        if let Some(home) = home_dir() {
            let config_path = home.join(".get_config.toml");
            let toml_str = toml::to_string(self)?;
            std::fs::write(&config_path, toml_str)?;
            Ok(())
        } else {
            Err(GetError::ConfigError(
                "Unable to determine home directory".to_string(),
            ))
        }
    }
}
