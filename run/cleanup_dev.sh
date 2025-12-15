#!/bin/bash

set -euo pipefail

# --- Colors ---
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m'

# Load environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/setup_env.sh"

echo -e "${BLUE}Cleaning up DEV database objects (custom only)...${NC}"
sql -name "$DB_CONNECT_DEV" @../scripts/clean_sql/origen-clean.sql
echo -e "${GREEN}✅ DEV database cleanup completed.${NC}"

