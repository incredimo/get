use duct::cmd;
///! # get
///! get is a simple application installer / package manager for windows and linux.
///! get listens to various get repos to easily install applications. users can also add their own repos.
///! get can easily use winget, scoop, choco (soon more) manifests to install applications.
///! get parses the manifests of these package managers, understands the dependencies and installs them.
///! (not using the package manager itself). so regardless of the package manager, get will install the applications the get way.
///! get also has a simple yet very powerful manifest format that can be used to install applications.
///!
///! ## get manifest
///! get manifests are simple json files that lists out a list of steps to install/uninstall/download/update an application.
///! git steps are simple and easy to understand and can be used to explain any process one step at a time.
///! get steps also support variables and conditions to make the steps more dynamic and powerful.
///!
///! ## usage
///! you can search for any application using `get <app-name>` and install it using `get install <app-name>`.
///! you can also list all the installed applications using `get list`. by default get uses few official repos to search for applications.
///! you can add your own repos using `get add <repo-url>`. you can also remove the repos using `get remove <repo-url>`.
///! get searches for the application in all the repos and installs the application from the first repo that has the application.
///! you can also define a priority using `get config` and editing the `repos` field in the config.toml file.
///! get also has a `get update` command that updates all the installed applications.
///! get also has a `get uninstall <app-name>` command that uninstalls the application.
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::fs;
use std::io::{Write, Read};
use std::process::Command;
use reqwest;
use zip;
use std::env;
use std::thread;
use std::time::Duration;
use regex::Regex;
use url::Url;
use indicatif::{ProgressBar, ProgressStyle};
use colored::*;

type Result<T> = std::result::Result<T, Box<dyn std::error::Error + Send + Sync>>;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub repos: Vec<String>,
    pub download_dir: PathBuf,
}

