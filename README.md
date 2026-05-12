# chittyseed-fractal

> The starter template for every new ChittyOS repo. Use it via **`gh repo create --template CHITTYFOUNDATION/chittyseed-fractal <new-repo-name>`** or the GitHub "Use this template" button.

This template encodes:

- The ChittyOS **Pentad** doc convention (CHARTER + CHITTY + CLAUDE + SECURITY + AGENTS)
- The **fractal trinity** repo layout (identity / authority / connectivity / scopes)
- A signable, contract-bound `SOVEREIGNTY.cert` for identity affirmation
- Pre-wired hookups to all 10 core ChittyOS services
- Workers **service-binding-based** auth (no service tokens)

## What you get

```
identity/        # ChittyID layer       — what this service IS (src, agents, schemas, scripts)
authority/       # ChittyTrust+Cert+Canon — weight
  contracts/     # Bound canonical contracts (AUTH_CONTRACT.md, SECRETS_CONTRACT.md)
connectivity/    # ChittyConnect+Router  — interaction
  api/           # Worker handlers
  integrations/  # Typed accessors for service bindings (chittyauth, chittycanon, bindings.ts)
scopes/          # Nested fractal sub-services (recursive)

CHARTER.md       # Mission, scope, API contract       (Pentad: Charter)
CHITTY.md        # Stack, ecosystem position          (Pentad: Architecture)
CLAUDE.md        # Dev commands + patterns            (Pentad: Developer)
SECURITY.md      # Auth, CORS, sensitive intent       (Pentad: Security)
AGENTS.md        # Agent declarations + orchestrator  (Pentad: Agents)
SOVEREIGNTY.cert # Contract-bound identity affirmation
scope.json       # Repo-as-scope manifest with capability_router + integrations
wrangler.jsonc   # Worker config with services[] bindings + env.staging/production
```

## 10 Hookups (orchestrated by `npm run bootstrap`)

| # | Service | Endpoint | Purpose |
|---|---|---|---|
| 1 | ChittySchema | `schema.chitty.cc` | Validate fractal layout + scope manifest |
| 2 | ChittyCanon | `canon.chitty.cc` | Register canonical URIs (CHARTER/CHITTY/SECURITY/AGENTS + contracts) |
| 3 | ChittyAuth | `auth.chitty.cc` | Issue ChittyID, JWKS for end-user OAuth |
| 4 | ChittyCert | `cert.chitty.cc` | Sign `SOVEREIGNTY_AFFIRMATION` cert |
| 5 | ChittyRegister | `register.chitty.cc` | Register scope into ecosystem |
| 6 | ChittyMarket | (PR-based) | Register capabilities (opt-in via `scope.json`) |
| 7 | Ch1tty | `ch1tty.com` | Register MCP backend (opt-in if service exposes MCP) |
| 8 | ChittyAgent-SDK | `@chittyos/agent-sdk` | Service-local agent toolkit (skip if no agents/) |
| 9 | ChittyTrack | (tail consumer) | Observability tail |
| 10 | ChittyBeacon | (post-deploy) | Deploy state reporting |

## Auth Model: Bindings + Device-Code

- **Service-to-service:** Cloudflare Workers service bindings declared in `wrangler.jsonc` `services[]`. No bearer tokens. The binding is the trust boundary. See `connectivity/integrations/bindings.ts`.
- **End-user:** Ch1tty device-code OAuth flow. JWTs verified edge-side via `jose` against `auth.chitty.cc/.well-known/jwks.json`. See `connectivity/integrations/chittyauth.ts`.
- **Secrets:** Always via the `CHITTYCONNECT` binding. Never env vars, never CLI prompts. See `authority/contracts/SECRETS_CONTRACT.md`.

## Sovereignty: Contract-Bound

`SOVEREIGNTY.cert` is signed by `cert.chitty.cc/api/v1/issue` on bootstrap. The cert is **conditional** — it lists `required_contracts` (AUTH, SECRETS, ontology, fractal layout) and `revocation_conditions` (contract drift, token leak, binding bypass, trust floor breach, beacon silence). ChittyCertify periodically re-verifies; the cert auto-revokes on any contract failure.

