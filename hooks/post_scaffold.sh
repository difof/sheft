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

check_bin() {
  if ! command -v "$1" &>/dev/null; then
    fail "Missing required tool: ${BOLD}$1${RESET}\n   Please install it before continuing."
  else
    ok "Found ${BOLD}$1${RESET}"
  fi
}

check_bin git
check_bin bun
check_bin forge
check_bin cast
check_bin task

cd "{{ .Project }}"
info "Post-scaffold hook running in $(pwd)"

if [ "{{ .Scaffold.should_package }}" != "true" ]; then
  rm -rf package
fi

if [ "{{ .Scaffold.use_husky_commitlint }}" != "true" ]; then
  rm -rf .husky commitlint.config.js
fi

task fmt

info "Initializing git repo"
git init
git add .gitignore
git commit -m "chore: initialized"
ok "Git repo initialized"

info "Installing TypeScript deps"
task deps:ts

info "Adding Solidity dependencies"
task deps:sol -- foundry-rs/forge-std lib/forge-std
task deps:sol -- OpenZeppelin/openzeppelin-contracts lib/openzeppelin-contracts
task deps:sol -- vectorized/solady lib/solady
git commit -m "chore: added solidity dependencies"
ok "Solidity deps added"

info_input "Creating new dev wallet"
task wallet:new -- dev

info "Copying .env.example → .env"
cp .env.example .env

info "Running all tests"
task test:all
ok "All tests passed successfully"
