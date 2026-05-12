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
│   ├── contracts/            # bound canonical contracts (AUTH, SECRETS)
│   └── owners/               # CODEOWNERS, governance
│
├── connectivity/             # ChittyConnect + ChittyRouter — interaction
│   ├── api/                  # inbound endpoints (Worker handlers)
│   ├── integrations/         # typed bindings + chittyauth/chittycanon helpers
│   ├── migrations/           # SQL per database
│   ├── releases/             # CHANGELOG, version tags
│   ├── deployments/          # deploy logs, beacon reports
│   ├── consumers/            # populated from Owner Manifest
│   └── upstreams/            # dependency declarations
│
├── scopes/                   # recursive fractal sub-services (each is a child scope)
│
├── scope.json                # fractal scope manifest at repo root
├── CHARTER.md                # Pentad: charter
├── CHITTY.md                 # Pentad: architecture
├── CLAUDE.md                 # Pentad: developer (this file)
├── SECURITY.md               # Pentad: security
├── AGENTS.md                 # Pentad: agents
├── SOVEREIGNTY.cert          # Contract-bound identity affirmation
├── package.json
├── tsconfig.json
└── wrangler.jsonc            # Worker config with services[] bindings
```

## Common Commands

```bash
npm install              # Install dependencies
npm run build            # tsc + tsc-alias → identity/dist
npm run dev              # tsx watch identity/src/index.ts
npm run dev:api          # wrangler dev on connectivity/api/index.ts
npm run deploy           # wrangler deploy (production)
npm run deploy:staging   # wrangler deploy --env staging
npm test                 # vitest run
npm run lint             # eslint identity/src connectivity
npm run typecheck        # tsc --noEmit
```

### Bootstrap (the get.chitty.cc register path)

```bash
npm run bootstrap        # orchestrate all 10 hookups via device-code OAuth
npm run bootstrap:dry    # dry-run (no remote writes)
npm run bootstrap:ci     # CI mode (fails if any REPLACE-ME remains)
```

The bootstrap script handles: schema validation → canon URI registration → ChittyID issuance → SOVEREIGNTY_AFFIRMATION signing → scope registration → optional ChittyMarket/Ch1tty registration → agent-sdk install → chittytrack/chittybeacon verification.

### Fractal compliance

```bash
npm run validate:fractal   # Validate this repo against fractal-layout meta-schema
npm run validate:contracts # Verify required contracts present + hashes recorded
npm run certify            # Run ChittySchema service-compliance certification
```

## Pentad Convention

The Pentad is the canonical 5-doc set at repo root:

- `CHARTER.md` — mission, scope, API contract
- `CHITTY.md` — architecture, stack, ecosystem position
- `CLAUDE.md` — this file: dev commands + patterns
- `SECURITY.md` — auth (bindings + device-code), CORS, sensitive intent
- `AGENTS.md` — service-local agents + orchestrator binding

Plus the identity affirmation: `SOVEREIGNTY.cert` (signed by `cert.chitty.cc`, contract-bound).

Contract attestations live at `authority/contracts/`:

- `AUTH_CONTRACT.md` — binding-based service auth + Ch1tty device-code user OAuth
- `SECRETS_CONTRACT.md` — no-secrets-in-chat, ChittyConnect-vaulted

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

## Service Bindings (BINDING — service-to-service auth)

ChittyOS uses Cloudflare Workers service bindings for inter-service auth. NO service tokens. Required bindings declared in `wrangler.jsonc` `services[]`:

| Binding | Service | Purpose |
|---|---|---|
| `CHITTYCANON` | chittycanon | Canonical URI registry |
| `CHITTYAUTH` | chittyauth | User identity + JWKS |
| `CHITTYCERT` | chittycert | Sovereignty affirmation |
| `CHITTYREGISTER` | chittyregister | Scope registration |
| `CHITTYCONNECT` | chittyconnect | Credential vault |
| `CHITTYSCHEMA` | chittyschema | Meta-schema validation |
| `CHITTYTRUST` | chittytrust | Trust score queries |

Optional (uncomment in wrangler.jsonc when needed): `CH1TTY`, `CHITTYMARKET`, `CHITTYAGENT_ORCHESTRATOR`, `CHITTYBEACON`.

Call via typed accessor in `connectivity/integrations/bindings.ts`:

```ts
import { callBinding } from './integrations/bindings';
const meta = await callBinding(c.env.CHITTYCANON, '/api/v1/uris/REPLACE-ME');
```

## Related Services

- **ChittySchema** — Meta-schemas + Owner Manifest. This repo validates against `chittycanon://core/services/chittyschema#meta/fractal-layout`.
- **ChittyRegister** — Service registration. Register this scope via `scope.json` (handled by `npm run bootstrap`).
- **ChittyCertify** — Compliance certification badges (Compatible → Compliant → Certified → Canonical).
- **ChittyCert** — Certificate authority. Signs `SOVEREIGNTY.cert`.
- **ChittyAuth** — User identity + ChittyID issuance + JWKS for edge JWT verification.
- **ChittyConnect** — Credential vault. All secrets retrieved at runtime via `CHITTYCONNECT` binding.
- **ChittyTrack** — Tail consumer for observability.
- **ChittyBeacon** — Deploy state reporting.
- **ChittyMarket** — Capability Router. Registers `capability_group` + `execution_class` for cross-channel discovery.
- **Ch1tty** — MCP aggregator. Centralized backend registration for cross-channel availability.
