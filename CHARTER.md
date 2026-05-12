---
uri: chittycanon://docs/tech/policy/REPLACE-ME-charter
namespace: chittycanon://docs/tech
type: policy
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Charter"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
---

# REPLACE-ME Charter

## Classification

- **Canonical URI:** `chittycanon://core/services/REPLACE-ME`
- **Tier:** 5 (replace with correct tier)
- **Organization:** CHITTYFOUNDATION
- **Scope type:** service
- **Generated from:** `CHITTYFOUNDATION/chittyseed-fractal`

## ChittyDNA

- **ChittyID:** REPLACE-ME (issued by `auth.chitty.cc` on bootstrap)
- **DNA Hash:** Pending
- **Lineage:** root (set `parent_scope_id` in `scope.json` if child of another service)
- **Sovereignty cert:** `SOVEREIGNTY.cert` (contract-bound; revoked on contract drift)

## Mission

Describe the mission in one paragraph. What does this service do? Who is it for?

## Scope

### IS Responsible For

- Capability 1
- Capability 2

### IS NOT Responsible For

- Out of scope 1
- Out of scope 2

## Pentad Documents

| Vertex | File | Purpose |
|---|---|---|
| Charter | `CHARTER.md` (this file) | Mission, scope, API contract |
| Architecture | `CHITTY.md` | Stack, data plane, ecosystem position |
| Developer | `CLAUDE.md` | Dev commands, workflow, patterns |
| Security | `SECURITY.md` | Auth model, CORS, sensitive intent |
| Agents | `AGENTS.md` | Agent declarations, orchestrator binding |

Plus the identity affirmation: `SOVEREIGNTY.cert` (signed by `cert.chitty.cc`, conditional on contract adherence).

## Bound Contracts

This service explicitly adheres to:

| Contract | Local | Canonical |
|---|---|---|
| Auth (service bindings + user device-code) | `authority/contracts/AUTH_CONTRACT.md` | `chittycanon://docs/tech/policy/chittyos-auth-contract-v1` |
| Secrets (no-tokens-in-chat) | `authority/contracts/SECRETS_CONTRACT.md` | `chittycanon://docs/tech/policy/sensitive-intent-contract-v1` |
| Entity ontology | (inline, this charter) | `chittycanon://gov/governance#core-types` |
| Fractal layout | `scope.json` | `chittycanon://core/services/chittyschema#meta/fractal-layout` |

`SOVEREIGNTY.cert` lists revocation conditions tied to drift on any of the above.

## Capability Router Slot

For ChittyMarket (`chittycanon://docs/ops/architecture/chittymarket-capability-router`):

- **Capability group:** REPLACE-ME (one of: `build`, `ship`, `govern`, `legal`, `connect`, `workspace`, `local-lab`, `agent-runtime`, `market`, `internal`)
- **Execution class:** REPLACE-ME (one of: `@chitty/ambient`, `@chitty/workspace`, `@chitty/connectors`, `@chitty/reasoning`)

## Dependencies

Service-to-service calls use Cloudflare Workers service bindings declared in `wrangler.jsonc`. No service tokens.

| Type | Service | Binding | Purpose |
|---|---|---|---|
| Required | ChittyCanon | `CHITTYCANON` | Canonical URI registry |
| Required | ChittyAuth | `CHITTYAUTH` | User identity, ChittyID issuance |
| Required | ChittyCert | `CHITTYCERT` | Sovereignty affirmation |
| Required | ChittyRegister | `CHITTYREGISTER` | Scope registration |
| Required | ChittyConnect | `CHITTYCONNECT` | Credential vault (secrets retrieval) |
| Required | ChittySchema | `CHITTYSCHEMA` | Meta-schema validation |
| Required | ChittyTrust | `CHITTYTRUST` | Trust score queries |
| Required | ChittyTrack | (tail consumer) | Observability tail |
| Optional | Ch1tty | `CH1TTY` | MCP backend aggregation (if exposes MCP) |
| Optional | ChittyMarket | `CHITTYMARKET` | Capability registration (if exposes capabilities) |
| Optional | ChittyAgent Orchestrator | `CHITTYAGENT_ORCHESTRATOR` | Agent registration (if ships agents) |
| Optional | ChittyBeacon | `CHITTYBEACON` | Deploy beacon emission |

## API Contract

### Core Endpoints

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `/health` | GET | none | Liveness — returns `{"status":"ok","service":"<name>"}` |
| `/api/v1/status` | GET | none | Service status with binding probes |

### User-Facing Endpoints

(Add service-specific routes. Auth via Ch1tty device-code per `AUTH_CONTRACT.md`.)

### Inter-Service Endpoints

Reachable only via declared bindings. (List any routes that bound services should call.)

## Compliance Checklist

- [ ] All Pentad files present (CHARTER, CHITTY, CLAUDE, SECURITY, AGENTS)
- [ ] `SOVEREIGNTY.cert` populated and signed by ChittyCert
- [ ] Both contracts present (`AUTH_CONTRACT.md`, `SECRETS_CONTRACT.md`)
- [ ] `/health` operational
- [ ] `scope.json` valid against `chittycanon://core/services/chittyschema#meta/repo-scope`
- [ ] Fractal layout valid against `chittycanon://core/services/chittyschema#meta/fractal-layout`
- [ ] All required service bindings declared in `wrangler.jsonc`
- [ ] Tail consumer configured (`chittytrack`)
- [ ] Service registered in ChittyRegistry
- [ ] Initial certification badge requested via ChittyCertify

---
*Charter Version: 0.1.0*
