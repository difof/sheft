# {{ .Project }}

{{ .Scaffold.description }}

## What is SHEFT stack?
Quick rundown: this repo is a comfy starter for shipping smart contracts with a modern toolbelt.

- Foundry for blazing-fast Solidity dev and tests
- Hardhat + Ethers for TypeScript scripts, tooling and ABI/types
- Bun for fast JS/TS tooling
- Taskfile as your humane command palette

## Project stats
- Solidity compiler: `{{ .Scaffold.solc_version }}`
- Target EVM: `{{ .Scaffold.evm_version }}`
- JS/TS package manager: `{{ .Scaffold.js_package_manager }}`

Key files and tools you’ll touch:
- `remappings.txt`, `lib/README.md` (Solidity libs)
- `hardhat.config.ts` (Hardhat configuration)
- `Taskfile.yaml` (your shortcuts)

## Quickstart
1) Install system deps (once):
- Bun: see `https://bun.com/docs/installation`
- Foundry (forge/cast): `https://getfoundry.sh/introduction/installation`
- Task: `https://taskfile.dev/installation/`

2) Format + compile + test:
```bash
task fmt            # prettier + forge fmt
task build          # forge compile + hardhat compile
task test:all       # foundry + hardhat + bun tests (ts)
```

## Directory structure (TL;DR)
```text
.
├─ .vscode/
├─ .gitignore
├─ bun.lock
├─ commitlint.config.js                # present if Husky/Commitlint enabled
├─ eslint.config.js
├─ foundry.toml
├─ hardhat.config.ts
├─ lib/                                # forge deps (submodules)
├─ package/                            # SDK build + re-exports ({{ .Scaffold.should_package }})
│  ├─ index.ts
│  └─ package.json
├─ script/                             # automation scripts
│  └─ foundry/
│     └─ deploy/                       # deploy scripts (forge script)
├─ src/
│  ├─ contracts/                       # Solidity sources
│  └─ ts/                              # shared TS utils (e.g., merkle, hashes)
├─ test/
│  ├─ foundry/                         # forge tests (Solidity)
│  ├─ hardhat/                         # integration tests (TS)
│  └─ ts/                              # pure bun tests (no hardhat)
├─ Taskfile.yaml                       # your command palette
└─ README.md
```

Notes:
- `lib/` gets populated by `task deps:sol` as git submodules (forge install). Don’t edit libraries there.
- Hardhat artifacts land in `artifacts/hardhat/...`; Foundry in `artifacts/foundry/...`.

## Tasks cheatsheet (zero memorization energy)

Core dev:
- `task deps` — install deps (TS + Foundry)
- `task fmt` — run prettier + forge fmt
- `task build` — compile with Foundry and Hardhat
- `task test` — Foundry tests (alias)
- `task test:hardhat` — Hardhat tests
- `task test:ts -- [[.Computed.jpm_test_files]]` — run pure ts tests
- `task test:all` - run all tests

ABI/Bytecode helpers:
- `task abi -- <ContractName>` — ABI from Foundry
- `task bytecode -- <ContractName>` — bytecode from Foundry
- `task abi:hardhat -- <path/to/Contract.sol>` — ABI from Hardhat
- `task bytecode:hardhat -- <path/to/Contract.sol>` — bytecode from Hardhat

Flattening (when explorers demand one-file):
- `task flatten -- src/contracts/Airdrop.sol` — via Foundry
- `task flatten:hardhat -- src/contracts/Airdrop.sol` — via Hardhat

Nodes/REPLs:
- `task node:anvil` — local chain (Foundry)
- `task node:hardhat` — local chain (Hardhat)
- `task repl:sol` — chisel
- `task repl:ts` — hardhat console

Coverage/Docs:
- `task cover` — Foundry coverage (lcov + html)
- `task docs` — generate natspec docs (Foundry)
- `task host:docs` — open docs locally
- `task host:cover` - open coverage locally

Deploy/Verify (you’ll need envs set; see deploy section in `Taskfile.yaml`):
- `task deploy -- <NETWORK> <WALLET> <ScriptName> [--verify] ...`
- `task verify -- <NETWORK> <contract-address> [path:ContractName]`

Cleaning:
- `task clean` — removes artifacts, coverage, docs, node_modules

## Wallet management (local keystore)

We keep a local keystore under `.keystore/` and use Foundry’s `cast` under the hood. Commands are thin wrappers so you don’t have to remember flags.

Create or import:
```bash
task wallet:new -- dev                 # create a new key named "dev"
task wallet:dry                        # generate a keypair (don’t store)
task wallet:ipk -- mykey               # import private key into keystore
task wallet:imn -- mykey               # import from mnemonic (prompts for phrase + index)
```

