
#!/bin/bash

# ===============================
# DELETE PROJECT SCRIPT
# ===============================

set -euo pipefail

# --- Colors ---
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m'

# Helper: ask Yes/No (default = Yes)
ask_yes_default() {
  local prompt="${1:?prompt}"
  local answer=""
  read -r -p "$prompt [Y/n]: " answer || true
  case "${answer:-}" in
    [Yy]|[Yy][Ee][Ss]|"") return 0 ;;
    *) return 1 ;;
  esac
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../setup_env.sh"

DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

# --- Header ---
echo -e "${BLUE}🧹 Deleting project ${PROJECT_NAME}${NC}"

# --- Local folder deletion ---
if ask_yes_default "Do you want to delete the local project folder ${PROJECTS_HOME}/${PROJECT_NAME}?"; then
  if [ -n "${PROJECTS_HOME:-}" ] && [ -n "${PROJECT_NAME:-}" ] && [ -d "${PROJECTS_HOME}/${PROJECT_NAME}" ]; then
    rm -rf "${PROJECTS_HOME:?}/${PROJECT_NAME}"
    echo -e "${GREEN}✅ Local project folder ${PROJECTS_HOME}/${PROJECT_NAME} deleted.${NC}"
  else
    echo -e "${RED}⚠️  Local project folder ${PROJECTS_HOME}/${PROJECT_NAME} does not exist or variables are empty, skipping rm -rf.${NC}"
  fi
else
  echo -e "${BLUE}ℹ️  Skipping local project folder deletion.${NC}"
fi

# --- Remote repository full cleanup ---
if ask_yes_default "Do you want to fully clean the remote repository at ${GITHUB_URL}? (releases, tags, branches, history, artifacts)"; then

  REPO_SLUG="${GITHUB_USER}/${GITHUB_REPO}"

  # Ensure gh is available
  if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}❌ 'gh' command not found. Please install GitHub CLI before running this step.${NC}"
    exit 1
  fi

  # Ensure git is available
  if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}❌ 'git' command not found. Please install Git before running this step.${NC}"
    exit 1
  fi

  echo -e "${BLUE}📦 Deleting all GitHub Releases in ${REPO_SLUG}...${NC}"

  # Delete all GitHub Releases (and their assets)
  RELEASE_TAGS=$(gh release list --repo "$REPO_SLUG" --limit 100 --json tagName -q '.[].tagName' || true)
  if [ -n "${RELEASE_TAGS}" ]; then
    while IFS= read -r tag; do
      [ -z "$tag" ] && continue
      echo -e "${BLUE}  📦 Deleting release: ${tag}${NC}"
      gh release delete "$tag" --repo "$REPO_SLUG" -y || \
        echo -e "${RED}⚠️  Failed to delete release ${tag} (maybe it was already removed).${NC}"
      sleep 1
    done <<< "${RELEASE_TAGS}"
  else
    echo -e "${BLUE}ℹ️  No releases found in remote repository.${NC}"
  fi

  echo -e "${BLUE}🏷️  Deleting all tags in remote repo ${REPO_SLUG}...${NC}"

  # Delete all tags (if any)
  TAGS=$(gh api "repos/${REPO_SLUG}/tags" --jq '.[].name' || true)
  if [ -n "${TAGS}" ]; then
    while IFS= read -r tag; do
      [ -z "$tag" ] && continue
      echo -e "${BLUE}  🏷️  Deleting tag: ${tag}${NC}"
      gh api -X DELETE "repos/${REPO_SLUG}/git/refs/tags/${tag}" || \
        echo -e "${RED}⚠️  Failed to delete tag ${tag} (maybe it was already removed).${NC}"
      sleep 1
    done <<< "${TAGS}"
  else
    echo -e "${BLUE}ℹ️  No tags found (or API returned empty).${NC}"
  fi

  echo -e "${BLUE}🧨 Deleting all GitHub Actions artifacts in ${REPO_SLUG}...${NC}"

  # Delete all GitHub Actions artifacts
  ARTIFACT_IDS=$(gh api -X GET "repos/${REPO_SLUG}/actions/artifacts?per_page=100" --paginate --jq '.artifacts[].id' || true)
  if [ -n "${ARTIFACT_IDS}" ]; then
    while IFS= read -r artifact_id; do
      [ -z "$artifact_id" ] && continue
      echo -e "${BLUE}  🧨 Deleting artifact ID: ${artifact_id}${NC}"
      gh api -X DELETE "repos/${REPO_SLUG}/actions/artifacts/${artifact_id}" || \
        echo -e "${RED}⚠️  Failed to delete artifact ID ${artifact_id} (maybe it was already removed).${NC}"
      sleep 1
    done <<< "${ARTIFACT_IDS}"
  else
    echo -e "${BLUE}ℹ️  No GitHub Actions artifacts found in repository.${NC}"
  fi

  echo -e "${BLUE}🌿 Deleting remote branches (except ${DEFAULT_BRANCH})...${NC}"

  # Delete all remote branches except DEFAULT_BRANCH
  BRANCHES=$(gh api "repos/${REPO_SLUG}/branches" --jq '.[].name' || true)
  if [ -n "${BRANCHES}" ]; then
    while IFS= read -r branch; do
      [ -z "$branch" ] && continue
      if [ "$branch" = "$DEFAULT_BRANCH" ]; then
        echo -e "${BLUE}  ℹ️  Keeping default branch: ${branch}${NC}"
        continue
      fi
      echo -e "${BLUE}  🌿 Deleting branch: ${branch}${NC}"
      gh api -X DELETE "repos/${REPO_SLUG}/git/refs/heads/${branch}" || \
        echo -e "${RED}⚠️  Failed to delete branch ${branch} (maybe it was already removed).${NC}"
      sleep 1
    done <<< "${BRANCHES}"
  else
    echo -e "${BLUE}ℹ️  No branches found (or API returned empty).${NC}"
  fi

  # Reinitialize default branch to empty state
  echo -e "${BLUE}⚙️  Reinitializing ${DEFAULT_BRANCH} branch with an empty commit...${NC}"

  ORIG_DIR="$(pwd)"
  TEMP_DIR="$(mktemp -d)"

  cd "${TEMP_DIR}"
  git init --initial-branch="$DEFAULT_BRANCH"

  echo "# Empty reset on $(date)" > README.md
  git add README.md
  git commit -m "chore: reset repository to empty state"

  git remote add origin "https://github.com/${REPO_SLUG}.git"
  git push -f origin "$DEFAULT_BRANCH"

  cd "${ORIG_DIR}"
  rm -rf "${TEMP_DIR}"

  echo -e "${GREEN}✔ Repo ${GITHUB_URL} is now clean and reset (only ${DEFAULT_BRANCH} branch with README.md).${NC}"
else
  echo -e "${BLUE}ℹ️  Skipping remote repository cleanup.${NC}"
fi


echo -e "${GREEN}🏁 Project ${PROJECT_NAME} deletion process completed.${NC}"
