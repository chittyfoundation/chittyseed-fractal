---
uri: chittycanon://docs/tech/policy/REPLACE-ME-security
namespace: chittycanon://docs/tech
type: policy
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Security Policy"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
---

# REPLACE-ME — Security Policy

This is the **Security** vertex of the ChittyOS Pentad (CHARTER + CHITTY + CLAUDE + **SECURITY** + AGENTS). Every service is required to declare its security posture explicitly here.

## Service-to-Service Auth: Bindings (NOT tokens)

ChittyOS does **NOT** use service-to-service bearer tokens. Inter-service calls use **Cloudflare Workers service bindings** declared in `wrangler.jsonc`:

```jsonc
"services": [
  { "binding": "CHITTYCANON",    "service": "chittycanon" },
  { "binding": "CHITTYAUTH",     "service": "chittyauth" },
  { "binding": "CHITTYCERT",     "service": "chittycert" },
  { "binding": "CHITTYREGISTER", "service": "chittyregister" },
  { "binding": "CHITTYCONNECT",  "service": "chittyconnect" },
  { "binding": "CHITTYSCHEMA",   "service": "chittyschema" },
  { "binding": "CHITTYTRUST",    "service": "chittytrust" }
]
```

The binding configuration **is** the trust boundary. No `Authorization` header crosses between services; no `CHITTY_AUTH_SERVICE_TOKEN` is needed for service-to-service calls.

Call bound services via `c.env.<BINDING>.fetch(...)` — see `connectivity/integrations/bindings.ts` for typed accessors.

## User OAuth: Device-Code via Ch1tty

End-user authentication uses the device-code OAuth flow through `https://ch1tty.com/auth/device`. The user-token lifecycle:

1. User initiates → service responds with `401` and `authorize_url: https://ch1tty.com/auth/device`
2. User opens URL, completes consent in browser
3. Service polls for token; receives Ch1tty-signed JWT
4. JWT validated edge-side via `jose` against `https://auth.chitty.cc/.well-known/jwks.json`
5. Token stored in ChittyConnect (1Password-backed vault) under the user's ChittyID

Middleware: `connectivity/integrations/chittyauth.ts`. Apply only to user-facing routes (not inter-service paths).

## Sensitive Intent Contract (BINDING)

Per `chittycanon://docs/tech/policy/sensitive-intent-contract-v1`:

- **NEVER** collect API keys, OAuth tokens, or long-lived secrets via CLI prompts or chat
- **NEVER** paste secrets into source files, commit messages, or PR bodies
- All credentials flow through **ChittyConnect** (1Password-backed vault)
- Third-party connector credentials use device-code OAuth terminating in ChittyConnect
- Fail-closed if ChittyConnect is unavailable → return `POLICY_BLOCKED_CHITTYCONNECT_UNAVAILABLE`

## CORS Policy

CORS is restricted to:

- `https://*.chitty.cc`
- `http://localhost:*` (development only)
- `http://127.0.0.1:*` (development only)

No wildcard origins, no `Access-Control-Allow-Origin: *` in production.

## Required Bindings & Env Vars

**Bindings** (declared in `wrangler.jsonc`, not env vars):

- Required: `CHITTYCANON`, `CHITTYAUTH`, `CHITTYCERT`, `CHITTYREGISTER`, `CHITTYCONNECT`, `CHITTYSCHEMA`, `CHITTYTRUST`
- Optional: `CH1TTY` (MCP backend), `CHITTYMARKET` (capabilities), `CHITTYAGENT_ORCHESTRATOR` (agents), `CHITTYBEACON` (deploy beacons)

**Env vars** (non-secret, in `wrangler.jsonc` `[vars]`):

| Variable | Purpose |
|---|---|
| `CHITTY_ENVIRONMENT` | `development` \| `staging` \| `production` |
| `SERVICE_NAME` | Service identity, used in `/health` payload |

Service-specific secrets are fetched at runtime via the `CHITTYCONNECT` binding — never stored in `[vars]` and never read from env directly.

## Sovereignty Affirmation

Every service MUST issue a `SOVEREIGNTY_AFFIRMATION` certificate via `cert.chitty.cc/api/v1/issue` (called via the `CHITTYCERT` binding during bootstrap). See `SOVEREIGNTY.cert`. The cert binds the service's `ChittyID` to its canonical URI and operating authority.

## Trust Posture

This service participates in **ChittyTrust** scoring. Trust impacts:

- Whether `connect`-type capabilities can be auto-enabled cross-channel
- Eligibility for `legal` / `govern` write authority
- Routing priority in Ch1tty slim-MCP search

Trust scores are queried via the `CHITTYTRUST` binding (never cached locally beyond request scope).

## P/L/T/E/A Authority Rules

Per `chittycanon://gov/governance#core-types`:

- Claude/agent contexts are **Person (P)** synthetic, NEVER Thing (T)
- Service write authority must declare the entity type(s) it can mutate
- Legal/Authority writes require non-repudiation receipts (hash + timestamp + actor + capability_id + case_id)

## Vulnerability Disclosure

Report security issues to: **security@chitty.cc**

For coordinated disclosure: file via `https://chittyconnect.chitty.cc/security/disclosure` with PGP-encrypted body.

Do NOT open public issues for vulnerabilities. Do NOT post details in Slack/Discord/Notion until disclosure window has closed.

## Pre-commit Hooks (BINDING)

The following hooks block insecure commits:

- Hookify entity-type validation (`hook-validate-entity-types`)
- ChittyID generation prohibition (`hook-block-chittyid-generation` — IDs are issued by chittyauth, never generated client-side)
- Credential leakage scan (`hook-block-credential-leakage`)
- Bypass-pipeline prevention (`hook-block-bypass-pipeline`)

## Refs

- `chittycanon://docs/tech/policy/sensitive-intent-contract-v1`
- `chittycanon://gov/governance#core-types` — P/L/T/E/A ontology
- `chittycanon://core/services/chittyconnect` — credential vault
- `chittycanon://core/services/chittyauth` — user OAuth + ChittyID issuance
- `chittycanon://core/services/chittycert` — sovereignty + cert authority
- `chittycanon://core/services/chittytrust` — trust scoring
- Cloudflare Workers [Service Bindings](https://developers.cloudflare.com/workers/runtime-apis/bindings/service-bindings/)
