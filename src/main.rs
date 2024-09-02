use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use minimo::banner::Banner;
use regex::Regex;
use reqwest;
use serde::{Deserialize, Serialize};
use serde_json;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::error::Error;
use std::fmt;
use std::fs;
use std::io::copy;
use std::path::{Path, PathBuf};
use std::process::Command;
use yaml_rust::YamlLoader;

type Result<T> = std::result::Result<T, Box<dyn Error>>;

#[derive(Debug)]
struct GetError(String);

impl fmt::Display for GetError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl Error for GetError {}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub repos: Vec<String>,
    pub download_dir: PathBuf,
}

impl Config {
    pub fn new() -> Self {
        Config {
            repos: vec!["https://github.com/microsoft/winget-pkgs".to_string()],
            download_dir: PathBuf::from("downloads"),
        }
    }

    pub fn load() -> Result<Self> {
        let path = Path::new("config.toml");
        if !path.exists() {
            let config = Config::new();
            config.save()?;
            return Ok(config);
        }
        let contents = fs::read_to_string(path)?;
        let config: Config = toml::from_str(&contents)?;
        Ok(config)
    }

    pub fn save(&self) -> Result<()> {
        let path = Path::new("config.toml");
        let toml = toml::to_string(&self)?;
        fs::write(path, toml)?;
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WingetManifest {
    package_identifier: String,
    package_name: String,
    package_version: String,
    publisher: String,
    license: Option<String>,
    short_description: Option<String>,
    description: Option<String>,
    homepage: Option<String>,
    installers: Vec<WingetInstaller>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WingetInstaller {
    architecture: String,
    installer_type: String,
    installer_url: String,
    installer_sha256: String,
    scope: Option<String>,
    silent_args: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChocolateyManifest {
    id: String,
    version: String,
    title: Option<String>,
    authors: Option<String>,
    owners: Option<String>,
    description: Option<String>,
    project_url: Option<String>,
    package_source_url: Option<String>,
    tags: Option<Vec<String>>,
    license_url: Option<String>,
    icon_url: Option<String>,
    release_notes: Option<String>,
    dependencies: Option<Vec<ChocolateyDependency>>,
    files: Vec<ChocolateyFile>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChocolateyDependency {
    id: String,
    version: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChocolateyFile {
    src: String,
    target: String,
}

pub struct Get {
    config: Config,
    installed_apps: HashMap<String, String>,
}

impl Get {
    pub fn new() -> Result<Self> {
        let config = Config::load()?;
        let installed_apps = Self::load_installed_apps()?;
        Ok(Get {
            config,
            installed_apps,
        })
    }

    fn load_installed_apps() -> Result<HashMap<String, String>> {
        let path = Path::new("installed_apps.json");
        if !path.exists() {
            return Ok(HashMap::new());
        }
        let contents = fs::read_to_string(path)?;
        let apps: HashMap<String, String> = serde_json::from_str(&contents)?;
        Ok(apps)
    }

    fn save_installed_apps(&self) -> Result<()> {
        let path = Path::new("installed_apps.json");
        let json = serde_json::to_string(&self.installed_apps)?;
        fs::write(path, json)?;
        Ok(())
    }

    pub fn parse_winget_manifest(&self, manifest_path: &str) -> Result<WingetManifest> {
        let contents = fs::read_to_string(manifest_path)?;
        let docs = YamlLoader::load_from_str(&contents)?;
        let doc = &docs[0];

        let mut installers = Vec::new();
        if let Some(installer_list) = doc["Installers"].as_vec() {
            for installer in installer_list {
                installers.push(WingetInstaller {
                    architecture: installer["Architecture"]
                        .as_str()
                        .unwrap_or("x64")
                        .to_string(),
                    installer_type: installer["InstallerType"]
                        .as_str()
                        .unwrap_or("")
                        .to_string(),
                    installer_url: installer["InstallerUrl"].as_str().unwrap_or("").to_string(),
                    installer_sha256: installer["InstallerSha256"]
                        .as_str()
                        .unwrap_or("")
                        .to_string(),
                    scope: installer["Scope"].as_str().map(String::from),
                    silent_args: installer["SilentArgs"].as_str().map(String::from),
                });
            }
        }

        Ok(WingetManifest {
            package_identifier: doc["PackageIdentifier"].as_str().unwrap_or("").to_string(),
            package_name: doc["PackageName"].as_str().unwrap_or("").to_string(),
            package_version: doc["PackageVersion"].as_str().unwrap_or("").to_string(),
            publisher: doc["Publisher"].as_str().unwrap_or("").to_string(),
            license: doc["License"].as_str().map(String::from),
            short_description: doc["ShortDescription"].as_str().map(String::from),
            description: doc["Description"].as_str().map(String::from),
            homepage: doc["Homepage"].as_str().map(String::from),
            installers,
        })
    }

    pub fn parse_chocolatey_manifest(&self, manifest_path: &str) -> Result<ChocolateyManifest> {
        let contents = fs::read_to_string(manifest_path)?;
        let manifest: ChocolateyManifest = serde_json::from_str(&contents)?;
        Ok(manifest)
    }

    pub fn install_winget_package(&mut self, manifest: &WingetManifest) -> Result<()> {
        println!(
            "{}",
            format!(
                "Installing {} using Winget manifest...",
                manifest.package_name
            )
            .green()
        );

        let installer = manifest
            .installers
            .first()
            .ok_or(GetError("No installer found".into()))?;

        let installer_filename = Path::new(&installer.installer_url)
            .file_name()
            .unwrap()
            .to_str()
            .unwrap();
        let installer_path = self.config.download_dir.join(installer_filename);

        self.download_file(&installer.installer_url, &installer_path)?;
        self.verify_sha256(&installer_path, &installer.installer_sha256)?;

        let mut cmd = match installer.installer_type.as_str() {
            "msi" => {
                let mut c = Command::new("msiexec");
                c.arg("/i").arg(&installer_path);
                if let Some(args) = &installer.silent_args {
                    c.args(args.split_whitespace());
                } else {
                    c.arg("/qn");
                }
                c
            }
            "exe" | "inno" | "nullsoft" => {
                let mut c = Command::new(&installer_path);
                if let Some(args) = &installer.silent_args {
                    c.args(args.split_whitespace());
                } else {
                    c.arg("/S");
                }
                c
            }
            _ => {
                return Err(Box::new(GetError(format!(
                    "Unsupported installer type: {}",
                    installer.installer_type
                ))))
            }
        };

        let output = cmd.output()?;
        if output.status.success() {
            println!(
                "{}",
                format!("{} installed successfully", manifest.package_name).green()
            );
            self.installed_apps.insert(
                manifest.package_identifier.clone(),
                manifest.package_version.clone(),
            );
            self.save_installed_apps()?;
            Ok(())
        } else {
            let error_message = String::from_utf8_lossy(&output.stderr);
            Err(Box::new(GetError(format!(
                "Failed to install {}: {}",
                manifest.package_name, error_message
            ))))
        }
    }

    pub fn install_chocolatey_package(&mut self, manifest: &ChocolateyManifest) -> Result<()> {
        println!(
            "{}",
            format!("Installing {} using Chocolatey manifest...", manifest.id).green()
        );

        let temp_dir = tempfile::tempdir()?;
        let package_dir = temp_dir.path().join(&manifest.id);
        fs::create_dir(&package_dir)?;

        let pb = ProgressBar::new(manifest.files.len() as u64);
        pb.set_style(
            ProgressStyle::default_bar()
                .template(
                    "{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})",
                )
                .unwrap()
                .progress_chars("#>-"),
        );

        for file in &manifest.files {
            let file_path = package_dir.join(&file.target);
            if let Some(parent) = file_path.parent() {
                fs::create_dir_all(parent)?;
            }
            self.download_file(&file.src, &file_path)?;
            pb.inc(1);
        }

        pb.finish_with_message("All files downloaded");

        let chocolateyinstall_ps1 = package_dir.join("tools").join("chocolateyinstall.ps1");
        if chocolateyinstall_ps1.exists() {
            let output = Command::new("powershell")
                .arg("-ExecutionPolicy")
                .arg("Bypass")
                .arg("-File")
                .arg(&chocolateyinstall_ps1)
                .output()?;

            if !output.status.success() {
                let error_message = String::from_utf8_lossy(&output.stderr);
                return Err(Box::new(GetError(format!(
                    "Failed to install {}: {}",
                    manifest.id, error_message
                ))));
            }
        }

        println!(
            "{}",
            format!("{} installed successfully", manifest.id).green()
        );
        self.installed_apps
            .insert(manifest.id.clone(), manifest.version.clone());
        self.save_installed_apps()?;
        Ok(())
    }

    pub fn uninstall_winget_package(&mut self, manifest: &WingetManifest) -> Result<()> {
        println!(
            "{}",
            format!(
                "Uninstalling {} using Winget manifest...",
                manifest.package_name
            )
            .yellow()
        );

        let installer = manifest
            .installers
            .first()
            .ok_or(GetError("No installer found".into()))?;

        let mut cmd = match installer.installer_type.as_str() {
            "msi" => {
                let mut c = Command::new("msiexec");
                c.arg("/x").arg(&manifest.package_identifier);
                if let Some(args) = &installer.silent_args {
                    c.args(args.split_whitespace());
                } else {
                    c.arg("/qn");
                }
                c
            }
            "exe" | "inno" | "nullsoft" => {
                let uninstaller_path = self.find_uninstaller(&manifest.package_name)?;
                let mut c = Command::new(&uninstaller_path);
                if let Some(args) = &installer.silent_args {
                    c.args(args.split_whitespace());
                } else {
                    c.arg("/S");
                }
                c
            }
            _ => {
                return Err(Box::new(GetError(format!(
                    "Unsupported installer type: {}",
                    installer.installer_type
                ))))
            }
        };

        let output = cmd.output()?;
        if output.status.success() {
            println!(
                "{}",
                format!("{} uninstalled successfully", manifest.package_name).green()
            );
            self.installed_apps.remove(&manifest.package_identifier);
            self.save_installed_apps()?;
            Ok(())
        } else {
            let error_message = String::from_utf8_lossy(&output.stderr);
            Err(Box::new(GetError(format!(
                "Failed to uninstall {}: {}",
                manifest.package_name, error_message
            ))))
        }
    }

    pub fn uninstall_chocolatey_package(&mut self, manifest: &ChocolateyManifest) -> Result<()> {
        println!(
            "{}",
            format!("Uninstalling {} using Chocolatey manifest...", manifest.id).yellow()
        );

        let chocolateyuninstall_ps1 = PathBuf::from("C:\\ProgramData\\chocolatey\\lib")
            .join(&manifest.id)
            .join("tools")
            .join("chocolateyuninstall.ps1");

        if chocolateyuninstall_ps1.exists() {
            let output = Command::new("powershell")
                .arg("-ExecutionPolicy")
                .arg("Bypass")
                .arg("-File")
                .arg(&chocolateyuninstall_ps1)
                .output()?;

            if !output.status.success() {
                let error_message = String::from_utf8_lossy(&output.stderr);
                return Err(Box::new(GetError(format!(
                    "Failed to uninstall {}: {}",
                    manifest.id, error_message
                ))));
            }
        } else {
            let uninstaller_path = self.find_uninstaller(&manifest.id)?;
            let output = Command::new(&uninstaller_path).arg("/S").output()?;

            if !output.status.success() {
                let error_message = String::from_utf8_lossy(&output.stderr);
                return Err(Box::new(GetError(format!(
                    "Failed to uninstall {}: {}",
                    manifest.id, error_message
                ))));
            }
        }

        println!(
            "{}",
            format!("{} uninstalled successfully", manifest.id).green()
        );
        self.installed_apps.remove(&manifest.id);
        self.save_installed_apps()?;
        Ok(())
    }

    fn download_file(&self, url: &str, target: &Path) -> Result<()> {
        let mut response = reqwest::blocking::get(url)?;
        let mut file = fs::File::create(target)?;
        copy(&mut response, &mut file)?;
        Ok(())
    }

    fn verify_sha256(&self, file_path: &Path, expected_hash: &str) -> Result<()> {
        let mut file = fs::File::open(file_path)?;
        let mut hasher = Sha256::new();
        copy(&mut file, &mut hasher)?;
        let hash = format!("{:x}", hasher.finalize());
        if hash == expected_hash {
            Ok(())
        } else {
            Err(Box::new(GetError(format!(
                "SHA256 mismatch for {}",
                file_path.display()
            ))))
        }
    }

    fn find_uninstaller(&self, package_name: &str) -> Result<PathBuf> {
        let output = Command::new("reg")
            .args(&[
                "query",
                r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                "/s",
                "/f",
                package_name,
            ])
            .output()?;

        let output_str = String::from_utf8_lossy(&output.stdout);
        let re = Regex::new(r"UninstallString\s+REG_SZ\s+(.+)")?;

        if let Some(caps) = re.captures(&output_str) {
            if let Some(uninstaller_path) = caps.get(1) {
                return Ok(PathBuf::from(uninstaller_path.as_str().trim()));
            }
        }

        Err(Box::new(GetError(format!(
            "Uninstaller not found for {}",
            package_name
        ))))
    }

    pub fn install_from_manifest(&mut self, manifest_path: &str) -> Result<()> {
        let path = Path::new(manifest_path);
        if !path.exists() {
            return Err(Box::new(GetError(format!(
                "Manifest file not found: {}",
                manifest_path
            ))));
        }

        if path.extension().and_then(|s| s.to_str()) == Some("yaml") {
            let manifest = self.parse_winget_manifest(manifest_path)?;
            self.install_winget_package(&manifest)
        } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
            let manifest = self.parse_chocolatey_manifest(manifest_path)?;
            self.install_chocolatey_package(&manifest)
        } else {
            Err(Box::new(GetError("Unsupported manifest format".into())))
        }
    }

    pub fn uninstall_from_manifest(&mut self, manifest_path: &str) -> Result<()> {
        let path = Path::new(manifest_path);
        if !path.exists() {
            return Err(Box::new(GetError(format!(
                "Manifest file not found: {}",
                manifest_path
            ))));
        }

        if path.extension().and_then(|s| s.to_str()) == Some("yaml") {
            let manifest = self.parse_winget_manifest(manifest_path)?;
            self.uninstall_winget_package(&manifest)
        } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
            let manifest = self.parse_chocolatey_manifest(manifest_path)?;
            self.uninstall_chocolatey_package(&manifest)
        } else {
            Err(Box::new(GetError("Unsupported manifest format".into())))
        }
    }

    pub fn list_installed_apps(&self) -> Result<()> {
        println!("{}", "Installed applications:".cyan().bold());
        for (app_id, version) in &self.installed_apps {
            println!("{} ({})", app_id.green(), version.blue());
        }
        Ok(())
    }

    pub fn update_all(&mut self) -> Result<()> {
        println!("{}", "Updating all installed applications...".cyan().bold());
        let apps_to_update: Vec<(String, String)> =
            self.installed_apps.clone().into_iter().collect();

        for (app_id, installed_version) in apps_to_update {
            match self.update_app(&app_id, &installed_version) {
                Ok(_) => println!("{}", format!("Updated {}", app_id).green()),
                Err(e) => println!("{}", format!("Failed to update {}: {}", app_id, e).red()),
            }
        }
        Ok(())
    }

    fn update_app(&mut self, app_id: &str, installed_version: &str) -> Result<()> {
        let manifest_path = self.find_manifest(app_id)?;

        if manifest_path.extension().and_then(|s| s.to_str()) == Some("yaml") {
            let manifest = self.parse_winget_manifest(&manifest_path.to_string_lossy())?;
            if first_is_greater(&manifest.package_version, installed_version) {
                self.install_winget_package(&manifest)?;
            }
        } else if manifest_path.extension().and_then(|s| s.to_str()) == Some("json") {
            let manifest = self.parse_chocolatey_manifest(&manifest_path.to_string_lossy())?;
            if first_is_greater(&manifest.version, installed_version) {
                self.install_chocolatey_package(&manifest)?;
            }
        } else {
            return Err(Box::new(GetError("Unsupported manifest format".into())));
        }

        Ok(())
    }

    fn find_manifest(&self, app_id: &str) -> Result<PathBuf> {
        for repo in &self.config.repos {
            let repo_path = Path::new(repo);
            if repo_path.is_dir() {
                let winget_path = repo_path
                    .join("manifests")
                    .join(app_id)
                    .with_extension("yaml");
                if winget_path.exists() {
                    return Ok(winget_path);
                }
                let choco_path = repo_path
                    .join("manifests")
                    .join(app_id)
                    .with_extension("json");
                if choco_path.exists() {
                    return Ok(choco_path);
                }
            } else {
                // TODO: Implement remote repository search
                println!(
                    "{}",
                    format!(
                        "Searching remote repository {} is not yet implemented",
                        repo
                    )
                    .yellow()
                );
            }
        }
        Err(Box::new(GetError(format!(
            "Manifest not found for {}",
            app_id
        ))))
    }

    pub fn search(&self, query: &str) -> Result<()> {
        println!("{}", format!("Searching for '{}'...", query).cyan().bold());
        let mut results = Vec::new();

        for repo in &self.config.repos {
            let repo_path = Path::new(repo);
            if repo_path.is_dir() {
                self.search_local_repo(repo_path, query, &mut results)?;
            } else {
                // TODO: Implement remote repository search
                println!(
                    "{}",
                    format!(
                        "Searching remote repository {} is not yet implemented",
                        repo
                    )
                    .yellow()
                );
            }
        }

        if results.is_empty() {
            println!("{}", "No results found.".yellow());
        } else {
            for result in results {
                println!("{} ({})", result.0.green(), result.1.blue());
            }
        }

        Ok(())
    }

    fn search_local_repo(
        &self,
        repo_path: &Path,
        query: &str,
        results: &mut Vec<(String, String)>,
    ) -> Result<()> {
        let manifests_dir = repo_path.join("manifests");
        if !manifests_dir.is_dir() {
            return Ok(());
        }

        for entry in fs::read_dir(manifests_dir)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    if ext == "yaml" {
                        let manifest = self.parse_winget_manifest(&path.to_string_lossy())?;
                        if manifest
                            .package_name
                            .to_lowercase()
                            .contains(&query.to_lowercase())
                        {
                            results.push((manifest.package_name, manifest.package_version));
                        }
                    } else if ext == "json" {
                        let manifest = self.parse_chocolatey_manifest(&path.to_string_lossy())?;
                        if manifest.id.to_lowercase().contains(&query.to_lowercase()) {
                            results.push((manifest.id, manifest.version));
                        }
                    }
                }
            }
        }

        Ok(())
    }
}

pub fn first_is_greater(first: &str, second: &str) -> bool {
    let first_parts = first.split('.').collect::<Vec<&str>>();
    let second_parts = second.split('.').collect::<Vec<&str>>();
    first_parts[0] > second_parts[0]
}

#[derive(Clone, Debug, Default)]
pub struct Launch {
    pub mode: LaunchMode,
    pub args: Vec<String>,
}

#[derive(Clone, Debug, Default)]
pub enum LaunchMode {
    Install(Vec<String>),
    Uninstall(Vec<String>),
    List,
    Add(AddMode),
    Remove(RemoveMode),
    Search(String),
    Update(Option<String>),
    Set(SetMode),
    Help,
    Version,
    #[default]
    None,
}

#[derive(Clone, Debug)]
pub enum AddMode {
    Repo(String),
    App(Vec<String>),
}

#[derive(Clone, Debug)]
pub enum RemoveMode {
    Repo(String),
    App(Vec<String>),
}

#[derive(Clone, Debug)]
pub enum SetMode {
    DownloadDir(PathBuf),
}

impl Launch {
    pub fn parse() -> Launch {
        let args: Vec<String> = std::env::args().skip(1).collect();
        let (mode, remaining_args) = LaunchMode::parse(&args);
        Launch {
            mode,
            args: remaining_args,
        }
    }
}

impl LaunchMode {
    pub fn parse(args: &[String]) -> (LaunchMode, Vec<String>) {
        if args.is_empty() {
            return (LaunchMode::Help, Vec::new());
        }

        match args[0].as_str() {
            "install" | "get" => {
                if args.len() > 1 {
                    (LaunchMode::Install(args[1..].to_vec()), Vec::new())
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "uninstall" | "remove" => {
                if args.len() > 1 {
                    (LaunchMode::Uninstall(args[1..].to_vec()), Vec::new())
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "list" => (LaunchMode::List, args[1..].to_vec()),
            "add" => {
                if args.len() > 2 && args[1] == "repo" {
                    (
                        LaunchMode::Add(AddMode::Repo(args[2].clone())),
                        args[3..].to_vec(),
                    )
                } else if args.len() > 1 {
                    (
                        LaunchMode::Add(AddMode::App(args[1..].to_vec())),
                        Vec::new(),
                    )
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "remove" => {
                if args.len() > 2 && args[1] == "repo" {
                    (
                        LaunchMode::Remove(RemoveMode::Repo(args[2].clone())),
                        args[3..].to_vec(),
                    )
                } else if args.len() > 1 {
                    (
                        LaunchMode::Remove(RemoveMode::App(args[1..].to_vec())),
                        Vec::new(),
                    )
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "search" => {
                if args.len() > 1 {
                    (LaunchMode::Search(args[1].clone()), args[2..].to_vec())
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "update" => {
                if args.len() > 1 {
                    (
                        LaunchMode::Update(Some(args[1].clone())),
                        args[2..].to_vec(),
                    )
                } else {
                    (LaunchMode::Update(None), Vec::new())
                }
            }
            "set" => {
                if args.len() > 2 && args[1] == "download-dir" {
                    (
                        LaunchMode::Set(SetMode::DownloadDir(PathBuf::from(&args[2]))),
                        args[3..].to_vec(),
                    )
                } else {
                    (LaunchMode::Help, Vec::new())
                }
            }
            "help" => (LaunchMode::Help, args[1..].to_vec()),
            "version" => (LaunchMode::Version, args[1..].to_vec()),
            _ => (LaunchMode::Install(args.to_vec()), Vec::new()), // Assume it's an app name if not recognized
        }
    }
}

impl Get {
    pub fn run(&mut self, launch: Launch) -> Result<()> {
        match launch.mode {
            LaunchMode::Install(apps) => {
                for app in apps {
                    match self.install_app(&app) {
                        Ok(_) => println!("{} installed successfully", app.green()),
                        Err(e) => println!("Failed to install {}: {}", app.red(), e),
                    }
                }
            }
            LaunchMode::Uninstall(apps) => {
                for app in apps {
                    match self.uninstall_app(&app) {
                        Ok(_) => println!("{} uninstalled successfully", app.green()),
                        Err(e) => println!("Failed to uninstall {}: {}", app.red(), e),
                    }
                }
            }
            LaunchMode::List => {
                self.list_installed_apps()?;
            }
            LaunchMode::Add(add_mode) => match add_mode {
                AddMode::Repo(repo) => {
                    self.config.repos.push(repo);
                    self.config.save()?;
                    println!("Repository added successfully");
                }
                AddMode::App(apps) => {
                    for app in apps {
                        match self.install_app(&app) {
                            Ok(_) => println!("{} installed successfully", app.green()),
                            Err(e) => println!("Failed to install {}: {}", app.red(), e),
                        }
                    }
                }
            },
            LaunchMode::Remove(remove_mode) => match remove_mode {
                RemoveMode::Repo(repo) => {
                    self.config.repos.retain(|r| r != &repo);
                    self.config.save()?;
                    println!("Repository removed successfully");
                }
                RemoveMode::App(apps) => {
                    for app in apps {
                        match self.uninstall_app(&app) {
                            Ok(_) => println!("{} uninstalled successfully", app.green()),
                            Err(e) => println!("Failed to uninstall {}: {}", app.red(), e),
                        }
                    }
                }
            },
            LaunchMode::Search(query) => {
                self.search(&query)?;
            }
            LaunchMode::Update(app) => match app {
                Some(app_name) => {
                    // match self.update_app(
                    //     &app_name,
                    //     self.installed_apps.get(&app_name).unwrap_or(&String::new()),
                    // ) {
                    //     Ok(_) => println!("{} updated successfully", app_name.green()),
                    //     Err(e) => println!("Failed to update {}: {}", app_name.red(), e),
                    // }
                }
                None => self.update_all()?,
            },
            LaunchMode::Set(set_mode) => match set_mode {
                SetMode::DownloadDir(path) => {
                    self.config.download_dir = path;
                    self.config.save()?;
                    println!("Download directory updated successfully");
                }
            },
            LaunchMode::Help => {
                self.print_help();
            }
            LaunchMode::Version => {
                println!("get version 1.0.0");
            }
            LaunchMode::None => {
                println!("No valid command provided. Use 'get help' for usage information.");
            }
        }
        Ok(())
    }

    fn install_app(&mut self, app_name: &str) -> Result<()> {
        let manifest_path = self.find_manifest(app_name)?;
        self.install_from_manifest(&manifest_path.to_string_lossy()) 
    }

    fn uninstall_app(&mut self, app_name: &str) -> Result<()> {
        let manifest_path = self.find_manifest(app_name)?;
        self.uninstall_from_manifest(&manifest_path.to_string_lossy())
    }

    fn print_help(&self) {
        minimo::set_max_width(60);
        println!("");
        Banner::new("superget").show(gray_dim);
        println!("");
        divider_vibrant();
        minimo::show_wrapped!(
        gray_dim, "you can search for apps using ",yellow_bold, "get find <app-name>",
        gray_dim, "or directly install known apps using ",yellow_bold, "get install <app-name>",
        gray_dim, "or even shorter ",yellow_bold, "get <app-name>",gray_dim,". no matter the app you are looking for is on winget/chocolatey/scoop/github get will find it for you."

       );
        divider();
    }
}
use minimo::*;
fn main() -> Result<()> {
    let mut get = Get::new()?;
    let launch = Launch::parse();
    get.run(launch)
}
