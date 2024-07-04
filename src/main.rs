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
use url::Url;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::fs;
use std::io::{Write, Read};
use std::process::Command;
use reqwest;
use tempfile::tempdir;
use zip;
use std::env;
use std::thread;
use std::time::Duration;
use regex::Regex;


type Result<T> = std::result::Result<T, Box<dyn std::error::Error + Send + Sync>>;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub repos: Vec<String>,
}

impl Config {
    pub fn new() -> Self {
        Config { repos: vec!["https://example.com/default-repo.json".to_string()] }
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
    pub edition: Option<String>,
    pub install_steps: Vec<StepWrapper>,
    pub uninstall_steps: Vec<StepWrapper>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type")]
pub enum Step {
    Download { url: String, target: String },
    Extract { source: String, target: String },
    Run { command: String, args: Vec<String> },
    Copy { source: String, target: String },
    Move { source: String, target: String },
    Delete { target: String },
    CreateDir { target: String },
    RemoveDir { target: String },
    Condition { condition: String, steps: Vec<StepWrapper> },
    Variable { name: String, value: String },
    Set { name: String, value: String },
    Unset { name: String },
    If { condition: String, steps: Vec<StepWrapper>, else_steps: Vec<StepWrapper> },
    For { variable: String, values: Vec<String>, steps: Vec<StepWrapper> },
    Include { file: String },
    Comment { text: String },
    Sleep { duration: u64 },
    SetEnv { name: String, value: String },
    UnsetEnv { name: String },
    SetRegistry { key: String, value: String },
    RemoveRegistry { key: String },
    JavaScript { code: String },
    Shell { script: String },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct StepWrapper {
    #[serde(flatten)]
    pub step: Step,
}

#[derive(Debug, Clone)]
pub struct Get {
    config: Config,
    repos: Vec<Repository>,
    installed_apps: HashMap<String, App>,
    variables: HashMap<String, String>,
}

impl Get {
    pub fn new() -> Result<Self> {
        let config = Config::load()?;
        let repos = config.repos.iter().map(|url| Repository::new(url, None)).collect();
        let installed_apps = Self::load_installed_apps()?;
        Ok(Get { config, repos, installed_apps, variables: HashMap::new() })
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
            // Remote repository
            let repo_apps: Vec<App> = reqwest::blocking::get(repo_url)?.json()?;
            Ok(repo_apps)
        } else {
            // Local repository
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

        let temp_dir = tempdir()?;

        for step in &app.install_steps {
            self.execute_step(step, temp_dir.path())?;
        }

        self.installed_apps.insert(app.identifier.clone(), app);
        self.save_installed_apps()?;
        Ok(())
    }

    pub fn uninstall(&mut self, app_name: &str) -> Result<()> {
        let app = self.installed_apps.remove(app_name).ok_or("App not installed")?;
        
        let temp_dir = tempdir()?;

        for step in &app.uninstall_steps {
            self.execute_step(step, temp_dir.path())?;
        }

        self.save_installed_apps()?;
        Ok(())
    }

    fn execute_step(&mut self, step: &StepWrapper, temp_dir: &Path) -> Result<()> {
        match &step.step {
            Step::Download { url, target } => {
                let target_path = temp_dir.join(target);
                let mut response = reqwest::blocking::get(url)?;
                let mut file = fs::File::create(target_path)?;
                response.copy_to(&mut file)?;
            }
            Step::Extract { source, target } => {
                let source_path = temp_dir.join(source);
                let target_path = temp_dir.join(target);
                let file = fs::File::open(source_path)?;
                let mut archive = zip::ZipArchive::new(file)?;
                archive.extract(target_path)?;
            }
            Step::Run { command, args } => {
                Command::new(command)
                    .args(args)
                    .current_dir(temp_dir)
                    .output()?;
            }
            Step::Copy { source, target } => {
                let source_path = temp_dir.join(source);
                let target_path = Path::new(target);
                fs::copy(source_path, target_path)?;
            }
            Step::Move { source, target } => {
                let source_path = temp_dir.join(source);
                let target_path = Path::new(target);
                fs::rename(source_path, target_path)?;
            }
            Step::Delete { target } => {
                let target_path = Path::new(target);
                if target_path.is_file() {
                    fs::remove_file(target_path)?;
                } else if target_path.is_dir() {
                    fs::remove_dir_all(target_path)?;
                }
            }
            Step::CreateDir { target } => {
                fs::create_dir_all(target)?;
            }
            Step::RemoveDir { target } => {
                fs::remove_dir_all(target)?;
            }
            Step::Condition { condition, steps } => {
                if self.evaluate_condition(condition)? {
                    for step in steps {
                        self.execute_step(step, temp_dir)?;
                    }
                }
            }
            Step::Variable { name, value } => {
                self.variables.insert(name.clone(), value.clone());
            }
            Step::Set { name, value } => {
                self.variables.insert(name.clone(), value.clone());
            }
            Step::Unset { name } => {
                self.variables.remove(name);
            }
            Step::If { condition, steps, else_steps } => {
                if self.evaluate_condition(condition)? {
                    for step in steps {
                        self.execute_step(step, temp_dir)?;
                    }
                } else {
                    for step in else_steps {
                        self.execute_step(step, temp_dir)?;
                    }
                }
            }
            Step::For { variable, values, steps } => {
                for value in values {
                    self.variables.insert(variable.clone(), value.clone());
                    for step in steps {
                        self.execute_step(step, temp_dir)?;
                    }
                }
            }
            Step::Include { file } => {
                let included_steps: Vec<StepWrapper> = serde_json::from_str(&fs::read_to_string(file)?)?;
                for step in included_steps {
                    self.execute_step(&step, temp_dir)?;
                }
            }
            Step::Comment { text: _ } => {
                // Do nothing for comments
            }
            Step::Sleep { duration } => {
                thread::sleep(Duration::from_secs(*duration));
            }
            Step::SetEnv { name, value } => {
                env::set_var(name, value);
            }
            Step::UnsetEnv { name } => {
                env::remove_var(name);
            }
            Step::SetRegistry { key, value } => {
                // Note: This is a simplified version. Real implementation would use Windows API.
                println!("Setting registry key {} to {}", key, value);
            }
            Step::RemoveRegistry { key } => {
                // Note: This is a simplified version. Real implementation would use Windows API.
                println!("Removing registry key {}", key);
            }
            Step::JavaScript { code } => {
                // Using deno for JavaScript execution
                let output = cmd!("deno", "eval", code).read()?;
                println!("JavaScript output: {}", output);
            }
            Step::Shell { script } => {
                let output = if cfg!(target_os = "windows") {
                    cmd!("cmd", "/C", script).read()?
                } else {
                    cmd!("sh", "-c", script).read()?
                };
                println!("Shell script output: {}", output);
            }
        }
        Ok(())
    }

    fn evaluate_condition(&self, condition: &str) -> Result<bool> {
        let re = Regex::new(r"\$\{([^}]+)\}")?;
        let expanded_condition = re.replace_all(condition, |caps: &regex::Captures| {
            self.variables.get(&caps[1]).cloned().unwrap_or_default()
        });
        
        // This is a simplified condition evaluator. In a real-world scenario,
        // you'd want to use a proper expression evaluator.
        Ok(expanded_condition == "true")
    }

    pub fn list(&self) -> Vec<&App> {
        self.installed_apps.values().collect()
    }

    pub fn update(&mut self) -> Result<()> {
        for app in self.clone().installed_apps.values() {
            let latest_version = self.clone().search(&app.name)?
                .into_iter()
                .next()
                .ok_or("App not found in repositories")?;
            
            if latest_version.version != app.version {
                println!("Updating {} from {} to {}", app.name, app.version, latest_version.version);
                self.uninstall(&app.identifier)?;
                self.install(&latest_version.name)?;
            }
        }
        Ok(())
    }

    pub fn add_repo(&mut self, url: &str, description: Option<&str>) -> Result<()> {
        let repo = Repository::new(url, description);
        self.repos.push(repo);
        self.config.repos.push(url.to_string());
        self.config.save()?;
        Ok(())
    }

    pub fn remove_repo(&mut self, url: &str) -> Result<()> {
        self.repos.retain(|r| r.url != url);
        self.config.repos.retain(|r| r != url);
        self.config.save()?;
        Ok(())
    }
}

fn main() -> Result<()> {
    let mut get = Get::new()?;
    
    match std::env::args().nth(1).as_deref() {
        Some("search") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            println!("Searching for {}", app_name);
            match get.search(&app_name) {
                Ok(apps) => {
                    if apps.is_empty() {
                        println!("No applications found matching '{}'", app_name);
                    } else {
                        for app in apps {
                            println!("{} ({}): {}", app.name, app.version, app.description.as_deref().unwrap_or(""));
                        }
                    }
                },
                Err(e) => eprintln!("Error searching for applications: {}", e),
            }
        }
        Some("install") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            println!("Installing {}", app_name);
            match get.install(&app_name) {
                Ok(_) => println!("{} installed successfully", app_name),
                Err(e) => eprintln!("Error installing {}: {}", app_name, e),
            }
        }
        Some("uninstall") => {
            let app_name = std::env::args().nth(2).expect("Provide an app name");
            println!("Uninstalling {}", app_name);
            match get.uninstall(&app_name) {
                Ok(_) => println!("{} uninstalled successfully", app_name),
                Err(e) => eprintln!("Error uninstalling {}: {}", app_name, e),
            }
        }
        Some("list") => {
            println!("Installed applications:");
            for app in get.list() {
                println!("{} ({}): {}", app.name, app.version, app.description.as_deref().unwrap_or(""));
            }
        }
        Some("update") => {
            println!("Updating installed applications");
            match get.update() {
                Ok(_) => println!("Applications updated successfully"),
                Err(e) => eprintln!("Error updating applications: {}", e),
            }
        }
        Some("add") => {
            let repo_url = std::env::args().nth(2).expect("Provide a repo URL");
            println!("Adding repo {}", repo_url);
            match get.add_repo(&repo_url, None) {
                Ok(_) => println!("Repo added successfully"),
                Err(e) => eprintln!("Error adding repo: {}", e),
            }
        }
        Some("remove") => {
            let repo_url = std::env::args().nth(2).expect("Provide a repo URL");
            println!("Removing repo {}", repo_url);
            match get.remove_repo(&repo_url) {
                Ok(_) => println!("Repo removed successfully"),
                Err(e) => eprintln!("Error removing repo: {}", e),
            }
        }
        _ => {
            println!("Usage: get <command>");
            println!("Commands:");
            println!("  search <app-name> - Search for an application");
            println!("  install <app-name> - Install an application");
            println!("  uninstall <app-name> - Uninstall an application");
            println!("  list - List installed applications");
            println!("  update - Update installed applications");
            println!("  add <repo-url> - Add a repository");
            println!("  remove <repo-url> - Remove a repository");
        }
    };

    Ok(())

}
