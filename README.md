# chittyseed-fractal

> The starter template for every new ChittyOS repo. Use it via **`gh repo create --template CHITTYFOUNDATION/chittyseed-fractal <new-repo-name>`** or the GitHub "Use this template" button.

This template encodes the **ChittyOS fractal trinity** layout — identity / authority / connectivity — that mirrors the data-layer scope primitive at the directory level. Every ChittyOS repo (foundation, core, app) is itself a registered scope.

## What you get

```
identity/      # ChittyID layer       — what this service IS
authority/     # ChittyTrust+Cert+Canon — weight (charters, canon, certs, owners)
connectivity/  # ChittyConnect+Router  — interaction (api, integrations, migrations, releases, deployments, consumers, upstreams)
scopes/        # nested fractal sub-services (recursive)
scope.json     # the repo IS a scope — manifest at root
```

Plus:

- `CHARTER.md`, `CHITTY.md`, `CLAUDE.md` at repo root (auto-loaded by Claude Code)
- `package.json` with standard ChittyOS scripts (build, test, lint, certify, validate:fractal)
- `tsconfig.json` with `rootDir: identity/src` + `outDir: identity/dist`
- `wrangler.jsonc` with `main: connectivity/api/index.ts` (delete if not a Worker)
- `.github/workflows/ci.yml` standard ChittyOS CI

## Bootstrap

After cloning your new repo from this template:

```bash
# 1. Edit scope.json — replace REPLACE-ME placeholders with your service name
# 2. Edit CHARTER.md, CHITTY.md, CLAUDE.md — fill in REPLACE-ME blanks
# 3. Install + verify
npm install
npm run validate:fractal     # confirms layout is valid
npm run build                # confirms toolchain is happy

# 4. Register your scope
# Once your scope.json is filled in:
curl -X POST https://register.chitty.cc/api/v1/scopes -H 'Content-Type: application/json' -d @scope.json
```

## Fractal compliance

Your repo must validate against the fractal-layout meta-schema served at `https://schema.chitty.cc/meta/fractal-layout.schema.json`. The validator (`npm run validate:fractal`) walks your repo and enforces:

- Required root files: `scope.json`, `CHARTER.md`, `CHITTY.md`, `CLAUDE.md`, `README.md`, `package.json`, `tsconfig.json`
- Required root dirs: `identity/`, `authority/`, `connectivity/`, `scopes/`
- Trinity-slot rules: no `api/`/`migrations/`/`integrations/` under `identity/`; no `src/`/`types/`/`validators/`/`agents/` under `connectivity/`
- Each `scopes/<child>/` must have its own valid `scope.json` (recursive validation)

## Inheritance (sub-services)

When you add a sub-service under `scopes/<child>/`, only declare its own deltas. The child's `scope.json` references the parent via `parent_scope_id` and `inherits.{identity,authority,connectivity}` controls which layers are inherited vs. overridden. Default behavior: inherit authority (CHARTER, canon, owners), declare your own identity (code, agents) and connectivity (api, migrations).

## Why this layout

The data layer ships a **fractal scopes primitive** in chittyos-core (`scopes` / `scope_parties` / `scope_events` / `scope_artifacts`, self-similar via `parent_scope_id`). This template extends the same shape to the directory layer:

| Data layer | Repo layer |
|---|---|
| `scopes.scope_type` | `scope.json.scope_type` (free text) |
| `scope_parties` | `parties/` (folded into `identity/agents` + `authority/owners`) |
| `scope_events` | `connectivity/migrations` + `connectivity/releases` + `connectivity/deployments` |
| `scope_artifacts` | `identity/src` (the things the scope produces) |
| `parent_scope_id` | `scopes/<child>/` nesting + `scope.json.parent_scope_id` |

Discovery is uniform across every ChittyOS repo: `parties/agents/<service>-overlord.md`, `authority/CHARTER.md`, `connectivity/api/index.ts`, etc.

## Refs

- [chittyschema](https://github.com/chittyfoundation/chittyschema) — the schema authority that serves these meta-schemas
- `chittycanon://gov/governance#core-types` — canonical 5 entity types (P/L/T/E/A)
- `chittycanon://core/services/chittyschema#meta/fractal-layout` — fractal layout contract
- `chittycanon://core/services/chittyschema#meta/repo-scope` — scope manifest contract

## License

MIT
