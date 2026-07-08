#!/bin/bash

# Set project base directory
export DEMO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECTS_HOME="$DEMO_HOME/projects"

# SQLcl version selection.
# The system default SQLcl is 26.1, which is not compatible with this demo.
# Override with SQLCL_VERSION=24.4.1 or SQLCL_VERSION=25.4.1 before running scripts.
export SQLCL_VERSION="${SQLCL_VERSION:-25.4.1}"

case "$SQLCL_VERSION" in
  24.4.1)
    export SQLCL_HOME="$DEMO_HOME/tools/sqlcl_24.4.1.042.1221"
    ;;
  25.4.1)
    export SQLCL_HOME="$DEMO_HOME/tools/sqlcl-25.4.1.022.0618"
    ;;
  *)
    echo "ERROR: Unsupported SQLCL_VERSION '$SQLCL_VERSION'. Use 24.4.1 or 25.4.1." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

if [[ ! -x "$SQLCL_HOME/bin/sql" ]]; then
  echo "ERROR: SQLcl executable not found or not executable: $SQLCL_HOME/bin/sql" >&2
  return 1 2>/dev/null || exit 1
fi

export PATH="$SQLCL_HOME/bin:$PATH"
export SQLCL_BIN="$SQLCL_HOME/bin/sql"

# GitHub Configuration (user-specific)
export GITHUB_USER="vmendo"
export GITHUB_REPO="apex_ci_cd_demo"
export GITHUB_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO.git"

export PROJECT_NAME="MyDemo"
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
