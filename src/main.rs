#![allow(unused, unused_imports, unused_variables, unused_mut)]

use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{self, BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use dirs::home_dir;
use reqwest::blocking::Client;
use reqwest::header::{AUTHORIZATION, USER_AGENT};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use serde_yaml::Value as YamlValue;
use sha2::{Digest, Sha256};
use hex::encode as hex_encode;
use rpassword::read_password;
use walkdir::WalkDir;
use chrono::{DateTime, Utc, TimeZone};
use winapi::um::winuser::SW_HIDE;
use indicatif::{ProgressBar, ProgressStyle, MultiProgress};
use rayon::prelude::*;
use ctrlc;
use rmp_serde::{encode, decode};

use get::config::Config;
use get::error::GetError;
use get::logging::{Logger, LogLevel};
use get::repository::{ensure_repo, WINGET_PKG_REPO_URL, SCOOP_MAIN_REPO_URL};
use get::package_manager::{PackageManager, WingetManager, ScoopManager};
use get::utils::{download_file, verify_checksum};

// Atomic flag for graceful termination
static SHOULD_TERMINATE: AtomicBool = AtomicBool::new(false);


 
 

// -------------------- Command Parsing --------------------

enum CommandType {
    Install(String),
    Uninstall(String),
    Search(String),
    Clone(String),
    Download(String),
    Auth,
}

fn parse_args() -> Result<CommandType, GetError> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        return Err(GetError::InvalidInput(
            "No command provided.\nUsage:\n  get auth\n  get install <package-name>\n  get uninstall <package-name>\n  get search <query>\n  get clone <repository-url>\n  get <download-url>".to_string(),
        ));
    }

    match args[1].as_str() {
        "install" => {
            if args.len() != 3 {
                return Err(GetError::InvalidInput(
                    "Invalid install command.\nUsage: get install <package-name>".to_string(),
                ));
            }
            Ok(CommandType::Install(args[2].clone()))
        }
        "uninstall" => {
            if args.len() != 3 {
                return Err(GetError::InvalidInput(
                    "Invalid uninstall command.\nUsage: get uninstall <package-name>".to_string(),
                ));
            }
            Ok(CommandType::Uninstall(args[2].clone()))
        }
        "search" => {
            if args.len() != 3 {
                return Err(GetError::InvalidInput(
                    "Invalid search command.\nUsage: get search <query>".to_string(),
                ));
            }
            Ok(CommandType::Search(args[2].clone()))
        }
        "clone" => {
            if args.len() != 3 {
                return Err(GetError::InvalidInput(
                    "Invalid clone command.\nUsage: get clone <repository-url>".to_string(),
                ));
            }
            Ok(CommandType::Clone(args[2].clone()))
        }
        "auth" => {
            Ok(CommandType::Auth)
        }
        url => {
            if url.starts_with("http://") || url.starts_with("https://") {
                if args.len() != 2 {
                    return Err(GetError::InvalidInput(
                        "Invalid download command.\nUsage: get <download-url>".to_string(),
                    ));
                }
                Ok(CommandType::Download(url.to_string()))
            } else {
                Err(GetError::InvalidInput(
                    "Unknown command.\nUsage:\n  get auth\n  get install <package-name>\n  get uninstall <package-name>\n  get search <query>\n  get clone <repository-url>\n  get <download-url>".to_string(),
                ))
            }
        }
    }
}

// -------------------- Dependency Management --------------------

fn is_command_available(cmd: &str) -> bool {
    if cfg!(target_os = "windows") {
        Command::new("where")
            .arg(cmd)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    } else {
        Command::new("which")
            .arg(cmd)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    }
}

fn install_git(logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
    logger.info("Installing Git...");
    // Git installation logic
    // For simplicity, prompt the user to install Git manually
    let install_url = "https://git-scm.com/downloads";
    logger.info(&format!(
        "Please install Git manually from the official website: {}",
        install_url
    ));
    Err(GetError::MissingDependency(
        "Git installation requires manual steps.".to_string(),
    ))
}

fn ensure_dependency(dependency: &str, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
    if is_command_available(dependency) {
        logger.log(&format!("Dependency '{}' is already installed.", dependency));
        Ok(())
    } else {
        logger.log(&format!("Dependency '{}' is missing.", dependency));
        match dependency {
            "git" => install_git(logger, m),
            _ => Err(GetError::MissingDependency(format!(
                "Unknown dependency: {}",
                dependency
            ))),
        }
    }
}

