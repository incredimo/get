use crate::repository::RepositoryManager;
use minimo::{showln, gray, red};
use std::fs;
use std::path::Path;

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

    pub async fn install_app(&self, app_name: &str) {
        let manifest = self.repo_manager.fetch_app_manifest(app_name).await;
        match manifest {
            Some(_) => {
                showln!(red, "Application already installed: ",gray_dim, app_name);
                let app_dir = Path::new("./installed_apps").join(app_name);
                fs::create_dir_all(&app_dir).unwrap();
               showln!(red, "Application installed: ", gray_dim, app_name);
            }
            None =>  {
                showln!(red, "Application not found: ", gray_dim, app_name);
            }
        }
    }
}
