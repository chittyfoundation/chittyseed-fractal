---
uri: chittycanon://docs/tech/policy/REPLACE-ME-auth-contract
namespace: chittycanon://docs/tech
type: policy
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Auth Contract"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
binds_to: chittycanon://docs/tech/policy/chittyos-auth-contract-v1
---

# REPLACE-ME — Auth Contract Adherence

This service binds to the canonical **ChittyOS Auth Contract** (`chittycanon://docs/tech/policy/chittyos-auth-contract-v1`). This document is the service's explicit acceptance of that contract — like a signed control attestation.

## Service-to-Service: Binding-based

This service **DOES NOT** issue, consume, or accept service-to-service bearer tokens. All inter-service auth flows through declared Cloudflare Workers service bindings in `wrangler.jsonc`. The binding configuration is the trust boundary; the binding manifest is the audit trail.

| Bound service | Binding name | Purpose |
|---|---|---|
| ChittyCanon | `CHITTYCANON` | Canonical URI registry |
| ChittyAuth | `CHITTYAUTH` | User identity issuance + JWKS |
| ChittyCert | `CHITTYCERT` | Sovereignty + X.509 |
| ChittyRegister | `CHITTYREGISTER` | Scope registration |
| ChittyConnect | `CHITTYCONNECT` | Credential vault |
| ChittySchema | `CHITTYSCHEMA` | Meta-schema validation |
| ChittyTrust | `CHITTYTRUST` | Trust score queries |

Calls are made via `c.env.<BINDING>.fetch(...)` and never include `Authorization` headers between services. The bound service's wrangler config controls who can bind to it (account/zone-level ACL).

## End-User: Ch1tty Device-Code OAuth

User-facing routes accept JWTs issued by `auth.chitty.cc` via Ch1tty's device-code flow at `https://ch1tty.com/auth/device`. JWTs are verified edge-side using `jose` against the public JWKS at `https://auth.chitty.cc/.well-known/jwks.json`. No password flows. No client_secrets. No paste-token forms.

If a user-facing route receives no token, response is:

```json
{
  "error": "unauthorized",
  "reason": "missing_user_token",
  "authorize_url": "https://ch1tty.com/auth/device"
}
```

## ChittyID Issuance

This service **NEVER** generates ChittyIDs client-side. ChittyIDs are issued exclusively by `CHITTYAUTH` (the `auth.chitty.cc/api/v1/chittyid/issue` endpoint). The `hook-block-chittyid-generation` pre-commit hook enforces this at the repo layer.

## Authority Scopes

User tokens may carry scope claims like:

- `read:<entity-type>` — read access to declared entity types
- `write:<entity-type>` — write access (P/L/T/E/A)
- `legal:write:case:<case-id>` — case-scoped legal write (non-repudiation required)
- `govern:*` — governance authority (system-wide)

This service declares which scopes it requires in CHARTER.md §"API Contract".

## Audit & Revocation

- Binding changes are audited via wrangler config commit history
- User-token revocation is handled by ChittyAuth; this service does NOT cache tokens past request scope
- Sovereignty cert revocation immediately disables write capability (verified at request time via `CHITTYCERT` binding)

## Refs

- `chittycanon://docs/tech/policy/chittyos-auth-contract-v1` — the canonical contract
- `chittycanon://core/services/chittyauth` — issuer
- `chittycanon://core/services/chittycert` — sovereignty
- `connectivity/integrations/chittyauth.ts` — user OAuth middleware (this repo)
- `connectivity/integrations/bindings.ts` — service binding accessors (this repo)
- `SECURITY.md` — overall security posture
