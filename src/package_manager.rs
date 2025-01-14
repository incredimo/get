//! Universal package manager implementation

use std::fs::File;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::Duration;

use reqwest::blocking::{Client, Response};
use reqwest::header::USER_AGENT;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use hex::encode as hex_encode;
use indicatif::{ProgressBar, ProgressStyle, MultiProgress};

use crate::config::Config;
use crate::error::GetError;
use crate::logging::Logger;

/// Universal package manager interface
pub trait PackageManager {
    fn install(&self, package: &str, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<(), GetError>;
    fn uninstall(&self, package: &str, logger: &Logger, m: &MultiProgress) -> Result<(), GetError>;
    fn search(&self, query: &str, logger: &Logger, config: &Config, m: &MultiProgress) -> Result<(), GetError>;
}

/// Universal package manager implementation
pub struct UniversalPackageManager;

impl PackageManager for UniversalPackageManager {
    fn install(&self, package: &str, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
        let package_info = self.fetch_package_info(package, config, logger, m)?;
        self.download_and_install(&package_info, config, logger, m)
    }

    fn uninstall(&self, package: &str, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
        self.handle_uninstall(package, logger, m)
    }

    fn search(&self, query: &str, logger: &Logger, config: &Config, m: &MultiProgress) -> Result<(), GetError> {
        let results = self.search_repositories(query, config, logger, m)?;
        self.display_search_results(&results, logger)
    }
}

impl UniversalPackageManager {
    fn fetch_package_info(&self, package: &str, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<PackageInfo, GetError> {
        let pb = m.add(ProgressBar::new_spinner());
        pb.set_message("Fetching package info...");
        pb.enable_steady_tick(Duration::from_millis(100));

        // Get repositories from config
        let repositories = config.get_repositories();
        if repositories.is_empty() {
            return Err(GetError::ConfigurationError("No repositories configured".to_string()));
        }

        // Try each repository until we find the package
        for repo in repositories {
            let url = format!("{}/packages/{}", repo.url, package);
            let client = Client::builder()
                .timeout(Duration::from_secs(30))
                .build()?;

            let mut request = client.get(&url)
                .header(USER_AGENT, "get-package-manager/1.0");

            // Add authentication if needed
            if let Some(auth) = &repo.authentication {
                request = match auth {
                    RepositoryAuth::Basic { username, password } => {
                        request.basic_auth(username, Some(password))
                    }
                    RepositoryAuth::Token { token } => {
                        request.header("Authorization", format!("Bearer {}", token))
                    }
                    RepositoryAuth::OAuth2 { client_id, client_secret } => {
                        request.basic_auth(client_id, Some(client_secret))
                    }
                };
            }

            let response = request.send()?;

            if response.status().is_success() {
                let package_info: PackageInfo = match repo.package_format {
                    PackageFormat::Json => response.json()?,
                    PackageFormat::Yaml => serde_yaml::from_reader(response)?,
                    PackageFormat::Toml => {
                        let text = response.text()?;
                        toml::from_str(&text)?
                    }
                    PackageFormat::MsgPack => rmp_serde::decode::from_read(response)?,
                };
                pb.finish_with_message("Package info fetched successfully");
                return Ok(package_info);
            }
        }

        pb.finish_with_message("Package not found in any repository");
        Err(GetError::PackageNotFound(package.to_string()))
    }

    fn download_and_install(&self, package_info: &PackageInfo, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
        let pb = m.add(ProgressBar::new_spinner());
        pb.set_message("Downloading package...");
        pb.enable_steady_tick(Duration::from_millis(100));

        // Download the package
        let client = Client::builder()
            .timeout(Duration::from_secs(300))
            .build()?;

        let response = client.get(&package_info.source_url)
            .header(USER_AGENT, "get-package-manager/1.0")
            .send()?;

        if !response.status().is_success() {
            return Err(GetError::NetworkError(format!(
                "Failed to download package: HTTP {}", 
                response.status()
            )));
        }

        // Create download directory
        let download_dir = config.get_download_dir();
        std::fs::create_dir_all(&download_dir)?;

        // Create temp file
        let file_name = package_info.source_url.split('/').last()
            .ok_or_else(|| GetError::InvalidInput("Invalid source URL".to_string()))?;
        let file_path = download_dir.join(file_name);
        let mut file = File::create(&file_path)?;

        // Download with progress
        let total_size = response.content_length()
            .ok_or_else(|| GetError::NetworkError("Failed to get content length".to_string()))?;

        let download_pb = m.add(ProgressBar::new(total_size));
        download_pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})")
            .unwrap()
            .progress_chars("#>-"));

