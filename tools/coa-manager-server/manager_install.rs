use coa_core::download::Cancel;
use coa_core::install::{install_base, Params, Source};
use coa_core::registry::Registry;
use coa_core::signing::EMBEDDED_PUBLIC_KEY;
use std::env;
use std::path::PathBuf;

fn main() {
    if let Err(e) = install() {
        eprintln!("CoA Server Manager installation failed: {e}");
        std::process::exit(1);
    }
}

fn install() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<_> = env::args_os().collect();
    if args.len() != 3 {
        return Err("Usage: manager-install.exe <verified-official-package-folder> <destination-CoA-Server>".into());
    }
    let package = PathBuf::from(&args[1]);
    let dest = PathBuf::from(&args[2]);
    if !package.join("manifest.json").is_file()
        || !package.join("manifest.json.sig").is_file()
        || !package.join("base.tar.zst.001").is_file()
    {
        return Err("The official signed CoA Server Manager base package is incomplete.".into());
    }
    let registry_file = dest
        .parent()
        .ok_or("Installation destination has no parent directory")?
        .join(".local-coa-manager-registry.json");
    let registry = Registry::at(registry_file);
    let params = Params {
        source: Source::Dir(package),
        dest: dest.clone(),
        trusted_key: EMBEDDED_PUBLIC_KEY,
        registry: &registry,
        cancel: Cancel::default(),
    };
    println!("Installing through the original CoA Server Manager install_base engine.");
    println!("Installer will verify the signed release, extract all server files, initialize MySQL, and rotate passwords.");
    let installed = install_base(&params, &|step| {
        println!("[{}%] {} {}", step.percent, step.step, step.detail.unwrap_or_default());
    })?;
    println!("Server successfully installed: {}", installed.path);
    println!("Server Manager source version: {}", coa_core::MANAGER_VERSION);
    if !dest.join("Settings/database.json").is_file()
        || !dest.join("Core/worldserver.exe").is_file()
        || !dest.join("Core/authserver.exe").is_file()
        || !dest.join("Runtime/python/python.exe").is_file()
    {
        return Err("CoA Server Manager returned success but expected installed server files are absent.".into());
    }
    Ok(())
}
