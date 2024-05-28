mod app;
mod repository;

use crate::app::{AppManager, APP_MANAGER};
use minimo::{divider, showln, cyan, red, selection, choice};
use std::sync::Arc;
use tokio::sync::Mutex;
use minimo::Choice;
#[tokio::main]
async fn main() {
    loop {
        divider!();
        let choices = vec![
            choice!("list", "List installed applications", list_installed_apps),
            choice!("search", "Search for an application", search_app),
            choice!("install", "Install a new application", install_app),
            choice!("uninstall", "Uninstall an application", uninstall_app),
            choice!("update", "Update applications", update_apps),
            choice!("add-repo", "Add a new repository", add_repository),
            choice!("remove-repo", "Remove a repository", remove_repository),
            choice!("list-repos", "List all repositories", list_repositories),
            choice!("exit", "Exit the program", || std::process::exit(0)),
        ];

        selection!("Select an option", &choices);
    }
}

async fn list_installed_apps() {
    APP_MANAGER.lock().await.list_installed_apps().await;
}

async fn search_app() {
    print!("Enter the name of the application to search: ");
    let mut app_name = String::new();
    std::io::stdin().read_line(&mut app_name).unwrap();
    let app_name = app_name.trim();
    APP_MANAGER.lock().await.search_app(app_name).await;
}

async fn install_app() {
    print!("Enter the name of the application to install: ");
    let mut app_name = String::new();
    std::io::stdin().read_line(&mut app_name).unwrap();
    let app_name = app_name.trim();
    APP_MANAGER.lock().await.install_app(app_name).await;
}

async fn uninstall_app() {
    print!("Enter the name of the application to uninstall: ");
    let mut app_name = String::new();
    std::io::stdin().read_line(&mut app_name).unwrap();
    let app_name = app_name.trim();
    APP_MANAGER.lock().await.uninstall_app(app_name).await;
}

async fn update_apps() {
    APP_MANAGER.lock().await.update_apps().await;
}

async fn add_repository() {
    print!("Enter the name of the repository to add: ");
    let mut repo_name = String::new();
    std::io::stdin().read_line(&mut repo_name).unwrap();
    let repo_name = repo_name.trim();
    APP_MANAGER.lock().await.add_repository(repo_name).await;
}

async fn remove_repository() {
    print!("Enter the name of the repository to remove: ");
    let mut repo_name = String::new();
    std::io::stdin().read_line(&mut repo_name).unwrap();
    let repo_name = repo_name.trim();
    APP_MANAGER.lock().await.remove_repository(repo_name).await;
}

async fn list_repositories() {
    APP_MANAGER.lock().await.list_repositories().await;
}