// -------------------- Repository Structures --------------------

// Winget Manifest Structures
#[derive(Debug, Deserialize, Clone, Serialize)]
struct WingetManifest {
    PackageIdentifier: String,
    PackageVersion: String,
    Publisher: Option<String>,
    // PackageName: String,
    License: Option<String>,
    ShortDescription: Option<String>,
    Installers: Vec<WingetInstaller>,
    InstallerSwitches: Option<InstallerSwitches>, // New optional field
    Commands: Option<Vec<String>>,               // New optional field
    // Additional fields can be added as needed
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct WingetInstaller {
    Architecture: String,
    InstallerType: Option<String>, // Made optional
    InstallerUrl: String,
    InstallerSha256: String,
    InstallerSwitches: Option<InstallerSwitches>, // New optional field

    // AppsAndFeaturesEntries: Option<Vec<AppsAndFeaturesEntry>>, // Optional
    // Additional fields can be added as needed
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct InstallerSwitches {
    Silent: Option<String>,
    // Other switches can be added as needed
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct AppsAndFeaturesEntry {
    DisplayName: Option<String>,
    Publisher: Option<String>,
    InstallerType: Option<String>,
    // Additional fields can be added as needed
}

// Scoop Manifest Structures
#[derive(Debug, Deserialize, Clone, Serialize)]
struct ScoopManifest {
    version: String,
    description: String,
    homepage: String,
    license: Option<String>,
    url: String,
    hash: String,
    bin: Option<String>,
    installer: Option<ScoopInstaller>,
    checkver: Option<ScoopCheckVer>,
    autoupdate: Option<ScoopAutoupdate>,
    // Additional fields can be added as needed
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct ScoopInstaller {
    script: Vec<String>,
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct ScoopCheckVer {
    url: String,
    regex: String,
}

#[derive(Debug, Deserialize, Clone, Serialize)]
struct ScoopAutoupdate {
    url: String,
}

// Module declarations
mod chocolatey;
mod scoop;

// Import package manager modules
use chocolatey::{ensure_choco_repo, install_choco_package};
use scoop::{ensure_scoop_repo, install_scoop_package};

// -------------------- Install Manager --------------------

fn install_package(
    package: &str,
    config: &Config,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    // Check which package manager to use based on config
    match config.get_preferred_manager() {
        Some("choco") => install_choco_package(package, config, logger, m),
        Some("scoop") => install_scoop_package(package, config, logger, m),
        _ => {
            // Try both if no preference is set
            if let Err(e) = install_choco_package(package, config, logger, m) {
                install_scoop_package(package, config, logger, m)
            } else {
                Ok(())
            }
        }
    }
}

// -------------------- Index Structures --------------------

// Winget Index Entry
#[derive(Debug, Serialize, Deserialize, Clone)]
struct WingetIndexEntry {
    PackageIdentifier: String,
    PackageVersion: String,
    Publisher: Option<String>,
    License: Option<String>,
    ShortDescription: Option<String>,
    Installers: Vec<WingetInstaller>,
}

// Scoop Index Entry
#[derive(Debug, Serialize, Deserialize, Clone)]
struct ScoopIndexEntry {
    version: String,
    description: String,
    homepage: String,
    license: Option<String>,
    url: String,
    hash: String,
    bin: Option<String>,
    installer: Option<ScoopInstaller>,
    checkver: Option<ScoopCheckVer>,
    autoupdate: Option<ScoopAutoupdate>,
}

// -------------------- Index Management --------------------

fn index_winget(winget_repo_path: &Path, logger: &Logger, m: &MultiProgress) -> Result<Vec<WingetIndexEntry>, GetError> {
    logger.log("Indexing Winget manifests...");
    let pb = m.add(ProgressBar::new_spinner());
    pb.set_message("Indexing Winget manifests...");
    pb.enable_steady_tick(Duration::from_millis(100));

    let manifest_files: Vec<_> = WalkDir::new(winget_repo_path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|s| s.to_str()) == Some("yaml"))
        .filter(|e| e.path().file_name().and_then(|s| s.to_str()).map_or(false, |s| s.ends_with("installer.yaml")))
        .collect();

    pb.finish_and_clear();

    let total = manifest_files.len() as u64;
    let pb_progress = m.add(ProgressBar::new(total));
    pb_progress.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} {msg}")
        .unwrap()
        .progress_chars("█░-"));

    // Parallel processing using rayon
    let index: Vec<WingetIndexEntry> = manifest_files.par_iter()
        .map(|entry| {
            if SHOULD_TERMINATE.load(Ordering::SeqCst) {
                return None;
            }

            let manifest_path = entry.path();

            // Parse the manifest
            let manifest_text = match fs::read_to_string(manifest_path) {
                Ok(text) => text,
                Err(_) => return None, // Skip if failed to read
            };
            let manifest: WingetManifest = match serde_yaml::from_str(&manifest_text) {
                Ok(m) => m,
                Err(_) => return None, // Skip invalid manifests
            };

            pb_progress.inc(1);

            Some(WingetIndexEntry {
                PackageIdentifier: manifest.PackageIdentifier,
                PackageVersion: manifest.PackageVersion,
                Publisher: manifest.Publisher,
                License: manifest.License,
                ShortDescription: manifest.ShortDescription,
                Installers: manifest.Installers,
            })
        })
        .filter_map(|x| x)
        .collect();

    pb_progress.finish_with_message("Winget indexing completed.");

    Ok(index)
}

fn index_scoop(scoop_repo_path: &Path, logger: &Logger, m: &MultiProgress) -> Result<Vec<ScoopIndexEntry>, GetError> {
    logger.log("Indexing Scoop manifests...");
    let pb = m.add(ProgressBar::new_spinner());
    pb.set_message("Indexing Scoop manifests...");
    pb.enable_steady_tick(Duration::from_millis(100));

    let manifest_files: Vec<_> = WalkDir::new(scoop_repo_path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|s| s.to_str()) == Some("json"))
        .collect();

    pb.finish_and_clear();

    let total = manifest_files.len() as u64;
    let pb_progress = m.add(ProgressBar::new(total));
    pb_progress.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} {msg}")
        .unwrap()
        .progress_chars("#>-"));

    // Parallel processing using rayon
    let index: Vec<ScoopIndexEntry> = manifest_files.par_iter()
        .map(|entry| {
            if SHOULD_TERMINATE.load(Ordering::SeqCst) {
                return None;
            }

            let manifest_path = entry.path();

            // Parse the manifest
            let manifest_text = match fs::read_to_string(manifest_path) {
                Ok(text) => text,
                Err(_) => return None, // Skip if failed to read
            };
            let manifest: ScoopManifest = match serde_json::from_str(&manifest_text) {
                Ok(m) => m,
                Err(_) => return None, // Skip invalid manifests
            };

            pb_progress.inc(1);

            Some(ScoopIndexEntry {
                version: manifest.version,
                description: manifest.description,
                homepage: manifest.homepage,
                license: manifest.license,
                url: manifest.url,
                hash: manifest.hash,
                bin: manifest.bin,
                installer: manifest.installer,
                checkver: manifest.checkver,
                autoupdate: manifest.autoupdate,
            })
        })
        .filter_map(|x| x)
        .collect();

    pb_progress.finish_with_message("Scoop indexing completed.");

    Ok(index)
}

