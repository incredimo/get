// app.rs
use crate::repository::{RepositoryManager, App};
use minimo::{showln, gray, red};
use std::fs;
use std::path::Path;
use lazy_static::lazy_static;
use std::sync::Arc;

lazy_static! {
    pub static ref APP_MANAGER: Arc<tokio::sync::Mutex<AppManager>> = Arc::new(tokio::sync::Mutex::new(AppManager::new(RepositoryManager::new())));
}

pub struct AppManager {
    repo_manager: RepositoryManager,
}

impl AppManager {
    pub fn new(repo_manager: RepositoryManager) -> Self {
        AppManager { repo_manager }
    }

    pub async fn list_installed_apps(&self) {
        let apps_dir = Path::new("./installed_apps");
        if apps_dir.exists() {
            for entry in fs::read_dir(apps_dir).unwrap() {
                let entry = entry.unwrap();
                let path = entry.path();
                if path.is_dir() {
                    showln!(gray, path.file_name().unwrap().to_str().unwrap());
                }
            }
        } else {
            showln!(red, "No applications installed.");
        }
    }

    pub async fn search_apps(&self, query: &str) -> Vec<App> {
        self.repo_manager.search_apps(query).await
    }

    pub async fn install_app(&self, app: &App) {
        let app_dir = Path::new("./installed_apps").join(&app.name);
        fs::create_dir_all(&app_dir).unwrap();
        showln!(gray_dim,"Application installed",yellow_bold, &app.name);
    }

    pub async fn uninstall_app(&self, app: &App) {
        let app_dir = Path::new("./installed_apps").join(&app.name);
        if app_dir.exists() {
            fs::remove_dir_all(&app_dir).unwrap();
            showln!(gray_dim, "Application uninstalled", yellow_bold, &app.name);
        } else {
            showln!(red, "Application not installed");
        }
    }

    pub async fn update_apps(&self) {
        let apps_dir = Path::new("./installed_apps");
        if apps_dir.exists() {
            for entry in fs::read_dir(apps_dir).unwrap() {
                let entry = entry.unwrap();
                let path = entry.path();
                if path.is_dir() {
                    let app_name = path.file_name().unwrap().to_str().unwrap();
                    let app = self.repo_manager.fetch_app_manifest(app_name).await.unwrap();
                    self.install_app(&app).await;
                }
            }
        } else {
            showln!(red, "No applications installed.");
        }
    }

    pub async fn add_repository(&mut self, url: &str) {
        self.repo_manager.add_repository(url).await;
    }

    pub async fn remove_repository(&mut self, url: &str) {
        self.repo_manager.remove_repository(url).await;
    }

    pub async fn list_repositories(&self) -> Vec<crate::repository::Repository> {
        self.repo_manager.list_repositories().await
    }
}
