#!/bin/bash

# ===============================
# CREATE PROJECT SCRIPT
# ===============================

set -euo pipefail

# --- Colors ---
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m'

# Resolve script directory and load environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup_env.sh"

echo ""
echo -e "${BLUE}📁 This script will:${NC}"
echo -e "${BLUE}📁   Initialize the project folder: $PROJECTS_HOME/$PROJECT_NAME${NC}"
echo -e "${BLUE}📁   Create a SQLcl Project (project init) for schema: $SCHEMA_NAME${NC}"
echo -e "${BLUE}📁   Generate a README.md for the project${NC}"
echo -e "${BLUE}📁   Initialize (or reuse) the local Git repo in: $PROJECTS_HOME${NC}"
echo -e "${BLUE}📁   Sync the local project with the remote repository: $GITHUB_URL${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1) Check if the project folder already exists
# ---------------------------------------------------------------------------
if [ -d "$PROJECTS_HOME/$PROJECT_NAME" ]; then
    echo -e "${RED}ERROR: The folder $PROJECTS_HOME/$PROJECT_NAME already exists!${NC}"
    echo -e "${RED}Please remove it manually and run the script again.${NC}"
    echo -e "${RED}Or edit setup_env.sh to change PROJECT_NAME (and remote repository) for a new project.${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2) Move to PROJECTS_HOME and init SQLcl project
# ---------------------------------------------------------------------------
echo -e "${BLUE}📁 Moving to the project directory: $PROJECTS_HOME${NC}"
cd "$PROJECTS_HOME" || {
  echo -e "${RED}ERROR: Cannot cd to $PROJECTS_HOME${NC}"
  exit 1
}

echo ""
echo -e "${BLUE}⚙️  Initializing SQLcl Project...${NC}"
echo -e "${GREEN}sql /nolog${NC}"
echo -e "${RED}project init -name $PROJECT_NAME -schemas $SCHEMA_NAME -makeroot${NC}"
echo ""

sql /nolog <<EOF
project init -name $PROJECT_NAME -schemas $SCHEMA_NAME -makeroot
exit
EOF

# ---------------------------------------------------------------------------
# Setting emitSchema=false into SQLcl-generated project.config.json
# ---------------------------------------------------------------------------

CONFIG_FILE="$PROJECTS_HOME/$PROJECT_NAME/.dbtools/project.config.json"

echo -e "${BLUE}🔧 Updating SQLcl project configuration${NC}"

# Set emitSchema to false
sed -i 's/"emitSchema" *: *true/"emitSchema" : false/' "$CONFIG_FILE"

echo -e "${GREEN}✔ Updated emitSchema=false in project.config.json${NC}"

# ---------------------------------------------------------------------------
# Add custom filters to SQLcl-generated project.filters
# ---------------------------------------------------------------------------
FILTERS_FILE="$PROJECTS_HOME/$PROJECT_NAME/.dbtools/filters/project.filters"

echo -e "${BLUE}🧩 Adding custom filters to project.filters...${NC}"

cat >> "$FILTERS_FILE" <<EOF

-- Custom rule: Exclude SYS → schema object grants
not (export_type = 'ALL_TAB_PRIVS' and grantor = 'SYS'),
EOF

echo -e "${GREEN}✅ Custom rule added to $FILTERS_FILE${NC}"

# ---------------------------------------------------------------------------
# Add filter to work only with the Database Objects based on DB_OBJECTS_FILTER
# ---------------------------------------------------------------------------

if [ -z "${DB_OBJECTS_FILTER:-}" ]; then
  echo -e "${BLUE}ℹ️  DB_OBJECTS_FILTER is not set. Skipping object_name filters.${NC}"
else
  OBJECT_PREDICATE=""

  for pattern in $DB_OBJECTS_FILTER; do
    [ -z "$pattern" ] && continue
    if [ -z "$OBJECT_PREDICATE" ]; then
      OBJECT_PREDICATE="object_name like '${pattern}'"
    else
      OBJECT_PREDICATE="${OBJECT_PREDICATE} or object_name like '${pattern}'"
    fi
  done

  if [ -n "$OBJECT_PREDICATE" ]; then
    {
      echo ""
      echo "-- Project objects filter from DB_OBJECTS_FILTER"
      echo "(${OBJECT_PREDICATE}),"
    } >> "$FILTERS_FILE"

    echo -e "${GREEN}✅ Added object_name filter from DB_OBJECTS_FILTER='${DB_OBJECTS_FILTER}' to ${FILTERS_FILE}.${NC}"
  else
    echo -e "${BLUE}ℹ️  DB_OBJECTS_FILTER had no valid patterns after parsing. Skipping object_name filters.${NC}"
  fi
fi

# ---------------------------------------------------------------------------
# Append APEX application filters (using APEX_APP_IDS) to the same FILTERS_FILE
# ---------------------------------------------------------------------------
if [ -z "${APEX_APP_IDS:-}" ]; then
  echo -e "${BLUE}ℹ️  APEX_APP_IDS is not set. Skipping APEX application filters in project.filters.${NC}"
else
  {
    echo ""
    echo "-- Project applications only"
    for app_id in $APEX_APP_IDS; do
      [ -z "$app_id" ] && continue
      echo "application_id = ${app_id},"
    done
  } >> "$FILTERS_FILE"

  echo -e "${GREEN}✅ Added APEX application filters to ${FILTERS_FILE} using APEX_APP_IDS='${APEX_APP_IDS}'.${NC}"