fn load_or_create_indexes(
    config: &Config,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(Vec<WingetIndexEntry>, Vec<ScoopIndexEntry>), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    let repos_dir = config.get_repos_dir();
    let winget_local_path = repos_dir.join("winget-pkgs");
    let scoop_local_path = repos_dir.join("Main");

    // Ensure repositories are cloned and up-to-date
    ensure_repo(WINGET_PKG_REPO_URL, &winget_local_path, logger, m)?;
    ensure_repo(SCOOP_MAIN_REPO_URL, &scoop_local_path, logger, m)?;

    // Define index file paths
    let winget_index_path = repos_dir.join("winget_index.msgpack");
    let scoop_index_path = repos_dir.join("scoop_index.msgpack");

    // Load or create Winget index
    let winget_index = if winget_index_path.exists() {
        logger.log("Loading Winget index from cache...");
        let index_data = fs::read(&winget_index_path)?;
        decode::from_read_ref(&index_data)?
    } else {
        let index = index_winget(&winget_local_path, logger, m)?;
        let encoded = encode::to_vec(&index)?;
        fs::write(&winget_index_path, &encoded)?;
        index
    };

    // Load or create Scoop index
    let scoop_index = if scoop_index_path.exists() {
        logger.log("Loading Scoop index from cache...");
        let index_data = fs::read(&scoop_index_path)?;
        decode::from_read_ref(&index_data)?
    } else {
        let index = index_scoop(&scoop_local_path, logger, m)?;
        let encoded = encode::to_vec(&index)?;
        fs::write(&scoop_index_path, &encoded)?;
        index
    };

    Ok((winget_index, scoop_index))
}

