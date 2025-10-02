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
- Has package subfolder (SDK exports): `{{ .Scaffold.should_package }}`

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
- `task test:bun -- test/ts` — run pure bun tests
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

---

### License
{{ .Scaffold.license }}