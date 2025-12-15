#!/bin/bash

# =========================================
# CREATE RELEASE SCRIPT (argument-based)
# Usage:
#   create_release.sh <release_name> <version>
# Example:
#   create_release.sh base_release 1.0
# =========================================

set -euo pipefail

# --- Colors ---
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m'

# Load environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup_env.sh"


# -----------------------------------------
# 0) Parse arguments
# -----------------------------------------
if [ $# -ne 2 ]; then
  echo -e "${RED}Usage: $0 <release_name> <version>${NC}"
  echo -e "${RED}Example: $0 base_release 1.0${NC}"
  exit 1
fi

RELEASE_NAME="$1"
RELEASE_VERSION="$2"

RELEASE_BRANCH="${RELEASE_NAME// /_}"   # Replace spaces if any
RELEASE_BRANCH="release_${RELEASE_BRANCH}_${RELEASE_VERSION}"

echo ""
echo -e "${BLUE}🚀 Starting release process${NC}"
echo -e "${BLUE}🔹 Release name:   $RELEASE_NAME${NC}"
echo -e "${BLUE}🔹 Release version: $RELEASE_VERSION${NC}"
echo -e "${BLUE}🔹 Release branch:  $RELEASE_BRANCH${NC}"
echo ""

# Base dirs
PROJECT_DIR="$PROJECTS_HOME/$PROJECT_NAME"

# -----------------------------------------
# 1) Validations
# -----------------------------------------
command -v sql >/dev/null 2>&1 || { echo -e "${RED}SQLcl not found in PATH${NC}"; exit 1; }
command -v git >/dev/null 2>&1 || { echo -e "${RED}git not found in PATH${NC}"; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo -e "${RED}gh CLI not found in PATH${NC}"; exit 1; }

cd "$PROJECT_DIR"

if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo -e "${RED}No Git repository found in $PROJECT_DIR${NC}"
  exit 1
fi

command -v gh  >/dev/null 2>&1 || { echo -e "${RED}gh CLI not found in PATH${NC}"; exit 1; }

if ! gh auth status >/dev/null 2>&1; then
  echo -e "${RED}❌ GitHub CLI (gh) is not authenticated in this environment.${NC}"
  echo -e "${BLUE}   Run: ${NC}gh auth login${BLUE}${NC}"
  exit 1
fi


# DB connection from setup_env.sh
DB_CONNECT_DEV="${DB_CONNECT_DEV:?DB_CONNECT_DEV must be defined in setup_env.sh}"

# -----------------------------------------
# 2) Update VERSION file
# -----------------------------------------
cd "$PROJECT_DIR"
echo "$RELEASE_VERSION" > VERSION
echo -e "${GREEN}✔ VERSION file updated: $RELEASE_VERSION${NC}"

# -----------------------------------------
# 3) Ensure main is up-to-date
# -----------------------------------------

git checkout main
git pull --ff-only

# -----------------------------------------
# 4) Create release branch
# -----------------------------------------
if git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
  echo -e "${RED}Branch $RELEASE_BRANCH already exists.${NC}"
  exit 1
fi

git checkout -b "$RELEASE_BRANCH"
echo -e "${GREEN}✔ Created branch: $RELEASE_BRANCH${NC}"

# -----------------------------------------
# 5) Run SQLcl project commands
# -----------------------------------------
cd "$PROJECT_DIR"

echo -e "${BLUE}⚙ Running SQLcl project export/stage/release${NC}"


sql -name "$DB_CONNECT_DEV" <<EOF
project export
!git add src
!git commit -m "feat: committing database and APEX application sources to the src folder"
project stage
exit
EOF


echo ""
echo -e "${BLUE}🧩 Review staged changelogs under dist/releases/$RELEASE_VERSION/...${NC}"
read -p "Press Enter to continue with project release, or Ctrl+C to abort... " -r
echo ""

sql -name "$DB_CONNECT_DEV" <<EOF
project release -version $RELEASE_VERSION
exit
EOF

# -----------------------------------------
# Patch dist/install.sql to include -defaults-file
# -----------------------------------------

# INSTALL_SQL="$PROJECT_DIR/dist/install.sql"

# if [ -f "$INSTALL_SQL" ]; then
  # if grep -q "defaults-file" "$INSTALL_SQL"; then
    # echo -e "${BLUE}ℹ️ dist/install.sql already contains -defaults-file option. Skipping patch.${NC}"
  # else
    # echo -e "${BLUE}🔧 Patching dist/install.sql to add -defaults-file...${NC}"
    # sed -i 's/lb update /lb update -defaults-file=env\/defaults.properties /' "$INSTALL_SQL"
    # echo -e "${GREEN}✔ Updated dist/install.sql to use env/defaults.properties.${NC}"
  # fi
# else
  # echo -e "${YELLOW}⚠ dist/install.sql not found. Skipping defaults-file patch.${NC}"
# fi

git add dist
git commit -m "feat: committing changelogs in the dist folder for release $RELEASE_VERSION"
tree 

echo -e "${GREEN}✔ SQLcl project release completed${NC}"
tree

# -----------------------------------------
# 6) Commit and push
# -----------------------------------------
cd "$PROJECT_DIR"
git add .
git commit -m "chore: release $RELEASE_VERSION ($RELEASE_NAME)"
git push -u origin "$RELEASE_BRANCH" --force-with-lease

echo -e "${GREEN}✔ Pushed branch to remote${NC}"

# -----------------------------------------
# 7) Create Pull Request
# -----------------------------------------

PR_TITLE="Release $RELEASE_VERSION - $RELEASE_NAME"
PR_BODY="Automated release branch for version $RELEASE_VERSION."

PR_URL=$(gh pr create \
  --base main \
  --head "$RELEASE_BRANCH" \
  --title "$PR_TITLE" \
  --body "$PR_BODY"
  )

PR_NUMBER=$(gh pr list --head "$RELEASE_BRANCH" --json number --jq '.[0].number')

echo -e "${GREEN}✔ PR created: $PR_URL${NC}"
echo -e "${BLUE}PR Number: $PR_NUMBER${NC}"

echo -e "${BLUE}⏳ Waiting for PR to be merged or closed...${NC}"

# -----------------------------------------
# 8) Wait for PR result
# -----------------------------------------
while true; do
  STATE=$(gh pr view "$PR_NUMBER" --json state   -q .state)

  if [[ "$STATE" == "MERGED" ]]; then
    echo -e "${GREEN}✔ PR merged${NC}"
    PR_RESULT="MERGED"
    break
  elif [[ "$STATE" == "CLOSED" ]]; then
    PR_RESULT="REJECTED"
    break
  fi

  echo "Checking again..."
  sleep 10
done

# -----------------------------------------
# 9) Actions depending on PR result
# -----------------------------------------
if [ "$PR_RESULT" = "MERGED" ]; then

    echo -e "${RED}✅ Pull request #$PR_NUMBER has been merged!${NC}"
    echo ""
    echo -e "${BLUE}📦 Creating the artifact for deployment.${NC}"
    echo -e "${RED}    sql -name $DB_CONNECT_DEV ${NC}"
    echo -e "${RED}    project gen-artifact -name $PROJECT_NAME -version $RELEASE_VERSION -format zip -verbose${NC}"
    echo ""
    
    sql -name "$DB_CONNECT_DEV" <<EOF
project gen-artifact -name $PROJECT_NAME -version $RELEASE_VERSION -format zip -verbose
exit
EOF
    echo -e "${BLUE}🚀 Uploading the artifact into GitHub Release Asset...${NC}"
    echo -e "${GREEN}    gh release create v$RELEASE_VERSION artifact/$PROJECT_NAME-$RELEASE_VERSION.zip --title '$RELEASE_BRANCH Version $RELEASE_VERSION' --notes '$RELEASE_BRANCH changes included in this artifact.'${NC}"
    gh release create v$RELEASE_VERSION artifact/$PROJECT_NAME-$RELEASE_VERSION.zip --title "$RELEASE_BRANCH Version $RELEASE_VERSION" --notes "$RELEASE_BRANCH changes included in this artifact."

    echo -e "${BLUE}🧹 Cleaning merged release branch${NC}"
    git checkout main
    git pull --ff-only
    git branch -d "$RELEASE_BRANCH" 2>/dev/null || git branch -D "$RELEASE_BRANCH"
    git push origin --delete "$RELEASE_BRANCH" 2>/dev/null || true
    echo -e "${GREEN}✔ Branch $RELEASE_BRANCH deleted (local and remote)${NC}"
    
else
  echo -e "${BLUE}🧹 Cleaning rejected release branch${NC}"
  git checkout main
  git branch -D "$RELEASE_BRANCH" 2>/dev/null || true
  git push origin --delete "$RELEASE_BRANCH" 2>/dev/null || true
  echo -e "${GREEN}✔ Branch cleaned (local + remote)${NC}"
fi

echo ""
echo -e "${GREEN}🏁 Release $RELEASE_VERSION complete (PR result: $PR_RESULT)${NC}"
