# CLAUDE.md

## Project Overview

REPLACE-ME — describe what this service does in 1–2 sentences.

**Repo:** `CHITTYFOUNDATION/REPLACE-ME` (or `CHITTYOS/REPLACE-ME`, `chittyapps/REPLACE-ME`)
**Deploy:** Cloudflare Workers at `REPLACE-ME.chitty.cc` (if applicable)
**Stack:** Hono TypeScript, Zod, PostgreSQL (if applicable)
**Canonical URI:** `chittycanon://core/services/REPLACE-ME` | Tier 5
**Generated from:** `CHITTYFOUNDATION/chittyseed-fractal`

## Repository Layout — Fractal Trinity

This repo follows the **ChittyOS fractal trinity** (identity / authority / connectivity), mirroring the data-layer scope primitive at the directory level. See `scope.json` for the scope manifest.

```
<repo>/
├── identity/                 # ChittyID layer — what this service IS
│   ├── src/                  # source code
│   ├── agents/               # subagent definitions (specific to this service)
│   ├── scripts/              # build / generation / validation scripts
│   ├── schemas/              # JSON Schema definitions
│   └── docs/                 # documentation
│
├── authority/                # ChittyTrust + ChittyCert + ChittyCanon — weight
│   ├── canon/                # chittycanon:// citations
│   ├── certifications/       # ChittyCertify badges
│   └── owners/               # CODEOWNERS, governance
│
├── connectivity/             # ChittyConnect + ChittyRouter — interaction
│   ├── api/                  # inbound endpoints (Worker handlers)
│   ├── integrations/         # outbound hooks
│   ├── migrations/           # SQL per database
│   ├── releases/             # CHANGELOG, version tags
│   ├── deployments/          # deploy logs, beacon reports
│   ├── consumers/            # populated from Owner Manifest
│   └── upstreams/            # dependency declarations
│
├── scopes/                   # recursive fractal sub-services (each is a child scope)
│
├── scope.json                # fractal scope manifest at repo root
├── CHARTER.md                # API contract
├── CHITTY.md                 # architecture
├── CLAUDE.md                 # this file
├── package.json
├── tsconfig.json
└── wrangler.jsonc            # if Cloudflare Worker
```

## Common Commands

```bash
npm install              # Install dependencies
npm run build            # tsc + tsc-alias → identity/dist
npm run dev              # tsx watch identity/src/index.ts
npm run dev:api          # wrangler dev on connectivity/api/index.ts
npm run deploy           # wrangler deploy
npm test                 # vitest run
npm run lint             # eslint identity/src
```

### Fractal compliance

```bash
npm run validate:fractal   # Validate this repo against fractal-layout meta-schema
npm run certify            # Run ChittySchema service-compliance certification
```

## Per-Service Ownership Pattern (BINDING)

- **Subagents** that are SPECIFIC to this service live in `identity/agents/`
- **Authority documents** (CHARTER.md, CHITTY.md, CLAUDE.md) live at repo root
- **Detailed dev guide** (if needed beyond CLAUDE.md) lives at `authority/DEV_GUIDE.md`
- **Service-specific schemas** live at `identity/schemas/`
- **Migrations for tables this service owns** live at `connectivity/migrations/<db>/`

If a sub-service is added under `scopes/<child>/`, it inherits identity/authority/connectivity from its parent unless `scope.json.inherits` declares otherwise. Children only declare their own deltas.

## No Mocks / No Fake Data / No Placeholder Endpoints (BINDING)

Every endpoint, every test, every PR must validate against real backends. See the global policy in `~/.claude/CLAUDE.md`.

For this service:
- All routes execute real queries against the manifested datastores
- Tests exercise real behavior — no `vi.mock` of DB modules in new tests
- Schema PRs include real-Neon validation evidence in the body
- `npm run certify` must be green before merge

## Canonical Entity Types (P/L/T/E/A — BINDING)

If this service touches entities, all five types apply:
- **P** Person, **L** Location, **T** Thing, **E** Event, **A** Authority
- ChittyID format: `VV-G-LLL-SSSS-T-YM-C-X` where `T` ∈ `{P,L,T,E,A}`
- Source: `chittycanon://gov/governance#core-types`

## Related Services

- **ChittySchema** — Meta-schemas + Owner Manifest. This repo validates against `chittycanon://core/services/chittyschema#meta/fractal-layout`.
- **ChittyRegister** — Service registration. Register this scope via `scope.json`.
- **ChittyCertify** — Compliance certification.
- **ChittyTrack** — Tail consumer for observability.
