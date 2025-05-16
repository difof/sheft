#!/usr/bin/env bash
set -euo pipefail

BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
MAGENTA="\033[35m"

info()  { echo -e "${BLUE}${BOLD}ℹ${RESET}${BOLD} $* ${RESET}"; }
ok()    { echo -e "${GREEN}${BOLD}✔${RESET}${BOLD} $* ${RESET}"; }
info_input()    { echo -e "${RESET}${BOLD}${YELLOW} $* ${RESET}"; }
fail()  { echo -e "${RED}${BOLD}❌${RESET}${BOLD} $* ${RESET}"; exit 1; }

