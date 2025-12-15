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

echo -e "${RED}⚠ Dropping ALL objects in the production...${NC}"
sql -name "$DB_CONNECT_PRO" @../scripts/clean_sql/destination-clean.sql
echo -e "${GREEN}✅ Production database cleanup completed.${NC}"

