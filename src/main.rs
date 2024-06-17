use reqwest::Client;
use serde::Deserialize;
use sha2::{Sha256, Digest};
use std::collections::HashMap;
use std::fs::File;
use std::io::{self, Read, Write};
use std::path::Path;
use tokio::fs::{self, create_dir_all};
use zip::ZipArchive;

#[derive(Debug)]
pub enum ScoopError {
    Network(reqwest::Error),
    FileIO(io::Error),
    HashVerification,
    InvalidUrl,
    MissingArchitecture,
    JsonParse(serde_json::Error),
    ZipExtraction(zip::result::ZipError),
}

impl From<reqwest::Error> for ScoopError {
    fn from(error: reqwest::Error) -> Self {
        ScoopError::Network(error)
    }
}

impl From<io::Error> for ScoopError {
    fn from(error: io::Error) -> Self {
        ScoopError::FileIO(error)
    }
}

impl From<serde_json::Error> for ScoopError {
    fn from(error: serde_json::Error) -> Self {
        ScoopError::JsonParse(error)
    }
}

impl From<zip::result::ZipError> for ScoopError {
    fn from(error: zip::result::ZipError) -> Self {
        ScoopError::ZipExtraction(error)
    }
}

pub type Result<T> = std::result::Result<T, ScoopError>;

#[derive(Deserialize)]
pub struct Architecture {
    pub url: Option<String>,
    pub hash: Option<String>,
    pub extract_dir: Option<String>,
}

#[derive(Deserialize)]
pub struct Manifest {
    pub version: Option<String>,
    pub description: Option<String>,
    pub homepage: Option<String>,
    pub license: Option<String>,
    pub architecture: HashMap<String, Architecture>,
    pub bin: Option<Vec<String>>,
    pub checkver: Option<Checkver>,
    pub autoupdate: Option<Autoupdate>,
}

#[derive(Deserialize)]
pub struct Checkver {
    pub url: Option<String>,
    pub jsonpath: Option<String>,
    pub regex: Option<String>,
}

#[derive(Deserialize)]
pub struct Autoupdate {
    pub architecture: HashMap<String, AutoupdateArchitecture>,
}

#[derive(Deserialize)]
pub struct AutoupdateArchitecture {
    pub url: Option<String>,
}

async fn download_file(url: &str, path: &str) -> Result<()> {
    let response = Client::new().get(url).send().await?;
    let bytes = response.bytes().await?;
    let mut file = File::create(path)?;
    file.write_all(&bytes)?;
    Ok(())
}

fn verify_hash(path: &str, expected_hash: &str) -> Result<bool> {
    let mut file = File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 4096];
    loop {
        let n = file.read(&mut buffer)?;
        if n == 0 {
            break;
        }
        hasher.update(&buffer[..n]);
    }
    let hash = hasher.finalize();
    Ok(hex::encode(hash) == expected_hash)
}

async fn extract_zip(path: &str, extract_to: &str) -> Result<()> {
    let file = File::open(path)?;
    let mut archive = ZipArchive::new(file)?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        let outpath = Path::new(extract_to).join(file.name());

        if file.name().ends_with('/') {
            create_dir_all(&outpath).await.unwrap();
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    create_dir_all(p).await.unwrap();
                }
            }
            let mut outfile = File::create(&outpath)?;
            io::copy(&mut file, &mut outfile)?;
        }
    }
    Ok(())
}

async fn install_package(manifest: &Manifest, arch: &str) -> Result<()> {
    let architecture = manifest.architecture.get(arch).ok_or(ScoopError::MissingArchitecture)?;
    let url = architecture.url.as_deref().ok_or(ScoopError::InvalidUrl)?;
    let hash = architecture.hash.as_deref().ok_or(ScoopError::HashVerification)?;
    let file_name = Path::new(url).file_name().ok_or(ScoopError::InvalidUrl)?;
    let download_path = format!("downloads/{}", file_name.to_string_lossy());

    download_file(url, &download_path).await?;

    if !verify_hash(&download_path, hash)? {
        return Err(ScoopError::HashVerification);
    }

    let extract_dir = architecture.extract_dir.as_deref().unwrap_or("");
    extract_zip(&download_path, extract_dir).await?;

    if let Some(description) = &manifest.description {
        if let Some(version) = &manifest.version {
            println!("Installed {} version {}", description, version);
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let manifest_data = r#"
    {
        "version": "1.39.0",
        "description": "A new way to see and navigate directory trees",
        "homepage": "https://dystroy.org/broot/",
        "license": "MIT",
        "architecture": {
            "64bit": {
                "url": "https://github.com/Canop/broot/releases/download/v1.39.0/broot_1.39.0.zip",
                "hash": "720fa5aa1d7ed54a994b6210ddab32255cf76ca3e18c1bb479d296fd05dc4a92",
                "extract_dir": "x86_64-pc-windows-gnu"
            }
        },
        "bin": ["broot.exe"],
        "checkver": {
            "github": "https://github.com/Canop/broot"
        },
        "autoupdate": {
            "architecture": {
                "64bit": {
                    "url": "https://github.com/Canop/broot/releases/download/v$version/broot_$version.zip"
                }
            }
        }
    }
    "#;

    let manifest: Manifest = serde_json::from_str(manifest_data)?;
    install_package(&manifest, "64bit").await?;

    Ok(())
}