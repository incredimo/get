// repository.rs
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref REPOSITORY_MANAGER: Arc<Mutex<RepositoryManager>> = Arc::new(Mutex::new(RepositoryManager::new()));
}

pub struct RepositoryManager {
    repositories: HashMap<String, Repository>,
}

impl RepositoryManager {
    pub fn new() -> Self {
        RepositoryManager {
            repositories: HashMap::new(),
        }
    }

    pub async fn add_repository(&mut self, url: &str) {
        let repo = Repository {
            url: url.to_string(),
        };
        self.repositories.insert(url.to_string(), repo);
    }

    pub async fn remove_repository(&mut self, url: &str) {
        self.repositories.remove(url);
    }

    pub async fn list_repositories(&self) -> Vec<Repository> {
        self.repositories.values().cloned().collect()
    }

    pub async fn search_apps(&self, query: &str) -> Vec<App> {
        // Mocked search, replace with actual repository search
        vec![App {
            name: query.to_string(),
            version: "1.0.0".to_string(),
        }]
    }

    pub async fn fetch_app_manifest(&self, app_name: &str) -> Option<App> {
        // Mocked fetch, replace with actual manifest fetching logic
        Some(App {
            name: app_name.to_string(),
            version: "1.0.0".to_string(),
        })
    }
}

#[derive(Clone)]
pub struct Repository {
    pub url: String,
}

#[derive(Clone)]
pub struct App {
    pub name: String,
    pub version: String,
}
