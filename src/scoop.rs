use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use indicatif::{ProgressBar, MultiProgress};
use serde::{Deserialize, Serialize};

use crate::{Config, GetError, Logger};

const SCOOP_MAIN_REPO_URL: &str = "https://github.com/ScoopInstaller/Main.git";

#[derive(Debug, Deserialize, Serialize)]
pub struct ScoopManifest {
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

#[derive(Debug, Deserialize, Serialize)]
pub struct ScoopInstaller {
    script: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ScoopCheckVer {
    url: String,
    regex: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ScoopAutoupdate {
    url: String,
}

pub fn ensure_scoop_repo(config: &Config, logger: &Logger, m: &MultiProgress) -> Result<PathBuf, GetError> {
    if crate::SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    let repos_dir = config.get_repos_dir();
    let scoop_local_path = repos_dir.join("scoop");

    ensure_repo(SCOOP_MAIN_REPO_URL, &scoop_local_path, logger, m)?;

    Ok(scoop_local_path)
}

fn ensure_repo(repo_url: &str, local_path: &Path, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
    if crate::SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    if local_path.exists() {
        logger.log(&format!(
            "Repository at '{}' already exists. Checking if it needs to be updated...",
            local_path.display()
        ));

        let last_pull_path = local_path.join("last_pull.txt");
        let needs_pull = if last_pull_path.exists() {
            let content = std::fs::read_to_string(&last_pull_path)?;
            if let Ok(timestamp) = content.trim().parse::<u64>() {
                let last_pull_time = UNIX_EPOCH + Duration::from_secs(timestamp);
                if let Ok(system_time) = SystemTime::now().duration_since(last_pull_time) {
                    system_time.as_secs() > 24 * 3600
                } else {
                    true
                }
            } else {
                true
            }
        } else {
            true
        };

        if needs_pull {
            let pb = m.add(ProgressBar::new_spinner());
            pb.set_message(format!("Pulling latest changes for repository '{}'.", local_path.display()));
            pb.enable_steady_tick(Duration::from_millis(100));
            let status = Command::new("git")
                .args(&["-C", local_path.to_str().unwrap(), "pull"])
                .status()?;

            pb.finish_and_clear();

            if status.success() {
                logger.log(&format!(
                    "Successfully updated repository at '{}'.",
                    local_path.display()
                ));
                let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
                std::fs::write(&last_pull_path, now.to_string())?;
                Ok(())
            } else {
                Err(GetError::CommandError(format!(
                    "Failed to pull updates for repository '{}'.",
                    local_path.display()
                )))
            }
        } else {
            logger.log(&format!(
                "Repository '{}' is up-to-date. No need to pull.",
                local_path.display()
            ));
            Ok(())
        }
    } else {
        let pb = m.add(ProgressBar::new_spinner());
        pb.set_message(format!(
            "Cloning repository from '{}' to '{}'.",
            repo_url,
            local_path.display()
        ));
        pb.enable_steady_tick(Duration::from_millis(100));
        let status = Command::new("git")
            .args(&["clone", repo_url, local_path.to_str().unwrap()])
            .status()?;

        pb.finish_and_clear();

        if status.success() {
            logger.log(&format!(
                "Successfully cloned repository to '{}'.",
                local_path.display()
            ));
            let last_pull_path = local_path.join("last_pull.txt");
            let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
            std::fs::write(&last_pull_path, now.to_string())?;
            Ok(())
        } else {
            Err(GetError::CommandError(format!(
                "Failed to clone repository from '{}'.",
                repo_url
            )))
        }
    }
}

pub fn install_scoop_package(package: &str, config: &Config, logger: &Logger, m: &MultiProgress) -> Result<(), GetError> {
    if crate::SHOULD_TERMINATE.load(Ordering::SeqCst) {
        return Err(GetError::InvalidInput("Operation terminated by user.".to_string()));
    }

    logger.log(&format!("Installing Scoop package '{}'...", package));
    
    let status = Command::new("scoop")
        .args(&["install", package])
        .status()?;

    if status.success() {
        logger.info(&format!("Package '{}' installed successfully.", package));
        Ok(())
    } else {
        Err(GetError::CommandError(format!(
            "Failed to install Scoop package '{}'.",
            package
        )))
    }
}