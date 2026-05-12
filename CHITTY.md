---
uri: chittycanon://docs/tech/architecture/REPLACE-ME
namespace: chittycanon://docs/tech
type: architecture
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Architecture"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
---

# REPLACE-ME

> `chittycanon://core/services/REPLACE-ME` | Tier 5 (replace) | `REPLACE-ME.chitty.cc`

## Ecosystem Position

Describe where this service sits in the ChittyOS ecosystem. What tier? What does it consume? What consumes it?

## Pentad

This repo follows the ChittyOS **Pentad** convention:

| Vertex | File | Purpose |
|---|---|---|
| Charter | `CHARTER.md` | Mission, scope, API contract |
| Architecture | `CHITTY.md` (this file) | Stack, ecosystem position, data plane |
| Developer | `CLAUDE.md` | Commands, dev workflow, patterns |
| Security | `SECURITY.md` | Auth model, CORS, sensitive intent |
| Agents | `AGENTS.md` | Agent declarations, orchestrator binding |

Plus the identity affirmation: `SOVEREIGNTY.cert` (signed by `cert.chitty.cc`).

## Stack

- **Runtime:** Cloudflare Workers via Hono
- **Language:** TypeScript (strict)
- **Validation:** Zod v4 (`zod` ≥ 4)
- **Schema authority:** `@chittyos/schema` — meta-schemas at `https://schema.chitty.cc/meta/`
- **Agent toolkit:** `@chittyos/agent-sdk` for service-local agents
- **Data:** Neon PostgreSQL (if applicable — declared in data plane below)
- **Observability:** Tail consumer → `chittytrack`; deploy beacon → `chittybeacon`

## Repository Layout — Fractal Trinity

Per `chittycanon://core/services/chittyschema#meta/fractal-layout`:

```
identity/      # ChittyID layer — what this service IS (src, agents, schemas, scripts)
authority/    # ChittyTrust + ChittyCert + ChittyCanon — weight (canon, certifications, owners)
connectivity/ # ChittyConnect + ChittyRouter — interaction
              # ├─ api/         (Worker handlers)
              # ├─ integrations/(chittyauth, chittycanon, chittymarket, ch1tty, ...)
              # ├─ migrations/  (SQL per database)
              # ├─ releases/    (CHANGELOG, version tags)
              # ├─ deployments/ (beacon reports → chittybeacon)
              # ├─ consumers/   (populated by Schema Owner Manifest sync)
              # └─ upstreams/   (declared dependencies)
scopes/       # nested fractal sub-services (recursive)
```

See `scope.json` for the scope manifest.

## ChittyOS Ecosystem

### Certification

- **Badge:** ChittyOS Compatible (target after `npm run bootstrap`)
- **Certifier:** ChittyCertify via `cert.chitty.cc/api/v1/issue`
- **Sovereignty:** declared in `SOVEREIGNTY.cert`
- **Last Certified:** Pending

### ChittyDNA

- **ChittyID:** REPLACE-ME (issued by `auth.chitty.cc` during bootstrap)
- **DNA Hash:** Pending
- **Lineage:** root (or set parent on bootstrap)

### Capability Router Slot (Phase 1 overlay)

Declare the JTBD group + execution class so the service registers cleanly with ChittyMarket (`chittycanon://docs/ops/architecture/chittymarket-capability-router`):

- **Capability group:** REPLACE-ME (one of: `build`, `ship`, `govern`, `legal`, `connect`, `workspace`, `local-lab`, `agent-runtime`, `market`, `internal`)
- **Execution class:** REPLACE-ME (one of: `@chitty/ambient`, `@chitty/workspace`, `@chitty/connectors`, `@chitty/reasoning`)

### Dependencies

| Type | Service | Purpose |
|---|---|---|
| Schema | ChittySchema | Fractal-layout + scope manifest validation |
| Canon | ChittyCanon | URI registration |
| Identity | ChittyAuth | ChittyID issuance + service token |
| Cert | ChittyCert | SOVEREIGNTY_AFFIRMATION |
| Registry | ChittyRegister | Scope registration |
| Marketplace | ChittyMarket | Capability registration |
| Gateway | Ch1tty | MCP backend aggregation (if applicable) |
| Agent SDK | `@chittyos/agent-sdk` | Service-local agent toolkit |
| Observability | ChittyTrack | Tail consumer |
| Beacon | ChittyBeacon | Deploy state reporting |

## Data Plane

If this service owns or reads tables, list them here:

- `<table>` (canon type, owner)
- ...

## Consumers

(Populated by the Schema Owner Manifest sync.)

## Upstreams

(Declared in `connectivity/upstreams/`.)

## Runtime Surfaces

| Surface | Path | Auth |
|---|---|---|
| Health | `GET /health` | none |
| Status | `GET /api/v1/status` | none |
| API | `connectivity/api/index.ts` routes | `CHITTY_AUTH_SERVICE_TOKEN` (JWT via jose) |

CORS policy: `*.chitty.cc` + `localhost` only. See `SECURITY.md`.
