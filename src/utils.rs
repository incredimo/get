//! Utility functions for the package manager

use std::path::{Path, PathBuf};
use std::time::Duration;
use crate::error::GetError;
use crate::logging::Logger;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use reqwest::blocking::Client;
use std::fs::File;
use std::io::{Read, Write};
use sha2::{Digest, Sha256};
use hex::encode as hex_encode;

/// Download a file from a URL
pub fn download_file(
    url: &str,
    download_dir: &Path,
    logger: &Logger,
    m: &MultiProgress,
) -> Result<PathBuf, GetError> {
    logger.log(&format!("Starting download from '{}'", url));

    let client = Client::builder()
        .timeout(Duration::from_secs(300))
        .build()?;

    let response = client
        .get(url)
        .header("User-Agent", "get-terminal-app/1.0")
        .send()?;

    if !response.status().is_success() {
        return Err(GetError::NetworkError(format!(
            "Failed to download file: HTTP {}",
            response.status()
        )));
    }

    let file_name = url
        .split('/')
        .last()
        .ok_or_else(|| GetError::InvalidInput("Invalid URL".to_string()))?;
    let file_path = download_dir.join(file_name);

    std::fs::create_dir_all(download_dir)?;
    let mut file = File::create(&file_path)?;

    let total_size = response
        .content_length()
        .ok_or_else(|| GetError::NetworkError("Failed to get content length".to_string()))?;

    let pb = m.add(ProgressBar::new(total_size));
    pb.set_style(ProgressStyle::default_bar()
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
        pb.set_position(downloaded);
    }

    pb.finish_with_message("Download completed successfully");
    Ok(file_path)
}

/// Verify file checksum
pub fn verify_checksum(file_path: &Path, expected_hash: &str, logger: &Logger) -> Result<(), GetError> {
    logger.log("Verifying checksum...");

    let mut file = File::open(file_path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 1024 * 1024]; // 1MB buffer

    loop {
        let n = file.read(&mut buffer)?;
        if n == 0 {
            break;
        }
        hasher.update(&buffer[..n]);
    }

    let result = hasher.finalize();
    let calculated_hash = hex_encode(result);

    if calculated_hash.eq_ignore_ascii_case(expected_hash) {
        logger.log("Checksum verification passed");
        Ok(())
    } else {
        Err(GetError::NetworkError(format!(
            "Checksum mismatch: expected {}, got {}",
            expected_hash, calculated_hash
        )))
    }
}
