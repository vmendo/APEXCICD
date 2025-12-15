# Oracle APEX CI/CD Demo (SQLcl Projects + GitHub)

This repository contains a complete working example of a CI/CD workflow for Oracle APEX and database objects using **SQLcl Projects**, **Git**, and **GitHub**.  
The demo automates the extraction of schema objects, APEX applications, and metadata into a structured, version-controlled SQLcl project.

---

## 🚀 Prerequisites

Before using this demo, make sure the following tools are installed:

### ✔ 1. SQLcl (latest version)
Install the latest SQLcl release from Oracle.

SQLcl requires:
- **Java 12+** (current releases also support **Java 21**)

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

This demo uses the following script (`setup_env.sh`) to configure all required environment variables:

```bash
#!/bin/bash

# Set project base directory
export DEMO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECTS_HOME="$DEMO_HOME/projects"

# GitHub Configuration (user-specific)
export GITHUB_USER="vmendo"
export GITHUB_REPO="apex_ci_cd_demo"
export GITHUB_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO.git"

export PROJECT_NAME="NIVA"
export SCHEMA_NAME="WKSP_DEMO"

export DB_CONNECT_DEV="apex_dev"
export DB_CONNECT_PRO="apex_pro"

# APEX apps to override (space separated)
export APEX_APP_IDS="115"
export DB_OBJECTS_FILTER="EBA_DEMO%"

# Target workspace name for this artifact (e.g. UAT workspace)
export APEX_WORKSPACE_NAME_TARGET="DEMO"

# Ensure PROJECTS_HOME exists
if [[ ! -d "$PROJECTS_HOME" ]]; then
  echo "📁 Creating base projects directory: $PROJECTS_HOME"
  mkdir -p "$PROJECTS_HOME"
fi
```

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

## 📚 Documentation

- SQLcl Projects  
  https://docs.oracle.com/en/database/oracle/sql-developer-command-line/sqlcl/sqlcl-projects.html  

---

## 📝 License

This project is provided for educational and demonstration purposes.