// -------------------- Search Manager --------------------

// Winget Search Result
#[derive(Debug)]
struct WingetSearchResult {
    PackageIdentifier: String,
    PackageVersion: String,
    Publisher: String,
    ShortDescription: String,
}

// Scoop Search Result
#[derive(Debug)]
struct ScoopSearchResult {
    description: String,
    version: String,
}

fn search_package(
    query: &str,
    logger: &Logger,
    config: &Config,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    logger.log("Starting search across Winget and Scoop repositories...");

    // Load or create indexes
    let (winget_index, scoop_index) = load_or_create_indexes(config, logger, m)?;

    // Perform search
    logger.log("Searching in Winget index...");
    let winget_results: Vec<WingetSearchResult> = winget_index
        .par_iter()
        .filter(|entry| {
            entry.PackageIdentifier.to_lowercase().contains(&query.to_lowercase())
                || entry.ShortDescription.as_ref().map_or(false, |desc| desc.to_lowercase().contains(&query.to_lowercase()))
        })
        .map(|entry| WingetSearchResult {
            PackageIdentifier: entry.PackageIdentifier.clone(),
            PackageVersion: entry.PackageVersion.clone(),
            Publisher: entry.Publisher.clone().unwrap_or_else(|| "Unknown".to_string()),
            ShortDescription: entry.ShortDescription.clone().unwrap_or_else(|| "".to_string()),
        })
        .collect();

    logger.log("Searching in Scoop index...");
    let scoop_results: Vec<ScoopSearchResult> = scoop_index
        .par_iter()
        .filter(|entry| {
            entry.description.to_lowercase().contains(&query.to_lowercase())
        })
        .map(|entry| ScoopSearchResult {
            description: entry.description.clone(),
            version: entry.version.clone(),
        })
        .collect();

    // Display results
    println!("\nSearch Results for '{}':\n", query);
    if winget_results.is_empty() && scoop_results.is_empty() {
        println!("No results found.");
    } else {
        if !winget_results.is_empty() {
            println!("Winget Packages:");
            for pkg in winget_results {
                println!(
                    "  - {} (Version: {}) by {}\n    Description: {}",
                    pkg.PackageIdentifier,
                    pkg.PackageVersion,
                    pkg.Publisher,
                    pkg.ShortDescription
                );
            }
        }

        if !scoop_results.is_empty() {
            println!("\nScoop Packages:");
            for pkg in scoop_results {
                println!(
                    "  - {} (Version: {})",
                    pkg.description, pkg.version
                );
            }
        }
    }

    Ok(())
}



fn handle_winget_install(
    manifest: &WingetIndexEntry,
    config: &Config,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    // Iterate through installers and choose the appropriate one
    for installer in &manifest.Installers {
        if SHOULD_TERMINATE.load(Ordering::SeqCst) {
            return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
        }

        logger.log(&format!(
            "Processing installer: Type={:?}, URL={}",
            installer.InstallerType, installer.InstallerUrl
        ));
        // Download the installer
        let installer_path = download_installer(&installer.InstallerUrl, &config.get_download_dir(), logger, m)?;

        // Verify SHA256 checksum
        // let checksum_pb = m.add(ProgressBar::new_spinner());
        // checksum_pb.set_message("Verifying checksum...");
        // checksum_pb.enable_steady_tick(Duration::from_millis(100));
        // verify_checksum(&installer_path, &installer.InstallerSha256, logger)?;
        // checksum_pb.finish_with_message("Checksum verification passed.");

        // Determine silent flags
        let silent_flags = if let Some(ref switches) = installer.InstallerSwitches {
            switches.Silent.clone().unwrap_or_else(|| {
                match installer.InstallerType.as_deref() {
                    Some("msi") => "/quiet /norestart".to_string(),
                    Some("nullsoft") => "/S".to_string(),
                    Some("exe") => "/S".to_string(),
                    _ => "".to_string(),
                }
            })
        } else {
            match installer.InstallerType.as_deref() {
                Some("msi") => "/quiet /norestart".to_string(),
                Some("nullsoft") => "/S".to_string(),
                Some("exe") => "/S".to_string(),
                _ => "".to_string(),
            }
        };

        // Execute the installer with silent flags
        let install_pb = m.add(ProgressBar::new_spinner());
        install_pb.set_message("Executing installer...");
        install_pb.enable_steady_tick(Duration::from_millis(100));
        execute_installer(&installer_path, &silent_flags, logger)?;
        install_pb.finish_with_message("Installer executed successfully.");

        logger.info(&format!("Package '{}' installed successfully.", manifest.PackageIdentifier));
        return Ok(());
    }

    Err(GetError::CommandError(format!(
        "No suitable installer found for package '{}'.",
        manifest.PackageIdentifier
    )))
}

