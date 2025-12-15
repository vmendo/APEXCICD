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
