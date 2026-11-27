# CTF

> **Warning:** Every contract here is training material with deliberate bugs. Do not deploy or reuse it.

Find as many vulnerabilities as you can in the challenge contracts. Each round
is released as a folder under `src/`.

## Setup

```sh
forge install
forge build
```

## Scope

- **In scope:** every contract under `src/round-*/`.
- **Trusted, not in scope:** `src/lib/DemoAsset.sol` (a plain test ERC-20),
  OpenZeppelin (`lib/openzeppelin-contracts`) and Uniswap V3 core
  (`lib/v3-core`). How the challenges *use* them is in scope.
- Privileged roles (owners, admins, operators, governance) act honestly and do not make mistakes.
  A bug that only a trusted role can trigger against itself is not a finding.

## Severity

Rate each finding by impact and likelihood:

| Impact \ Likelihood | High | Medium | Low |
|---|---|---|---|
| **High** | Critical | High | Medium |
| **Medium** | High | Medium | Low |
| **Low** | Medium | Low | Low |

Low findings count too: wrong events, missing safeguards and similar issues
are worth reporting.