fi

# -----------------------------------------
# 3) Generate APEX defaults.properties for workspace/appId overrides
# -----------------------------------------
# echo -e "${BLUE}🧩 Generating APEX defaults.properties for this release...${NC}"

# PROJECT_DIR="$PROJECTS_HOME/$PROJECT_NAME"
# ENV_DIR="$PROJECT_DIR/dist/env"
# DEFAULTS_FILE="$ENV_DIR/defaults.properties"

# mkdir -p "$ENV_DIR"
# : > "$DEFAULTS_FILE"   # truncate or create

# if [ -z "${APEX_APP_IDS:-}" ] || [ -z "${APEX_WORKSPACE_NAME_TARGET:-}" ]; then
#   echo -e "${YELLOW}⚠ APEX_APP_IDS or APEX_WORKSPACE_NAME_TARGET not set in setup_env.sh.${NC}"
#   echo -e "${YELLOW}  Skipping defaults.properties generation.${NC}"
# else
  # for APP_ID in $APEX_APP_IDS; do
    # {
      # echo "# Overrides for APEX application $APP_ID"
      # echo "parameter.apex.${APP_ID}.workspace = ${APEX_WORKSPACE_NAME_TARGET}"
      # echo "parameter.apex.${APP_ID}.appId     = ${APP_ID}"
      # echo
    # } >> "$DEFAULTS_FILE"
  # done
  # echo -e "${GREEN}✔ Created $DEFAULTS_FILE with APEX overrides.${NC}"
# fi


# ---------------------------------------------------------------------------
# 4) Generate README.md inside the project folder
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLUE}📄 Creating README.md for the project...${NC}"

cat > "$PROJECTS_HOME/$PROJECT_NAME/README.md" <<EOF
# $PROJECT_NAME

Database CI/CD project using SQLcl Projects and release artifacts compatible with automated deployments.

## �� Project Structure

- db/ — SQLcl project source (exported objects)
- db/properties/project.properties — SQLcl project settings
- .dbtools/filters/project.filters — object filters for export/stage/release
- dist/releases/ — generated release artifacts (versioned)
- includes/ — SQL source files included in releases

## 🔧 Requirements

- SQLcl 25.3+ (with project commands enabled)
- Java 17+
- Oracle Database (ATP/ADB or On-Prem)
- Git and GitHub CLI (gh) for repository management

## 🔑 Environment Variables (from setup_env.sh)

- PROJECT_NAME="$PROJECT_NAME"
- PROJECTS_HOME="$PROJECTS_HOME"
- SCHEMA_NAME="$SCHEMA_NAME"
- GITHUB_URL="$GITHUB_URL"

## 📝 Filters

You can customize which objects are included in the project by editing:

- $PROJECT_NAME/.dbtools/filters/project.filters

EOF

echo -e "${GREEN}✅ README.md created at $PROJECTS_HOME/$PROJECT_NAME/README.md${NC}"

# ---------------------------------------------------------------------------
# 5) Ask user to review filters / project setup
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLUE}📝 Edit the file to customize your filters:${NC}"
echo -e "${BLUE}📝   $PROJECTS_HOME/$PROJECT_NAME/.dbtools/filters/project.filters${NC}"
echo -e "${BLUE}📝 Review your project setup, apply any changes and press any key to continue.${NC}"
echo ""
read -p "Press any key to continue when your project setup is ready..." -n 1 -s
echo ""
echo ""

# ---------------------------------------------------------------------------
# 6) Git configuration (init / remote / commit / push)
# ---------------------------------------------------------------------------
echo -e "${BLUE}🔧 Configuring Git repository...${NC}"

cd $PROJECTS_HOME/$PROJECT_NAME

# 6.1 Initialize Git only if this is NOT already a Git repo
if [ ! -d ".git" ]; then
    echo -e "${GREEN}🔨 Initializing new Git repository (branch: main)...${NC}"
    git init --initial-branch=main
else
    echo -e "${GREEN}ℹ️  Git repository already exists in $PROJECTS_HOME — skipping git init.${NC}"
fi

# 6.2 Configure remote 'origin' only if it does not exist
if ! git remote | grep -q "^origin$"; then
    echo -e "${GREEN}🔗 Adding remote 'origin': $GITHUB_URL${NC}"
    git remote add origin "$GITHUB_URL"
else
    echo -e "${GREEN}ℹ️  Remote 'origin' already exists — skipping remote add.${NC}"
fi

# 6.3 Stage and commit changes (if any)
echo -e "${GREEN}📝 Committing project files...${NC}"
git add .
if git commit -m "chore: initializing repository with default project files" 2>/dev/null; then
    echo -e "${GREEN}✅ Commit created.${NC}"
else
    echo -e "${GREEN}ℹ️  Nothing to commit — working tree is clean.${NC}"
fi

# 6.4 Push to remote main branch (force to ensure sync with remote)
echo -e "${GREEN}📤 Pushing to remote 'main' branch...${NC}"
git push -u origin main --force

echo ""
echo -e "${BLUE}🏁 Your database project '$PROJECT_NAME' has been created and synced with:${NC}"
echo -e "${BLUE}   $GITHUB_URL${NC}"
echo ""
