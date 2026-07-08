# Oracle APEX CI/CD Demo (SQLcl Projects + GitHub)

This repository contains a complete working example of a CI/CD workflow for Oracle APEX and database objects using **SQLcl Projects**, **Git**, and **GitHub**.  
The demo automates the extraction of schema objects, APEX applications, and metadata into a structured, version-controlled SQLcl project.

---

## 🚀 Prerequisites

Before using this demo, make sure the following tools are installed:

### ✔ 1. SQLcl supported version

Do not use the system default SQLcl `26.1` for this demo.

The demo relies on SQLcl Projects behavior that is compatible with the
pre-APEXLang SQLcl releases included in this repository under `tools/`.
SQLcl `26.1` includes APEXLang-related changes that currently break this demo
workflow.

The supported SQLcl versions are:

| Version | Location |
|---------|----------|
| `25.4.1` | `tools/sqlcl-25.4.1.022.0618/bin/sql` |
| `24.4.1` | `tools/sqlcl_24.4.1.042.1221/bin/sql` |

By default, `run/setup_env.sh` prepends SQLcl `25.4.1` to `PATH`, so all demo
scripts call the bundled SQLcl instead of the system `sql` executable.

To force SQLcl `24.4.1`, set `SQLCL_VERSION` when running any script:

```bash
SQLCL_VERSION=24.4.1 ./run/create_project.sh
SQLCL_VERSION=24.4.1 ./run/create_release.sh base_release 1.0
```

To use the default SQLcl `25.4.1`, run the scripts normally:

```bash
./run/create_project.sh
```

SQLcl requires:
- **Java 17 or Java 21**

Documentation:  
https://docs.oracle.com/en/database/oracle/sql-developer-command-line/

---

### ✔ 2. Git + GitHub CLI (gh)

- Git: https://git-scm.com/downloads  
- GitHub CLI: https://cli.github.com/

---

### ✔ 3. Authenticate with GitHub

Run:

```bash
gh auth login
```

Follow the prompts to authenticate via browser or token.

---

## ⚙️ Environment Setup

This demo uses script [`run/setup_env.sh`](run/setup_env.sh) to configure all required environment variables:

You must edit this file before run the demo and set the values for your demo environment. 

---

## 🧩 Configuration Details

### 🔹 GitHub Configuration

These variables must be adapted by the user running the demo:

| Variable | Description |
|----------|-------------|
| `GITHUB_USER` | GitHub username where the SQLcl project will be pushed |
| `GITHUB_REPO` | Repository name for project artifacts |
| `GITHUB_URL` | Complete HTTPS URL constructed automatically |

---

### 🔹 SQLcl Connections

| Variable | Purpose |
|----------|---------|
| `DB_CONNECT_DEV` | Saved SQLcl connection to the development database (source) |
| `DB_CONNECT_PRO` | Saved SQLcl connection to the production database (target) |

These refer to SQLcl **saved connections**.

Documentation:  
https://docs.oracle.com/en/database/oracle/sql-developer-command-line/sqlcl/using-saved-connections.html#GUID-0A4C4C16-ED1C-4AFD-A4B4-1674D28D1DF3

---

### 🔹 Project and Schema

| Variable | Purpose |
|----------|---------|
| `PROJECT_NAME` | Name of the project created in `projects/` |
| `SCHEMA_NAME` | Schema from which DDL and metadata will be extracted |

---

### 🔹 Object Filters

| Variable | Description |
|----------|-------------|
| `APEX_APP_IDS` | APEX application(s) to export |
| `DB_OBJECTS_FILTER` | Restricts exported database objects using LIKE patterns |

---

### 🔹 Workspace Target

APEX_WORKSPACE_NAME_TARGET


Currently unused because DEV and PRO workspaces share the same name.

---

## ▶️ How to Use

### 1. Generate the SQLcl project


./run/create_project.sh


### 2. Build a release package


./run/create_release.sh


### 3. Deploy to another environment (DEV → PRO)


./run/deploy_project.sh


---

## 🧹 Reset the Demo

Use `run/clean_demo.sh` to reset the full demo environment.

```bash
./run/clean_demo.sh
```

The script runs the cleanup steps in this order:

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `run/clean/delete_project.sh` | Deletes the generated SQLcl project folder and optionally cleans the GitHub repository |
| 2 | `run/clean/cleanup_dev.sh` | Cleans custom demo objects from the DEV database |
| 3 | `run/clean/cleanup_pro.sh` | Drops demo objects from the PRO database |

The reset scripts load `run/setup_env.sh`, so they use the same project name,
GitHub repository, SQLcl version, and saved SQLcl connections configured for the
demo.

You can also run each cleanup step individually:

```bash
./run/clean/delete_project.sh
./run/clean/cleanup_dev.sh
./run/clean/cleanup_pro.sh
```

Warning: these scripts are destructive. Review `run/setup_env.sh` before
running them, especially `PROJECT_NAME`, `GITHUB_USER`, `GITHUB_REPO`,
`DB_CONNECT_DEV`, and `DB_CONNECT_PRO`.

---

## 📚 Documentation

- SQLcl Projects  
  https://docs.oracle.com/en/database/oracle/sql-developer-command-line/sqlcl/sqlcl-projects.html  

---

## 📝 License

This project is provided for educational and demonstration purposes.
