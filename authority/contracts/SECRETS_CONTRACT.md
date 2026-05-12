---
uri: chittycanon://docs/tech/policy/REPLACE-ME-secrets-contract
namespace: chittycanon://docs/tech
type: policy
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Secrets Contract"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
binds_to: chittycanon://docs/tech/policy/sensitive-intent-contract-v1
---

# REPLACE-ME — Secrets Contract Adherence

This service binds to the canonical **Sensitive Intent Contract** (`chittycanon://docs/tech/policy/sensitive-intent-contract-v1`). This document is the service's explicit acceptance — a signed control attestation.

## Storage

| Class | Where | Retrieved By |
|---|---|---|
| User OAuth tokens | ChittyConnect vault (1Password-backed) | `CHITTYCONNECT` binding |
| Third-party connector credentials | ChittyConnect vault | `CHITTYCONNECT` binding |
| Internal cryptographic keys | Workers Secrets (wrangler `secrets`) | `c.env.<SECRET_NAME>` (runtime only) |
| Non-secret config | `wrangler.jsonc` `[vars]` | `c.env.<VAR>` |

**Never stored:** plaintext anywhere in repo, env files, CI variables, logs, chat, PR bodies, commit messages, NPM scripts, Notion pages, or KV/D1/R2 without envelope encryption.

## Retrieval

Service code retrieves secrets at runtime via the `CHITTYCONNECT` binding:

```ts
const cred = await callBinding<{token: string}>(
  c.env.CHITTYCONNECT,
  `/api/v1/credentials/${capability_id}`,
);
```

ChittyConnect handles vault lookup, audit logging, rotation, and revocation. The service never holds long-lived credential material in module scope.

## Prohibited Patterns

The following are blocked by pre-commit hooks and CI:

- API keys / OAuth tokens in source files, env files, or `wrangler.jsonc` `[vars]`
- `process.env.<TOKEN>` reads in handler code (use binding instead)
- CLI prompts that ask the user to "paste your API key"
- Logging secret values, even truncated
- Including secrets in error messages or status responses
- Hardcoded fallback credentials for "dev mode"

Hooks enforcing these:

- `hook-block-credential-leakage`
- `hook-block-credential-asking`
- `hook-block-credentials-in-commands`
- `hook-block-credential-files`

## User-Sourced Credentials: Device-Code Only

When the service needs a third-party credential (e.g., user's Notion API), the flow is:

1. Service returns `{authorize_url: ".../device"}` to client
2. User completes OAuth in browser via ChittyConnect
3. Token vaulted under user's ChittyID
4. Service retrieves via `CHITTYCONNECT` binding scoped to that user

**Never** prompt the user to paste a token in CLI or chat. **Never** accept tokens via POST body from an unauthenticated client.

## Fail-Closed

If `CHITTYCONNECT` is unreachable or returns an error for credential retrieval, the service MUST:

1. Return `POLICY_BLOCKED_CHITTYCONNECT_UNAVAILABLE` (503)
2. NOT fall back to local prompts, env vars, or cached credentials
3. NOT degrade to "anonymous mode" if anonymous mode would expose data the credential gates

## Audit Trail

Every `CHITTYCONNECT` credential retrieval is logged with:

- Requesting service ChittyID
- User ChittyID (if user-scoped)
- Capability ID being authorized
- Timestamp + request hash
- Trust score at time of request

Audit log is tail-consumed by `chittytrack`. Anomaly detection runs in `chittytrust`.

## Rotation

This service does NOT rotate secrets. Rotation is owned by ChittyConnect. The service tolerates rotation by re-fetching on 401 from the third party (with a one-attempt back-off; further failures escalate to ChittyConnect).

## Refs

- `chittycanon://docs/tech/policy/sensitive-intent-contract-v1` — the canonical contract
- `chittycanon://core/services/chittyconnect` — credential vault
- `chittycanon://core/services/chittytrack` — audit tail
- `chittycanon://core/services/chittytrust` — anomaly detection
- `AUTH_CONTRACT.md` — paired auth contract (this dir)
- `SECURITY.md` — overall security posture (repo root)