        let mut downloaded: u64 = 0;
        let mut reader = response;
        let mut buffer = [0u8; 8192];

        loop {
            let bytes_read = reader.read(&mut buffer)?;
            if bytes_read == 0 {
                break;
            }
            file.write_all(&buffer[..bytes_read])?;
            downloaded += bytes_read as u64;
            download_pb.set_position(downloaded);
        }

        download_pb.finish_with_message("Download complete");

        // Verify checksum
        pb.set_message("Verifying checksum...");
        let mut hasher = Sha256::new();
        let mut file = File::open(&file_path)?;
        let mut buffer = [0u8; 8192];

        loop {
            let bytes_read = file.read(&mut buffer)?;
            if bytes_read == 0 {
                break;
            }
            hasher.update(&buffer[..bytes_read]);
        }

        let computed_hash = hex_encode(hasher.finalize());
        if computed_hash != package_info.checksum {
            return Err(GetError::ValidationError(format!(
                "Checksum mismatch. Expected: {}, Got: {}",
                package_info.checksum, computed_hash
            )));
        }

        pb.set_message("Installing package...");

        // Handle installation based on instructions
        match &package_info.install_instructions {
            InstallInstructions::Executable { path, args } => {
                self.install_executable(&file_path, path, args, logger, m)?;
            }
            InstallInstructions::Archive { format, extract_path, post_extract_commands } => {
                self.install_archive(&file_path, format, extract_path, post_extract_commands, logger, m)?;
            }
            InstallInstructions::Script { interpreter, script } => {
                self.install_script(&file_path, interpreter, script, logger, m)?;
            }
        }

        pb.finish_with_message("Package installed successfully");
        Ok(())
    }

    fn handle_uninstall(&self, package: &str, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
        // TODO: Implement package uninstallation
        unimplemented!()
    }

    fn search_repositories(&self, query: &str, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<Vec<PackageInfo>, GetError> {
        // TODO: Implement repository searching
        unimplemented!()
    }

    fn display_search_results(&self, results: &[PackageInfo], logger: &Logger) -> Result<(), GetError> {
        // TODO: Implement search results display
        unimplemented!()
    }
}

/// Package information structure
#[derive(Debug, Serialize, Deserialize)]
struct PackageInfo {
    name: String,
    version: String,
    description: String,
    author: Option<String>,
    license: Option<String>,
    source_url: String,
    checksum: String,
    dependencies: Vec<String>,
    install_instructions: InstallInstructions,
}

/// Package installation instructions
#[derive(Debug, Serialize, Deserialize)]
enum InstallInstructions {
    Executable {
        path: String,
        args: Vec<String>,
    },
    Archive {
        format: ArchiveFormat,
        extract_path: String,
        post_extract_commands: Vec<String>,
    },
    Script {
        interpreter: String,
        script: String,
    },
}

/// Supported archive formats
#[derive(Debug, Serialize, Deserialize)]
enum ArchiveFormat {
    Zip,
    TarGz,
    TarXz,
    TarBz2,
    SevenZip,
}

/// Repository information
#[derive(Debug, Serialize, Deserialize)]
struct Repository {
    name: String,
    url: String,
    package_format: PackageFormat,
    authentication: Option<RepositoryAuth>,
}

/// Supported package formats
#[derive(Debug, Serialize, Deserialize)]
enum PackageFormat {
    Json,
    Yaml,
    Toml,
    MsgPack,
}

/// Repository authentication methods
#[derive(Debug, Serialize, Deserialize)]
enum RepositoryAuth {
    Basic { username: String, password: String },
    Token { token: String },
    OAuth2 { client_id: String, client_secret: String },
}
