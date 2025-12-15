#!/bin/bash

# =========================================
# DEPLOY PROJECT SCRIPT (argument-based)
# Usage:
#   deploy_project.sh <environment> <release_version>
# Examples:
#   deploy_project.sh UAT 1.0
#   deploy_project.sh PRO 1.0
# =========================================

set -euo pipefail

# --- Colors ---
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
YELLOW='\033[33m'
NC='\033[0m'

# Load environment variables
# Expected in setup_env.sh:
#   PROJECTS_HOME, PROJECT_NAME
#   GITHUB_USER, GITHUB_REPO
#   DB_CONNECT_UAT, DB_CONNECT_PRO
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup_env.sh"

# -----------------------------------------
# 0) Parse and validate arguments
# -----------------------------------------
if [ $# -ne 2 ]; then
  echo -e "${RED}Usage: $0 <environment> <release_version>${NC}"
  echo -e "${RED}Examples: $0 UAT 1.0  |  $0 PRO 1.0${NC}"
  exit 1
fi

ENVIRONMENT_RAW="$1"
RELEASE_VERSION="$2"

# Normalize environment to upper case
ENVIRONMENT="$(echo "$ENVIRONMENT_RAW" | tr '[:lower:]' '[:upper:]')"

case "$ENVIRONMENT" in
  UAT)
    DB_CONNECT="${DB_CONNECT_UAT:?DB_CONNECT_UAT must be defined in setup_env.sh}"
    ;;
  PRO)
    DB_CONNECT="${DB_CONNECT_PRO:?DB_CONNECT_PRO must be defined in setup_env.sh}"
    ;;
  *)
    echo -e "${RED}Invalid environment: ${ENVIRONMENT_RAW}${NC}"
    echo -e "${RED}Valid values are: UAT or PRO${NC}"
    exit 1
    ;;
esac

# -----------------------------------------
# 1) Basic validations (tools and variables)
# -----------------------------------------
command -v sql >/dev/null 2>&1 || { echo -e "${RED}SQLcl (sql) not found in PATH${NC}"; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo -e "${RED}GitHub CLI (gh) not found in PATH${NC}"; exit 1; }

: "${PROJECTS_HOME:?PROJECTS_HOME must be defined in setup_env.sh}"
: "${PROJECT_NAME:?PROJECT_NAME must be defined in setup_env.sh}"
: "${GITHUB_USER:?GITHUB_USER must be defined in setup_env.sh}"
: "${GITHUB_REPO:?GITHUB_REPO must be defined in setup_env.sh}"

FULL_REPO="${GITHUB_USER}/${GITHUB_REPO}"
TAG="v${RELEASE_VERSION}"
ASSET_NAME="${PROJECT_NAME}-${RELEASE_VERSION}.zip"

# -----------------------------------------
# 2) Directory layout for artifacts
# -----------------------------------------
PROJECT_BASE_DIR="${PROJECTS_HOME}/${PROJECT_NAME}"
ARTIFACT_DIR="${PROJECT_BASE_DIR}/artifacts"
ARTIFACT_PATH="${ARTIFACT_DIR}/${ASSET_NAME}"

mkdir -p "${ARTIFACT_DIR}"

echo ""
echo -e "${BLUE}🚀 Starting deployment${NC}"
echo -e "${BLUE}🔹 Environment:      ${ENVIRONMENT}${NC}"
echo -e "${BLUE}🔹 Release version:   ${RELEASE_VERSION}${NC}"
echo -e "${BLUE}🔹 GitHub repo:       ${FULL_REPO}${NC}"
echo -e "${BLUE}🔹 Release tag:       ${TAG}${NC}"
echo -e "${BLUE}🔹 Artifact name:     ${ASSET_NAME}${NC}"
echo -e "${BLUE}🔹 Artifact directory:${ARTIFACT_DIR}${NC}"
echo -e "${BLUE}🔹 DB connection:     ${DB_CONNECT}${NC}"
echo ""

# -----------------------------------------
# 3) Check release and asset on GitHub
# -----------------------------------------
echo -e "${BLUE}🔎 Checking release ${TAG} in ${FULL_REPO}...${NC}"

ASSET_LIST="$(gh release view "${TAG}" --repo "${FULL_REPO}" --json assets --jq '.assets[].name')"

if ! echo "${ASSET_LIST}" | grep -qx "${ASSET_NAME}"; then
  echo -e "${RED}❌ Release ${TAG} in ${FULL_REPO} does not contain asset ${ASSET_NAME}.${NC}"
  echo -e "${YELLOW}Available assets in this release:${NC}"
  echo "${ASSET_LIST:-<none>}"
  exit 1
fi

echo -e "${GREEN}✔ Release and asset found in GitHub.${NC}"

# -----------------------------------------
# 4) Download artifact if needed
# -----------------------------------------
if [[ -f "${ARTIFACT_PATH}" ]]; then
  echo -e "${GREEN}✅ Artifact already present: ${ARTIFACT_PATH}${NC}"
else
  echo -e "${BLUE}⬇️  Downloading artifact from GitHub Releases...${NC}"
  gh release download "${TAG}" \
    --repo "${FULL_REPO}" \
    --pattern "${ASSET_NAME}" \
    --dir "${ARTIFACT_DIR}" \
    --clobber
  echo -e "${GREEN}✔ Artifact downloaded to: ${ARTIFACT_PATH}${NC}"
fi

# -----------------------------------------
# 5) Deploy with SQLcl Project Deploy
# -----------------------------------------
echo ""
echo -e "${BLUE}🚀 Deploying version ${RELEASE_VERSION} to ${ENVIRONMENT}...${NC}"
echo -e "${YELLOW}Artifact path: ${ARTIFACT_PATH}${NC}"
echo ""

sql -name "${DB_CONNECT}" <<EOF
SET SCAN OFF;
project deploy -file ${ARTIFACT_PATH} -verbose
exit
EOF

echo ""
echo -e "${GREEN}🎉 Deployment of version ${RELEASE_VERSION} to ${ENVIRONMENT} completed successfully!${NC}"