fn handle_scoop_install(
    manifest: &ScoopIndexEntry,
    config: &Config,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    // Download the installer
    let installer_path = download_installer(&manifest.url, &config.get_download_dir(), logger, m)?;

    // Verify hash
    let verify_pb = m.add(ProgressBar::new_spinner());
    verify_pb.set_message("Verifying hash...");
    verify_pb.enable_steady_tick(Duration::from_millis(100));
    verify_checksum(&installer_path, &manifest.hash, logger)?;
    verify_pb.finish_with_message("Hash verification passed.");

    // Execute the installer script if available
    if let Some(installer) = &manifest.installer {
        for script in &installer.script {
            if SHOULD_TERMINATE.load(Ordering::SeqCst) {
                return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
            }

            logger.log(&format!("Executing installer script: {}", script));
            let exec_pb = m.add(ProgressBar::new_spinner());
            exec_pb.set_message("Executing installer script...");
            exec_pb.enable_steady_tick(Duration::from_millis(100));

            // For simplicity, execute the script using PowerShell on Windows
            #[cfg(target_os = "windows")]
            {
                let status = Command::new("powershell")
                    .args(&["-NoProfile", "-Command", script])
                    .status()?;
                if !status.success() {
                    exec_pb.finish_and_clear();
                    return Err(GetError::CommandError(format!(
                        "Failed to execute installer script for package '{}'.",
                        manifest.description
                    )));
                }
            }

            #[cfg(not(target_os = "windows"))]
            {
                exec_pb.finish_and_clear();
                return Err(GetError::InvalidInput(
                    "Scoop installation scripts are only supported on Windows.".to_string(),
                ));
            }

            exec_pb.finish_with_message("Installer script executed successfully.");
        }
    } else {
        // If no installer script, attempt to execute the installer directly with silent flags
        // Since Scoop uses different installer types, handling here may vary
        let exec_pb = m.add(ProgressBar::new_spinner());
        exec_pb.set_message("Executing installer...");
        exec_pb.enable_steady_tick(Duration::from_millis(100));
        execute_installer(&installer_path, "/S", logger)?;
        exec_pb.finish_with_message("Installer executed successfully.");
    }

    logger.info(&format!("Package '{}' installed successfully.", manifest.description));
    Ok(())
}

// -------------------- Uninstall Manager --------------------

fn uninstall_package(
    package: &str,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    // Load or create indexes
    logger.info(&format!("Searching for package '{}' in repositories for uninstallation...", package));
    let config = Config::load();
    let (winget_index, scoop_index) = load_or_create_indexes(&config, logger, m)?;

    let winget_results: Vec<&WingetIndexEntry> = winget_index
        .par_iter()
        .filter(|entry| {
            entry.PackageIdentifier.to_lowercase() == package.to_lowercase()
        })
        .collect();

    let scoop_results: Vec<&ScoopIndexEntry> = scoop_index
        .par_iter()
        .filter(|entry| {
            entry.description.to_lowercase().contains(&package.to_lowercase())
        })
        .collect();

    if winget_results.is_empty() && scoop_results.is_empty() {
        return Err(GetError::InvalidInput(format!(
            "Package '{}' not found in Winget or Scoop repositories.",
            package
        )));
    }

    // Prioritize Winget results
    if !winget_results.is_empty() {
        logger.log("Attempting to uninstall using Winget manifests.");
        for manifest in winget_results {
            if manifest.PackageIdentifier.to_lowercase() == package.to_lowercase()
            {
                logger.log(&format!("Found package '{}' in Winget.", manifest.PackageIdentifier));
                return handle_winget_uninstall(&manifest, logger, m);
            }
        }
    }

    // If not found in Winget, try Scoop
    if !scoop_results.is_empty() {
        logger.log("Attempting to uninstall using Scoop manifests.");
        for manifest in scoop_results {
            if manifest.description.to_lowercase().contains(&package.to_lowercase()) {
                logger.log(&format!("Found package '{}' in Scoop.", manifest.description));
                return handle_scoop_uninstall(&manifest, logger, m);
            }
        }
    }

    Err(GetError::InvalidInput(format!(
        "Package '{}' not found or uninstallation criteria not met.",
        package
    )))
}

