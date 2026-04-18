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

## Mission

Describe the mission in one paragraph. What does this service do? Who is it for?

## Scope

### IS Responsible For

- Capability 1
- Capability 2

### IS NOT Responsible For

- Out of scope 1
- Out of scope 2

## Dependencies

| Type | Service | Purpose |
|------|---------|---------|
| Upstream | (e.g. ChittyCanon) | (why) |
| Binding | (e.g. ChittyConnect) | (credential resolution) |
| Observability | ChittyTrack | Tail consumer |

## API Contract

### Core Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/v1/status` | GET | Service status |

## Compliance

- [ ] `/health` operational
- [ ] CHARTER.md present (this file)
- [ ] CHITTY.md present
- [ ] CLAUDE.md present
- [ ] scope.json valid against `chittycanon://core/services/chittyschema#meta/repo-scope`
- [ ] Fractal layout valid against `chittycanon://core/services/chittyschema#meta/fractal-layout`
- [ ] Tail consumer configured (chittytrack)
- [ ] Service registered in ChittyRegistry

---
*Charter Version: 0.1.0*
