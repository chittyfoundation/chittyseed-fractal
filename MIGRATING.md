# Migrating an Existing Repo to the Fractal Trinity Layout

This guide walks you through restructuring an existing ChittyOS repo to the fractal trinity layout (identity / authority / connectivity / scopes).

> **Reference implementation:** [chittyfoundation/chittyschema PR #17](https://github.com/chittyfoundation/chittyschema/pull/17) — the fractal pilot. Worked example with full move map + tooling lockstep.

## Prerequisites

- Repo currently uses ad-hoc layout (`src/`, `api/`, `scripts/`, `migrations/`, etc.)
- All tests + build pass on `main` (don't refactor a broken repo)
- One reviewer available for the structural PR

## Move map

| From | To |
|---|---|
| `src/` (library code) | `identity/src/` |
| `scripts/` | `identity/scripts/` |
| `schemas/` (JSON Schemas served) | `identity/schemas/` |
| `docs/` | `identity/docs/` |
| `agents/` (subagents) | `identity/agents/` |
| `cli.ts` | `identity/cli.ts` |
| `api/` (Worker handlers) | `connectivity/api/` |
| `integrations/` | `connectivity/integrations/` |
| `migrations/` (SQL) | `connectivity/migrations/` |
| `CHARTER.md`, `CHITTY.md`, `CLAUDE.md`, `README.md` | (keep at repo root) |
| dev-side CLAUDE.md (deeper dev guide) | `authority/DEV_GUIDE.md` |
| `CERTIFICATION.md`, `CHITTYCERT_*` | `authority/certifications/` |
| `SCHEMA_GOVERNANCE.md` | `authority/SCHEMA_GOVERNANCE.md` |
| `DEPLOYMENT.md` | `connectivity/deployments/README.md` |
| `INTEGRATION_GUIDE.md` | `connectivity/integrations/README.md` |
| `database-config.json` (root or nested) | repo root |

## Tooling updates (lockstep — required for build to keep working)

### `package.json`

```jsonc
{
  "main": "identity/dist/index.js",
  "types": "identity/dist/index.d.ts",
  "bin": { "<service>": "./identity/cli.ts" },
  "scripts": {
    "dev": "tsx watch identity/src/index.ts",
    "dev:api": "wrangler dev connectivity/api/index.ts",
    "validate:fractal": "tsx identity/scripts/validate-fractal-layout.ts"
    // ... all script paths point into identity/ or connectivity/
  }
}
```

### `tsconfig.json`

```jsonc
{
  "compilerOptions": {
    "rootDir": "./identity/src",
    "outDir": "./identity/dist",
    "paths": { "@/*": ["identity/src/*"] }
  },
  "include": ["identity/src/**/*"]
}
```

### `wrangler.jsonc`

```jsonc
{
  "main": "connectivity/api/index.ts"
}
```

### CI (`.github/workflows/*.yml`)

- Drop any `working-directory: development/<service>` assumptions
- Update `paths:` filters to new trinity paths
- Update `cache-dependency-path:` to root `package-lock.json`

## Cross-trinity import paths

When code crosses trinity boundaries, paths get longer:

- `connectivity/api/` → `identity/src/`: `import x from '../../../identity/src/...'`
- `connectivity/api/` → repo root `database-config.json`: `import dbConfig from '../../database-config.json'`
- `identity/scripts/` → repo root config: `import dbConfig from '../../database-config.json'`
- `identity/scripts/` → `connectivity/api/`: `import { x } from '../../connectivity/api/lib/...'`

Find these with: `grep -rn "from '\.\./" identity/ connectivity/`

## New files

- `scope.json` at repo root — fractal scope manifest. Get the schema at https://schema.chitty.cc/meta/repo-scope.schema.json
- (optional) `.github/CODEOWNERS` → `authority/owners/CODEOWNERS`

## Verification

```bash
npm install
npm run validate:fractal     # confirms layout is valid
npm run build                # confirms toolchain works
npm run validate:manifest    # if applicable
npx wrangler deploy --dry-run --outdir=.wrangler-test  # if Worker
```

All four must pass. **No mocks** — every endpoint in the diff must execute real queries against a real backend. If something can't be implemented end-to-end right now, defer it.

## Sequencing

1. Make the move map changes (use `git mv` to preserve history per file)
2. Update tooling configs in lockstep
3. Fix relative path imports
4. Add `scope.json` at root
5. Update CLAUDE.md to document the new layout
6. Run `npm run validate:fractal` until clean
7. Run `npm run build` until clean
8. Open PR, verify CI green, merge

## Common gotchas

- **`git mv` into a pre-existing target dir nests** — it places the source as a child. Either don't pre-create the target dir or use `git mv source target.tmp && rmdir target && git mv target.tmp target`.
- **`process.cwd()`-based scripts** that assumed flat `src/` need updating — the `src/` is now `identity/src/`. Update path components, not the CWD assumption.
- **`__dirname`-based imports** generally survive if files moved together (e.g., `cli.ts` → `identity/cli.ts` and `scripts/` → `identity/scripts/` both move under `identity/` so `__dirname/scripts` still works).
- **JSON Schema $schema** — chittyschema's API uses Ajv 2020-12. New meta-schemas must use `https://json-schema.org/draft/2020-12/schema` (not draft-07).

## Sub-services (`scopes/<child>/`)

If your repo contains nested sub-services (e.g., chittyentity/workers/<agent>/), each becomes a child scope under `scopes/`. Each child has its own `scope.json` with `parent_scope_id` referencing the parent, and only declares its own deltas. The parent's authority (CHARTER, canon, owners) is inherited by default.

See [scope.json schema](https://schema.chitty.cc/meta/repo-scope.schema.json) for the `inherits` and `overrides` fields.