fn handle_winget_uninstall(
    manifest: &WingetIndexEntry,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    // Attempt to find the installation path or use standard uninstallation commands
    // For simplicity, use PowerShell to uninstall based on the PackageIdentifier
    #[cfg(target_os = "windows")]
    {
        if SHOULD_TERMINATE.load(Ordering::SeqCst) {
            return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
        }

        let uninstall_cmd = format!(
            "Get-Package -Name '{}' | Uninstall-Package -Force -Confirm:$false",
            manifest.PackageIdentifier
        );

        let uninstall_pb = m.add(ProgressBar::new_spinner());
        uninstall_pb.set_message("Executing uninstallation command...");
        uninstall_pb.enable_steady_tick(Duration::from_millis(100));

        let status = Command::new("powershell")
            .args(&["-NoProfile", "-Command", &uninstall_cmd])
            .status()?;

        uninstall_pb.finish_with_message("Uninstallation command executed.");

        if status.success() {
            logger.info(&format!("Package '{}' uninstalled successfully.", manifest.PackageIdentifier));
            Ok(())
        } else {
            Err(GetError::CommandError(format!(
                "Failed to uninstall package '{}'.",
                manifest.PackageIdentifier
            )))
        }
    }

    #[cfg(not(target_os = "windows"))]
    {
        Err(GetError::InvalidInput(
            "Winget uninstallation is only supported on Windows.".to_string(),
        ))
    }
}

fn handle_scoop_uninstall(
    manifest: &ScoopIndexEntry,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    // Execute the uninstallation script if available
    if let Some(installer) = &manifest.installer {
        for script in &installer.script {
            if SHOULD_TERMINATE.load(Ordering::SeqCst) {
                return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
            }

            logger.log(&format!("Executing uninstaller script: {}", script));
            let exec_pb = m.add(ProgressBar::new_spinner());
            exec_pb.set_message("Executing uninstaller script...");
            exec_pb.enable_steady_tick(Duration::from_millis(100));

            // For simplicity, execute the script using PowerShell on Windows
            #[cfg(target_os = "windows")]
            {
                let status = Command::new("powershell")
                    .args(&["-NoProfile", "-Command", script])
                    .status()?;
                if !status.success() {
                    exec_pb.finish_and_clear();
                    return Err(GetError::CommandError(format!(
                        "Failed to execute uninstaller script for package '{}'.",
                        manifest.description
                    )));
                }
            }

            #[cfg(not(target_os = "windows"))]
            {
                exec_pb.finish_and_clear();
                return Err(GetError::InvalidInput(
                    "Scoop uninstallation scripts are only supported on Windows.".to_string(),
                ));
            }

            exec_pb.finish_with_message("Uninstaller script executed successfully.");
        }
    } else {
        // If no uninstaller script, attempt to remove the installation directory
        // This requires knowledge of the installation path, which is not provided in the manifest
        return Err(GetError::InvalidInput(
            "No uninstaller script found for this Scoop package.".to_string(),
        ));
    }

    logger.info(&format!("Package '{}' uninstalled successfully.", manifest.description));
    Ok(())
}

// -------------------- Download and Verification --------------------

fn download_installer(url: &str, download_dir: &Path, logger: &Logger, m: &MultiProgress) -> Result<PathBuf, GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    logger.log(&format!("Starting download from '{}'.", url));

    let client = Client::builder()
        .timeout(Duration::from_secs(300)) // Increased timeout for large files
        .build()?;

    let response = client
        .get(url)
        .header(USER_AGENT, "get-terminal-app/1.0")
        .send()?;

    if !response.status().is_success() {
        return Err(GetError::NetworkError(format!(
            "Failed to download installer: HTTP {}",
            response.status()
        )));
    }

    let url_path = url
        .split('/')
        .last()
        .ok_or_else(|| GetError::InvalidInput("Invalid URL.".to_string()))?;
    let file_path = download_dir.join(url_path);

    fs::create_dir_all(download_dir)?;

    let mut file = File::create(&file_path)?;

    let total_size = response
        .content_length()
        .ok_or_else(|| GetError::NetworkError("Failed to get content length.".to_string()))?;

    let pb = m.add(ProgressBar::new(total_size));
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})")
        .unwrap()
        .progress_chars("#>-"));

    let mut downloaded: u64 = 0;

    let mut reader = response;

    let mut buffer = [0u8; 8192];
    loop {
        if SHOULD_TERMINATE.load(Ordering::SeqCst) {
            pb.finish_and_clear();
            return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
        }

        let bytes_read = reader.read(&mut buffer)?;
        if bytes_read == 0 {
            break;
        }
        file.write_all(&buffer[..bytes_read])?;
        downloaded += bytes_read as u64;
        pb.set_position(downloaded);
    }

    pb.finish_with_message("Download completed successfully.");
    Ok(file_path)
}


