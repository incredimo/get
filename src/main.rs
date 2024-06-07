mod app;
mod repository;

// get
// get is simple high perfomant and varsatile alternative to scoop
// get is a package manager for windows, macos and linux, it uses scoop compatible repositories
// however it is a complete rewrite of scoop in rust and it is much faster than scoop
// with get you can install, uninstall, update and search for applications from repositories
// main.rs
use crate::app::{AppManager, APP_MANAGER};
use minimo::{divider, showln, ask, async_selection, async_choice, green_bold, red_bold, yellow_bold, gray_dim};
use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;
use tokio::sync::Mutex;

const PR1: &str = "enter the name of the application to search for";
const PR2: &str = "enter the name of the application to install";
const PR3: &str = "enter the name of the application to uninstall";
const PR4: &str = "enter the URL of the repository to add";
const PR5: &str = "enter the URL of the repository to remove";
const PR6: &str = "Select an option";



#[tokio::main]
async fn main() {
    loop {
        divider!();
        let choices = vec![
            async_choice!("list", "List installed applications", list_installed_apps),
            async_choice!("search", "Search for an application", search_app),
            async_choice!("install", "Install a new application", install_app),
            async_choice!("uninstall", "Uninstall an application", uninstall_app),
            async_choice!("update", "Update applications", update_apps),
            async_choice!("add-repo", "Add a new repository", add_repository),
            async_choice!("remove-repo", "Remove a repository", remove_repository),
            async_choice!("list-repos", "List all repositories", list_repositories),
            async_choice!("exit", "Exit the program", || std::process::exit(0)),
        ];

        let choices = Arc::new(Mutex::new(choices));

        async_selection!("Select an option", choices);
    }
}

fn list_installed_apps() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        app_manager.list_installed_apps().await;
    })
}

fn search_app() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        let query = ask::text(PR1).unwrap();
        let apps = app_manager.search_apps(&query).await;
        for app in apps {
            showln!(yellow_bold, app.name, gray_dim, app.version);
        }
    })
}

fn install_app() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        let query = ask::text("Enter the name of the application to install").unwrap();
        let apps = app_manager.search_apps(&query).await;
        if apps.is_empty() {
            showln!(red_bold, "No application found with the name ", gray_dim, query);
            return;
        }
        let app = &apps[0];
        app_manager.install_app(app).await;
        showln!(green_bold, "Application installed successfully");
    })
}

fn uninstall_app() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        let query = ask::text("Enter the name of the application to uninstall").unwrap();
        let apps = app_manager.search_apps(&query).await;
        if apps.is_empty() {
            showln!(red_bold, "No application found with the name ", gray_dim, query);
            return;
        }
        let app = &apps[0];
        app_manager.uninstall_app(app).await;
        showln!(green_bold, "Application uninstalled successfully");
    })
}

fn update_apps() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        app_manager.update_apps().await;
        showln!(green_bold, "Applications updated successfully");
    })
}

fn add_repository() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let mut app_manager = APP_MANAGER.lock().await;
        let url = ask::text("Enter the URL of the repository to add").unwrap();
        app_manager.add_repository(&url).await;
        showln!(green_bold, "Repository added successfully");
    })
}

fn remove_repository() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let mut app_manager = APP_MANAGER.lock().await;
        let url = ask::text("Enter the URL of the repository to remove").unwrap();
        app_manager.remove_repository(&url).await;
        showln!(green_bold, "Repository removed successfully");
    })
}

fn list_repositories() -> Pin<Box<dyn Future<Output = ()> + Send>> {
    Box::pin(async {
        let app_manager = APP_MANAGER.lock().await;
        let repos = app_manager.list_repositories().await;
        for repo in repos {
            showln!(yellow_bold, repo.url);
        }
    })
}