## Bootstrap (the `get.chitty.cc` register path)

```bash
# 0. Use as template
gh repo create --template CHITTYFOUNDATION/chittyseed-fractal my-new-service
cd my-new-service

# 1. Resolve REPLACE-ME placeholders
#    Edit: scope.json (name, canon_uri, tier, capability_router)
#          CHARTER.md, CHITTY.md, CLAUDE.md, SECURITY.md, AGENTS.md
#          authority/contracts/AUTH_CONTRACT.md, SECRETS_CONTRACT.md
#          SOVEREIGNTY.cert (entity_data block)
#          wrangler.jsonc (name, routes)

# 2. Install
npm install

# 3. Bootstrap — orchestrates all 10 hookups via device-code OAuth
npm run bootstrap

# 4. Verify
#    - SOVEREIGNTY.cert has issued_at + signature
#    - scope.json registered_with includes "chittyregister"
#    - Open https://get.chitty.cc and search for your service name
```

The bootstrap script handles device-code auth automatically — on first run you'll be prompted to open `https://ch1tty.com/auth/device?code=ABCD-1234` and grant the service authorization. The token is cached locally at `.chitty-bootstrap-token` (gitignored).

## Fractal Compliance

Your repo validates against the fractal-layout meta-schema served at `https://schema.chitty.cc/meta/fractal-layout.schema.json`. The validator (`npm run validate:fractal`) enforces:

- Required root files: `scope.json`, `CHARTER.md`, `CHITTY.md`, `CLAUDE.md`, `SECURITY.md`, `AGENTS.md`, `SOVEREIGNTY.cert`, `README.md`, `package.json`, `tsconfig.json`
- Required root dirs: `identity/`, `authority/`, `connectivity/`, `scopes/`
- Trinity-slot rules: no `api/`/`migrations/`/`integrations/` under `identity/`; no `src/`/`types/`/`validators/`/`agents/` under `connectivity/`
- Each `scopes/<child>/` must have its own valid `scope.json` (recursive validation)

## Inheritance (sub-services)

When you add a sub-service under `scopes/<child>/`, only declare its own deltas. The child's `scope.json` references the parent via `parent_scope_id` and `inherits.{identity,authority,connectivity}` controls which layers are inherited vs. overridden. Default: inherit authority (CHARTER, canon, owners, sovereignty cert lineage), declare your own identity (code, agents) and connectivity (api, migrations).

## Why this layout

The data layer ships a **fractal scopes primitive** in chittyos-core (`scopes` / `scope_parties` / `scope_events` / `scope_artifacts`, self-similar via `parent_scope_id`). This template extends the same shape to the directory layer:

| Data layer | Repo layer |
|---|---|
| `scopes.scope_type` | `scope.json.scope_type` |
| `scope_parties` | `parties/` (folded into `identity/agents` + `authority/owners`) |
| `scope_events` | `connectivity/migrations` + `connectivity/releases` + `connectivity/deployments` |
| `scope_artifacts` | `identity/src` (the things the scope produces) |
| `parent_scope_id` | `scopes/<child>/` nesting + `scope.json.parent_scope_id` |

Discovery is uniform across every ChittyOS repo: `authority/contracts/`, `CHARTER.md`, `connectivity/api/index.ts`, etc.

## Refs

- [chittyschema](https://github.com/chittyfoundation/chittyschema) — schema authority serving the meta-schemas
- [chittymarket](https://github.com/chittyos/chittymarket) — Capability Router (`capability_group` + `execution_class`)
- `chittycanon://gov/governance#core-types` — canonical 5 entity types (P/L/T/E/A)
- `chittycanon://docs/tech/policy/sensitive-intent-contract-v1` — secrets contract
- `chittycanon://docs/tech/policy/chittyos-auth-contract-v1` — auth contract
- `chittycanon://core/services/chittyschema#meta/fractal-layout` — fractal layout contract
- `chittycanon://core/services/chittyschema#meta/repo-scope` — scope manifest contract

## License

MIT