// -------------------- Installer Execution --------------------

fn execute_installer(installer_path: &Path, silent_flags: &str, logger: &Logger) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    logger.log(&format!("Executing installer: {}", installer_path.display()));
    logger.info(&format!("args: {}", silent_flags));

    #[cfg(target_os = "windows")]
    {
        use std::os::windows::ffi::OsStrExt;
        use std::ffi::OsStr;

        let extension = installer_path.extension().and_then(OsStr::to_str).unwrap_or("");
        let (operation, parameters) = match extension.to_lowercase().as_str() {
            "exe" | "msi" => {
                let operation: Vec<u16> = OsStr::new("runas").encode_wide().chain(Some(0)).collect();
                let parameters: Vec<u16> = OsStr::new(silent_flags).encode_wide().chain(Some(0)).collect();
                (operation, parameters)
            },
            "msix" => {
                let operation: Vec<u16> = OsStr::new("open").encode_wide().chain(Some(0)).collect();
                let parameters: Vec<u16> = OsStr::new("").encode_wide().chain(Some(0)).collect();
                (operation, parameters)
            },
            _ => return Err(GetError::InvalidInput(format!("Unsupported file type: {}", extension))),
        };

        let file: Vec<u16> = installer_path.as_os_str().encode_wide().chain(Some(0)).collect();

        let result = unsafe {
            winapi::um::shellapi::ShellExecuteW(
                std::ptr::null_mut(),
                operation.as_ptr(),
                file.as_ptr(),
                parameters.as_ptr(),
                std::ptr::null(),
                SW_HIDE,
            )
        };

        if (result as isize) > 32 {
            logger.info("Installer executed successfully.");
            Ok(())
        } else {
            Err(GetError::CommandError("Installer execution failed.".to_string()))
        }
    }

    #[cfg(not(target_os = "windows"))]
    {
        // Implement installer execution for other OSes if necessary
        Err(GetError::InvalidInput(
            "Installer execution is only supported on Windows.".to_string(),
        ))
    }
}

// -------------------- Authentication Manager --------------------

fn authenticate(logger: &Logger, config: &mut Config) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    logger.info("Authenticating with GitHub...");

    println!("To authenticate with GitHub, you need a Personal Access Token (PAT).");
    println!("If you don't have one, you can create it by following these steps:");
    println!("1. Go to https://github.com/settings/tokens");
    println!("2. Click on 'Generate new token'");
    println!("3. Select the scopes you need (for this tool, 'repo' scope is sufficient)");
    println!("4. Click 'Generate token' and copy the token");

    print!("Enter your GitHub Personal Access Token: ");
    io::stdout().flush().unwrap();

    let token = read_password()?; // Securely read the token without echoing

    // Verify the token by making a simple API request
    let client = Client::builder()
        .timeout(Duration::from_secs(10))
        .build()?;

    let response = client
        .get("https://api.github.com/user")
        .header(USER_AGENT, "get-terminal-app/1.0")
        .header(AUTHORIZATION, format!("Bearer {}", token))
        .send()?;

    if response.status().is_success() {
        logger.info("Authentication successful.");
        config.github_token = Some(token);
        config.save()?;
        Ok(())
    } else {
        Err(GetError::NetworkError(format!(
            "Authentication failed: HTTP {}",
            response.status()
        )))
    }
}

// -------------------- Clone Manager --------------------

