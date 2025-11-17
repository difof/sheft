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
check_bin forge
check_bin cast
check_bin task
{{ if eq .Scaffold.js_package_manager "bun" }}check_bin bun{{ else }}check_bin npm{{ end }}

cd "{{ .Project }}"
info "Post-scaffold hook running in $(pwd)"

{{ if not .Scaffold.should_package }}
[ -d package ] && rm -rf package
{{ end }}

{{ if not .Scaffold.use_husky_commitlint }}
[ -d .husky ] && rm -rf .husky
[ -f commitlint.config.js ] && rm -f commitlint.config.js
{{ end }}

{{ if not .Scaffold.export_abi }}
[ -d tasks/contracts.yaml ] && rm -rf tasks/contracts.yaml
{{ end }}

{{ if .Scaffold.empty_start }}
rm -rf src/contracts/*.sol
find test/foundry -type f -name '*.sol' -delete
find script/foundry -type f -name '*.sol' -delete
rm -rf test/hardhat/*.ts
{{ else }}
  {{ if not .Computed.use_viem }}
  rm -fr test/hardhat/AirdropIntegration.viem.test.ts
  {{ end }}
  {{ if not .Computed.use_ethers }}
  rm -rf test/hardhat/AirdropIntegration.test.ts test/hardhat/KeccakEthersDiff.test.ts
  {{ end }}
{{ end }}

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

info "Formatting files"
task fmt

info "Commiting all changes"
git add .
git commit -m "chore: post SHEFT setup"

info_input "Creating new dev wallet"
task wallet:new -- dev

info "Copying .env.example → .env"
cp .env.example .env

{{ if not .Scaffold.empty_start }}
info "Running all tests"
task test:all
ok "All tests passed successfully"
{{ end }}