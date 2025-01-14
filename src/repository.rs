//! Repository management for package managers

use std::{path::Path, process::Command, time::Duration};
use crate::error::GetError;
use crate::logging::Logger;
use indicatif::{MultiProgress, ProgressBar};

pub const WINGET_PKG_REPO_URL: &str = "https://github.com/microsoft/winget-pkgs";
pub const SCOOP_MAIN_REPO_URL: &str = "https://github.com/ScoopInstaller/Main";

/// Ensures a repository is cloned and up-to-date
pub fn ensure_repo(
    repo_url: &str,
    local_path: &Path,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<(), GetError> {
    if !local_path.exists() {
        logger.log(&format!("Cloning repository from '{}'", repo_url));
        let pb = m.add(ProgressBar::new_spinner());
        pb.set_message("Cloning repository...");
        pb.enable_steady_tick(Duration::from_millis(100));
        
        let status = Command::new("git")
            .args(&["clone", repo_url, local_path.to_str().unwrap()])
            .status()?;
            
        if status.success() {
            pb.finish_with_message("Repository cloned successfully.");
            Ok(())
        } else {
            pb.finish_and_clear();
            Err(GetError::CommandError(format!(
                "Failed to clone repository '{}'",
                repo_url
            )))
        }
    } else {
        logger.log(&format!("Repository already exists at '{}'", local_path.display()));
        Ok(())
    }
}
