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

{{ if .Computed.empty_start }}
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

task sort-package.json

info "Initializing git repo"
git init
git add .gitignore

{{ if .Scaffold.git_commit_init }}
git commit -m "chore: initialized"
{{ end }}

ok "Git repo initialized"

info "Installing TypeScript deps"
task deps:ts

{{ if .Scaffold.install_default_sol_libs }}
info "Adding Solidity dependencies"
task deps:sol -- foundry-rs/forge-std lib/forge-std
task deps:sol -- OpenZeppelin/openzeppelin-contracts lib/openzeppelin-contracts
task deps:sol -- OpenZeppelin/openzeppelin-contracts-upgradeable lib/openzeppelin-contracts-upgradeable
task deps:sol -- vectorized/solady lib/solady

{{ if .Scaffold.git_commit_init }}
git commit -m "chore: added solidity dependencies"
{{ end }}

ok "Solidity deps added"
{{end}}

info "Formatting files"
task fmt

info "Adding all changes to git"
git add .

{{ if .Scaffold.git_commit_init }}
git commit -m "chore: post SHEFT setup"
{{ end }}

info_input "Creating new dev wallet"
task wallet:new -- dev

info "Copying .env.example → .env"
cp .env.example .env

{{ if not .Computed.empty_start }}
info "Running all tests"
task test:all
ok "All tests passed successfully"
{{ end }}