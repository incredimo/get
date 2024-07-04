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
use std::path::Path;
use std::fs;
use std::io::Write;
use std::io::Read;
use std::io::Error;



pub type Result<T> = std::result::Result<T, Error>;
pub type Error = Box<dyn std::error::Error + Send + Sync>;

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub repos: Vec<String>,
}

impl Config {
    pub fn new() -> Self {
        Config { repos: vec![] }
    }

    pub fn load() -> Result<Self> {
        let path = Path::new("config.toml");
        if !path.exists() {
            let mut file = fs::File::create(path)?;
            let config = Config::new();
            let toml = toml::to_string(&config)?;
            file.write_all(toml.as_bytes())?;
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

#[derive(Debug, Serialize, Deserialize)]
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

#[derive(Debug, Serialize, Deserialize)]
pub struct App {
    pub identifier: String, // unique identifier for the app e.g. "git" => "Microsoft/git"
    pub name: String, // display name of the app e.g. "git"
    pub description: Option<String>, // description of the app e.g. "distributed version control system"
    // since an app can have multiple versions, made for different platforms, architectures with different editions and so on
    // we need to have a way to uniquely identify an installation with all these variables in mind
    // so we have a unique identifier for each installation
    
}