fn clone_repository(repo_url: &str, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
    if SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    let pb = m.add(ProgressBar::new_spinner());
    pb.set_message(format!("Cloning repository from '{}'.", repo_url));
    pb.enable_steady_tick(Duration::from_millis(100));
    let status = Command::new("git")
        .args(&["clone", repo_url])
        .status()?;

    if status.success() {
        pb.finish_with_message(format!("Repository '{}' cloned successfully.", repo_url));
        logger.info(&format!("Repository '{}' cloned successfully.", repo_url));
        Ok(())
    } else {
        pb.finish_and_clear();
        Err(GetError::CommandError(format!(
            "Failed to clone repository '{}'.",
            repo_url
        )))
    }
}


// -------------------- Main Execution ---------------------

fn main() {
    // Initialize MultiProgress for handling multiple progress bars
    let m = MultiProgress::new();

    // Setup Ctrl+C handler for graceful shutdown
    let m_clone = m.clone();
    ctrlc::set_handler(move || {
        SHOULD_TERMINATE.store(true, Ordering::SeqCst);
        m_clone.println("\nReceived Ctrl+C! Attempting to terminate gracefully...").unwrap();
    }).expect("Error setting Ctrl+C handler");

    // Load configuration
    let mut config = Config::load();
    let log_level = config.get_log_level();
    let logger = Logger::new(log_level);

    // Parse command
    let command = match parse_args() {
        Ok(cmd) => cmd,
        Err(e) => {
            match e {
                GetError::InvalidInput(msg) => logger.error(&msg),
                _ => logger.error("An unexpected error occurred while parsing arguments."),
            }
            std::process::exit(1);
        }
    };

    // Determine required dependencies based on command
    let required_dependencies = match &command {
        CommandType::Install(_) => vec!["git"],
        CommandType::Uninstall(_) => vec!["git"],
        CommandType::Clone(_) => vec!["git"],
        CommandType::Download(_) => vec![],
        CommandType::Search(_) => vec!["git"],
        CommandType::Auth => vec![],
    };

    // Ensure dependencies
    for dep in required_dependencies {
        if let CommandType::Install(_) | CommandType::Uninstall(_) | CommandType::Clone(_) | CommandType::Search(_) = &command {
            if let Err(e) = ensure_dependency(dep, &logger, &m) {
                logger.error(&match e {
                    GetError::MissingDependency(msg) => msg,
                    GetError::CommandError(msg) => msg,
                    _ => "Failed to ensure dependencies.".to_string(),
                });
                std::process::exit(1);
            }
        }
    }

    // Execute command
    match command {
        CommandType::Install(package) => {
            if let Err(e) = install_package(&package, &config, &logger, &m) {
                logger.error(&match e {
                    GetError::CommandError(msg) => msg,
                    GetError::MissingDependency(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    _ => format!("Failed to install package '{}'.\n reason: {:?}", package, e),
                });
                std::process::exit(1);
            }
        }
        CommandType::Uninstall(package) => {
            if let Err(e) = uninstall_package(&package, &logger, &m) {
                logger.error(&match e {
                    GetError::CommandError(msg) => msg,
                    GetError::MissingDependency(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    _ => "Failed to uninstall package.".to_string(),
                });
                std::process::exit(1);
            }
        }
        CommandType::Search(query) => {
            if let Err(e) = search_package(&query, &logger, &config, &m) {
                logger.error(&match e {
                    GetError::NetworkError(msg) => msg,
                    GetError::ParseError(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    _ => "Failed to search packages.".to_string(),
                });
                std::process::exit(1);
            }
        }
        CommandType::Clone(repo_url) => {
            if let Err(e) = clone_repository(&repo_url, &logger, &m) {
                logger.error(&match e {
                    GetError::CommandError(msg) => msg,
                    GetError::MissingDependency(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    _ => "Failed to clone repository.".to_string(),
                });
                std::process::exit(1);
            }
        }
        CommandType::Download(url) => {
            let download_dir = config.get_download_dir();
            if let Err(e) = download_file(&url, &download_dir, &logger, &m) {
                logger.error(&match e {
                    GetError::NetworkError(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    GetError::IoError(msg) => msg,
                    _ => "Failed to download file.".to_string(),
                });
                std::process::exit(1);
            }
        }
        CommandType::Auth => {
            if let Err(e) = authenticate(&logger, &mut config) {
                logger.error(&match e {
                    GetError::NetworkError(msg) => msg,
                    GetError::InvalidInput(msg) => msg,
                    _ => "Failed to authenticate.".to_string(),
                });
                std::process::exit(1);
            }
        }
    }

    // Wait for all progress bars to finish
    // m.join().unwrap();
}
