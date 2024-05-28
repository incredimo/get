use reqwest::Client;
use serde::Deserialize;

const REPOSITORY_URL: &str = "https://api.github.com/repos/ScoopInstaller/Main/contents/bucket";

#[derive(Deserialize, Debug)]
pub struct Manifest {
    pub name: String,
    pub version: String,
    pub url: String,
    pub bin: Option<String>,
}

pub struct RepositoryManager {
    client: Client,
}

impl RepositoryManager {
    pub fn new() -> Self {
        RepositoryManager {
            client: Client::new(),
        }
    }

    pub async fn fetch_app_manifest(&self, app_name: &str) -> Option<Manifest> {
        let url = format!("{}/{}.json", REPOSITORY_URL, app_name);
        let response = self.client.get(&url).send().await.unwrap();

        if response.status().is_success() {
            let manifest: Manifest = response.json().await.unwrap();
            Some(manifest)
        } else {
            None
        }
    }
}