impl Config {
    pub fn new() -> Self {
        Config {
            repos: vec!["https://example.com/default-repo.json".to_string()],
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
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        let config: Config = toml::from_str(&contents)?;
        Ok(config)
    }

    pub fn save(&self) -> Result<()> {
        let path = Path::new("config.toml");
        let mut file = fs::File::create(path)?;
        let toml = toml::to_string(&self)?;
        file.write_all(toml.as_bytes())?;
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Repository {
    pub url: String,
    pub description: Option<String>,
}

impl Repository {
    pub fn new(url: &str, description: Option<&str>) -> Self {
        Repository {
            url: url.to_string(),
            description: description.map(|s| s.to_string()),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct App {
    pub identifier: String,
    pub name: String,
    pub description: Option<String>,
    pub version: String,
    pub platform: String,
    pub architecture: String,
    pub install_steps: Vec<Step>,
    pub uninstall_steps: Vec<Step>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type")]
pub enum Step {
    Download { url: String, target: String },
    Extract { source: String, target: String },
    Run { command: String, args: Vec<String> },
    Copy { source: String, target: String },
    Delete { target: String },
    CreateDir { target: String },
    SetEnv { name: String, value: String },
    UnsetEnv { name: String },
    SetRegistry { key: String, value: String },
    RemoveRegistry { key: String },
}

#[derive(Debug, Clone)]
pub struct Get {
    config: Config,
    repos: Vec<Repository>,
    installed_apps: HashMap<String, App>,
}

impl Get {
    pub fn new() -> Result<Self> {
        let config = Config::load()?;
        let repos = config.repos.iter().map(|url| Repository::new(url, None)).collect();
        let installed_apps = Self::load_installed_apps()?;
        Ok(Get { config, repos, installed_apps })
    }

    fn load_installed_apps() -> Result<HashMap<String, App>> {
        let path = Path::new("installed_apps.json");
        if !path.exists() {
            return Ok(HashMap::new());
        }
        let file = fs::File::open(path)?;
        let apps: HashMap<String, App> = serde_json::from_reader(file)?;
        Ok(apps)
    }

    fn save_installed_apps(&self) -> Result<()> {
        let path = Path::new("installed_apps.json");
        let file = fs::File::create(path)?;
        serde_json::to_writer(file, &self.installed_apps)?;
        Ok(())
    }

    pub fn search(&self, app_name: &str) -> Result<Vec<App>> {
        let mut results = Vec::new();
        for repo in &self.repos {
            let apps = self.get_apps_from_repo(&repo.url)?;
            results.extend(apps.into_iter().filter(|app| app.name.to_lowercase().contains(&app_name.to_lowercase())));
        }
        Ok(results)
    }

    fn get_apps_from_repo(&self, repo_url: &str) -> Result<Vec<App>> {
        if Url::parse(repo_url).is_ok() {
            let repo_apps: Vec<App> = reqwest::blocking::get(repo_url)?.json()?;
            Ok(repo_apps)
        } else {
            let path = PathBuf::from(repo_url);
            let file = fs::File::open(path)?;
            let repo_apps: Vec<App> = serde_json::from_reader(file)?;
            Ok(repo_apps)
        }
    }

    pub fn install(&mut self, app_name: &str) -> Result<()> {
        let app = self.search(app_name)?
            .into_iter()
            .next()
            .ok_or("App not found")?;

        println!("{}", format!("Installing {}...", app.name).green().bold());

        let pb = ProgressBar::new(app.install_steps.len() as u64);
        pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] {bar:40.cyan/blue} {pos}/{len} {msg}")
            .unwrap()
            .progress_chars("#>-"));

        for (index, step) in app.install_steps.iter().enumerate() {
            let step_name = self.get_step_name(step);
            pb.set_message(format!("Step {}: {}", index + 1, step_name));
            self.execute_step(step)?;
            pb.inc(1);
            thread::sleep(Duration::from_millis(100));
        }

        pb.finish_with_message(format!("{} installed successfully", app.name));

        self.installed_apps.insert(app.identifier.clone(), app);
        self.save_installed_apps()?;
        Ok(())
    }

    pub fn uninstall(&mut self, app_name: &str) -> Result<()> {
        let app = self.installed_apps.remove(app_name).ok_or("App not installed")?;

        println!("{}", format!("Uninstalling {}...", app.name).red().bold());

        let pb = ProgressBar::new(app.uninstall_steps.len() as u64);
        pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.red} [{elapsed_precise}] {bar:40.cyan/blue} {pos}/{len} {msg}")
            .unwrap()
            .progress_chars("#>-"));

        for (index, step) in app.uninstall_steps.iter().enumerate() {
            let step_name = self.get_step_name(step);
            pb.set_message(format!("Step {}: {}", index + 1, step_name));
            self.execute_step(step)?;
            pb.inc(1);
            thread::sleep(Duration::from_millis(100));
        }

        pb.finish_with_message(format!("{} uninstalled successfully", app.name));

        self.save_installed_apps()?;
        Ok(())
    }

    fn execute_step(&self, step: &Step) -> Result<()> {
        match step {
            Step::Download { url, target } => {
                let target_path = self.config.download_dir.join(target);
                let mut response = reqwest::blocking::get(url)?;
                let mut file = fs::File::create(target_path)?;
                response.copy_to(&mut file)?;
            }
            Step::Extract { source, target } => {
                let source_path = self.config.download_dir.join(source);
                let target_path = PathBuf::from(target);
                let file = fs::File::open(source_path)?;
                let mut archive = zip::ZipArchive::new(file)?;
                archive.extract(target_path)?;
            }
            Step::Run { command, args } => {
                Command::new(command)
                .current_dir(&self.config.download_dir)
                    .args(args)
                    .output()?;
            }
            Step::Copy { source, target } => {
                let source_path = self.config.download_dir.join(source);
                let target_path = PathBuf::from(target);
                fs::copy(source_path, target_path)?;
            }
            Step::Delete { target } => {
                let target_path = PathBuf::from(target);
                if target_path.is_file() {
                    fs::remove_file(target_path)?;
                } else if target_path.is_dir() {
                    fs::remove_dir_all(target_path)?;
                }
            }
            Step::CreateDir { target } => {
                fs::create_dir_all(target)?;
            }
            Step::SetEnv { name, value } => {
                env::set_var(name, value);
            }
            Step::UnsetEnv { name } => {
                env::remove_var(name);
            } 
            _ => {}
        }
        Ok(())
    }

    fn get_step_name(&self, step: &Step) -> String {
        match step {
            Step::Download { .. } => "Downloading".to_string(),
            Step::Extract { .. } => "Extracting".to_string(),
            Step::Run { .. } => "Running command".to_string(),
            Step::Copy { .. } => "Copying files".to_string(),
            Step::Delete { .. } => "Deleting files".to_string(),
            Step::CreateDir { .. } => "Creating directory".to_string(),
            Step::SetEnv { .. } => "Setting environment variable".to_string(),
            Step::UnsetEnv { .. } => "Unsetting environment variable".to_string(),
            _ => "unimplemented function".to_string(),
        }
    }

    pub fn list(&self) -> Vec<&App> {
        self.installed_apps.values().collect()
    }

    pub fn update(&mut self) -> Result<()> {
        println!("{}", "Checking for updates...".cyan().bold());
        let cloned_self = self.clone();
        let pb = ProgressBar::new(cloned_self.installed_apps.len() as u64);
        pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] {bar:40.cyan/blue} {pos}/{len} {msg}")
            .unwrap()
            .progress_chars("#>-"));

        for app in cloned_self.installed_apps.values() {
            pb.set_message(format!("Checking {}", app.name));
            match self.search(&app.name) {
                Ok(search_results) => {
                    if let Some(latest_version) = search_results.into_iter().next() {
                        if latest_version.version != app.version {
                            println!("{}", format!("Updating {} from {} to {}", app.name, app.version, latest_version.version).yellow());
                            self.uninstall(&app.identifier)?;
                            self.install(&latest_version.name)?;
                        }
                    }
                },
                Err(e) => eprintln!("{}", format!("Error checking for updates for {}: {}", app.name, e).red()),
            }
            pb.inc(1);
        }

        pb.finish_with_message("Update check completed");
        Ok(())
    }

    pub fn add_repo(&mut self, url: &str, description: Option<&str>) -> Result<()> {
        let repo = Repository::new(url, description);
        self.repos.push(repo);
        self.config.repos.push(url.to_string());
        self.config.save()?;
        println!("{}", format!("Added repository: {}", url).green());
        Ok(())
    }

    pub fn remove_repo(&mut self, url: &str) -> Result<()> {
        self.repos.retain(|r| r.url != url);
        self.config.repos.retain(|r| r != url);
        self.config.save()?;
        println!("{}", format!("Removed repository: {}", url).yellow());
        Ok(())
    }
}

fn main() -> Result<()> {
    let mut get = Get::new()?;
    
    match std::env::args().nth(1).as_deref() {
        Some("search") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            println!("{}", format!("Searching for {}...", app_name).cyan().bold());
            match get.search(&app_name) {
                Ok(apps) => {
                    if apps.is_empty() {
                        println!("{}", "No applications found.".yellow());
                    } else {
                        for app in apps {
                            println!("{} ({}):\n    {}", 
                                app.name.green().bold(), 
                                app.version.blue(),
                                app.description.as_deref().unwrap_or("No description available").italic()
                            );
                        }
                    }
                },
                Err(e) => eprintln!("{}", format!("Error searching for applications: {}", e).red()),
            }
        }
        Some("install") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            match get.install(&app_name) {
                Ok(_) => println!("{}", format!("{} installed successfully", app_name).green().bold()),
                Err(e) => eprintln!("{}", format!("Error installing {}: {}", app_name, e).red()),
            }
        }
        Some("uninstall") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            match get.uninstall(&app_name) {
                Ok(_) => println!("{}", format!("{} uninstalled successfully", app_name).green().bold()),
                Err(e) => eprintln!("{}", format!("Error uninstalling {}: {}", app_name, e).red()),
            }
        }
        Some("list") => {
            println!("{}", "Installed applications:".cyan().bold());
            for app in get.list() {
                println!("{} ({})", app.name.green(), app.version.blue());
            }
        }
        Some("update") => {
            match get.update() {
                Ok(_) => println!("{}", "All applications updated successfully".green().bold()),
                Err(e) => eprintln!("{}", format!("Error updating applications: {}", e).red()),
            }
        }
        Some("add") => {
            let url = std::env::args().nth(2).expect("Provide a repo URL");
            let description = std::env::args().nth(3);
            match get.add_repo(&url, description.as_deref()) {
                Ok(_) => println!("{}", format!("Repository {} added successfully", url).green().bold()),
                Err(e) => eprintln!("{}", format!("Error adding repository {}: {}", url, e).red()),
            }
        }
        Some("remove") => {
            let url = std::env::args().nth(2).expect("Provide a repo URL");
            match get.remove_repo(&url) {
                Ok(_) => println!("{}", format!("Repository {} removed successfully", url).green().bold()),
                Err(e) => eprintln!("{}", format!("Error removing repository {}: {}", url, e).red()),
            }
        }
        _ => {
            println!("{}", "Usage: get <command> [args]".cyan());
            println!("{}", "Commands:".yellow());
            println!("  search <app-name>     : Search for an application");
            println!("  install <app-name>    : Install an application");
            println!("  uninstall <app-name>  : Uninstall an application");
            println!("  list                  : List installed applications");
            println!("  update                : Update all installed applications");
            println!("  add <repo-url> [desc] : Add a repository");
            println!("  remove <repo-url>     : Remove a repository");
        }
    }

    Ok(())
}