Inspect:
```bash
task wallet:ls                         # list local keys
task wallet:addr -- dev                # show address for a key
task wallet:pk -- dev                  # print private key (careful!)
task wallet:cp -- dev                  # change password for a key
```

Pro tip: keep `.keystore/` out of git (it already is). Treat anything printed to your terminal as sensitive.

**NOTE**: Never use plaintext secrets, devs usually put private keys in `.env` and that's exactly how you compromise millions of dollars.

## Coding Style & Conventions

{{if .Scaffold.use_husky_commitlint -}}
### Conventional Commits

Use conventional commits for all changes. The project enforces this via `commitlint.config.js`:

```bash
feat: add new airdrop functionality
fix: resolve merkle tree verification bug
test: add integration tests for claim flow
docs: update deployment instructions
chore: updated hardhat config
refactor: moved airdrop to new dir
```
{{- end}}

### Solidity Test Conventions (Foundry)

**File naming**: `<ContractName>.<aspect>.test.sol`
- `Airdrop.doubleSpend.test.sol`
- `Airdrop.setup.sol` (setup files)

**Test contract naming**: `Test_<ContractName>_<Aspect>`
- `Test_Airdrop_Generic`
- `Test_Airdrop_DoubleSpend`

**Test function naming**:
- `test_<Behavior>` — standard tests
- `testFuzz_<Behavior>` — fuzz tests  
- `testFork_<Behavior>` — fork tests
- `testDiff_<Behavior>` — differential/property tests

**Setup files** (`<ContractName>.setup.sol`):
- Purpose: shared fixtures, constants, helpers
- When to use: multiple test files for same contract
- Convention: `<ContractName>Setup` contract with internal helpers prefixed with `_`

### Hardhat Test Conventions (TypeScript)

**File naming**: `<ContractName>Integration.test.ts`
- `AirdropIntegration.test.ts`

**Structure**: Mocha `describe` blocks with contract name, `beforeEach` setup, `it` test cases

**Helper functions**: Place after tests, descriptive names
- `makeMerkleTree`, `buildMapperFunction`, `loadContracts`

### Bun Test Conventions

**File naming**: `<functionality>.test.ts` (lowercase with camelCase)
- `simpleMerkle.test.ts`

**Location**: `test/ts/` for pure TypeScript logic (no blockchain interaction)

**Structure**: Simple describe/it blocks, focused on utility functions

### Deploy Script Conventions

**Location**: `script/foundry/deploy/`
**File naming**: `<ContractName>.s.sol`
**Class naming**: `Deploy_<ContractName>` in PascalCase with underscore

**Structure**:
- `run()` function: handles wallet selection and broadcast
- `deploy()` function: pure deployment logic (reusable, testable)
- Always separate concerns: `run()` calls `deploy()`

**Fork tests**: Create `test/foundry/fork/Deploy<ContractName>.test.sol`
- Naming: `TestFork_Deploy<ContractName>`
- Tests the `deploy()` function directly (not `run()`)

### Wallet Separation

- **Local dev**: Use `.keystore/dev` or similar named keys
- **Testnet**: Separate key (e.g., `.keystore/testnet`)
- **Mainnet**: Dedicated key, never reuse testnet keys
- Never share keys across environments

### Solidity Code Organization

**Contract location**: `src/contracts/` for all Solidity sources

**File structure**: One main contract per file, with related interfaces and structs

**Interfaces**: Define in same file as implementation, prefixed with `I`
- `IAirdrop`, `IAirdropErrors`

**Structs**: Place at top of file if used by interface
- `AirdropMembership`

**Import organization**: Group by source (openzeppelin, solady, local), alphabetize within groups

**Naming**: PascalCase for contracts, interfaces, structs; camelCase for functions/variables

### TypeScript Code Organization

**Utilities location**: `src/ts/` for shared utilities
- `merkle.ts`, `keccak.ts`

**Hardhat scripts**: `script/hardhat/` for deployment/automation scripts

**SDK exports**: Use `package/index.ts` to re-export from `typechain` and `src/ts/`
- Export typechain factories and types
- Export utilities with renamed types (e.g., `MerkleDataItem`)
- Keep exports clean and intentional

### Environment Configuration

**Location**: `.env` file in project root

**Networks**: Define RPC URLs for both Foundry and Hardhat
```bash
# Networks
ETHEREUM_MAINNET_RPC= # RPC endpoint (websocket not supported)
ETHEREUM_MAINNET_API_KEY= # etherscan API key
ETHEREUM_MAINNET_CHAINID=1
```

**Required vars**: Document network RPC URLs, API keys (Etherscan, etc.)

---

## License
{{ .Scaffold.license }}