# AGENTS.md – PCC Vulnerability‑Hunting Agent Instructions

## Purpose

This file tells OpenAI Codex how to operate on Apple’s **security‑pcc** source tree and the VRE mirror you’ll commit in this repo.  The objective is to surface bug‑bounty‑eligible weaknesses that violate PCC’s five core guarantees (statelessness, enforceable guarantees, no privileged access, non‑targetability, verifiable transparency).

## Repository layout assumptions

* `vre/` — VRE image + helper scripts (`make vre-shell`, `make repro`)
* `src/` — pristine checkout of github.com/apple/security-pcc
* `research/` — your working copies and harnesses
* `tests/` — unit & regression suites Codex must keep green

## Commands Codex SHOULD run

* `./scripts/bootstrap.sh` — installs LLVM 17, `clang-tidy`, `rust-analyzer`, `swift-format`, afl++.
* `make ci` — runs `swift test`, CMake builds, and static analysis pipeline.
* `make fuzz` — kicks off `afl-fuzz` on protobuf parsers for 20 minutes.
* `./scripts/diff-sandboxes.py` — compares current sandbox profiles against hardened WebKit/BlastDoor baselines.
* `python research/log_audit.py` — greps for `splunkloggingd` misuse & accidental string formatting of user data.

## Coding conventions

* Follow Apple Swift API Design Guidelines and LLVM clang‑format default style.
* Keep patches < 400 LOC; split large refactors into sequential commits.
* All new Swift must use `DataProtocol` rather than raw pointers.
* Prefer `Enum` error types over integer return codes.

## Programmatic checks

This repo ships GitHub Actions; Codex MUST ensure they pass locally via `act`:

1. `Static‑Analysis`: zero clang‑tidy warnings of type *security* or *cert‑*
2. `Sandbox‑Diff`: no profile reads `network*` outside declared allow‑lists.
3. `Fuzz‑Smoke`: no crashes within 5 minutes of seed corpus.
4. `Secrets‑Scan`: repo contains no hard‑coded private keys.

## Suggested task queue

1. *Enumerate external‑input parsers* — locate protobuf/JSON/CBOR handlers lacking length checks; write property tests.
2. *Sandbox hardening* — tighten any `allow file-read*` in `profiles/*.sb` that are broader than needed.
3. *Logging audit* — trace calls to `os_log`, verify no user‑supplied bytes reach `splunkloggingd`.
4. *Attestation bypass probes* — attempt to inject forged ensemble attestations inside VRE; note any path that accepts unsigned payloads.
5. *Ephemeral Data Mode persistence* — search for file writes outside `/tmp` that survive reboot in VRE.

## Pull‑request messaging template (use by Codex)

```
<scope>: <concise summary>

Why:
Explain which PCC guarantee could be violated and how the patch mitigates it.

What:
High‑level overview   
• Key files touched  
• Tests added  

Verification:
Paste `make ci` and fuzz logs proving success.
```
