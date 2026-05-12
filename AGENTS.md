---
uri: chittycanon://docs/tech/architecture/REPLACE-ME-agents
namespace: chittycanon://docs/tech
type: architecture
version: 0.1.0
status: DRAFT
registered_with: chittycanon://core/services/canon
title: "REPLACE-ME Agents Manifest"
certifier: chittycanon://core/services/chittycertify
visibility: INTERNAL
---

# REPLACE-ME — Agents Manifest

This is the **Agents** vertex of the ChittyOS Pentad. Declares the agents this service exposes, the authority they carry, and how they bind into the broader agent ecosystem.

## Service-Local Agents

Agents specific to this service live in `identity/agents/`. Each agent file (`identity/agents/<name>.md` or `<name>.yaml`) declares:

- `agent_id` — kebab-case slug, also the file basename
- `canonical_uri` — `chittycanon://capability/<group>/<service>.<agent>`
- `capability_group` — JTBD slot per ChittyMarket Capability Router v4 (`build|ship|govern|legal|connect|workspace|local-lab|agent-runtime|market|internal`)
- `execution_class` — `@chitty/{ambient|workspace|connectors|reasoning}`
- `authority` — required `chittyid`, scopes, write boundary
- `runtime_exclusions` — channels that cannot host this agent
- `discovery.verbs` — high-signal intent verbs that route to this agent
- `bindings` — upstream services this agent calls

Initial inventory: REPLACE-ME (e.g., none, or list `agent-name-1`, `agent-name-2`).

## Agent Authority Model

| Authority | Granted When | Revoked When |
|---|---|---|
| `chittyid:read` | Default for any registered agent | Never (read is universal) |
| `<entity-type>:write` | Service charter declares write scope | Charter revoked or trust < threshold |
| `legal:write:case:<id>` | Per-case grant from ChittyTrust + ChittyCertify | Case closed, trust drop, sovereignty cert expired |
| `deploy:*` | Service has `ship` capability_group + non_repudiation_required | trust score drop |
| `governance:*` | Service has `govern` capability_group + ChittyID verified | sovereignty cert revoked |

## Orchestrator Registration

Agents register with the ChittyAgent Orchestrator at `agent.chitty.cc/mcp`. Registration is automatic via `npm run bootstrap` — the bootstrap script POSTs each agent's manifest to:

```
POST https://agent.chitty.cc/api/v1/agents/register
```

After registration, agents become discoverable cross-channel via `skill_search` / `agent_search` calls.

## Ch1tty Backend Registration (BINDING)

If this service exposes an MCP surface, register the backend with Ch1tty rather than authoring local `.mcp.json` configs per consumer:

```bash
npm run register:ch1tty   # registers connectivity/api/index.ts as a Ch1tty backend
```

Centralized registration means Claude, Claude.ai, ChatGPT, Codex, OpenClaw all inherit the backend without per-channel configuration. The `dev:api` script can run a local instance for testing, but production routing always flows through `mcp.chitty.cc/mcp` and `agent.chitty.cc/mcp`.

## Discovery: Slim-MCP Index Injection

Per the Capability Router v4 spec (see `chittycanon://docs/ops/architecture/chittymarket-capability-router`):

- Agents in `capability_group=workspace` and `execution_class=@chitty/ambient` appear in the static SessionStart index served at `agent.chitty.cc/api/v1/capabilities/index?channel=<channel>`
- Other agents are discovered on-demand via slim-MCP `search` + `execute` pattern with Triple-AND broadening when search misses

## Per-Service Agents (Pattern)

```yaml
# identity/agents/example-agent.yaml
agent_id: example-agent
canonical_uri: chittycanon://capability/build/REPLACE-ME.example-agent
capability_group: build
execution_class: "@chitty/workspace"
authority:
  requires_chittyid: true
  write_scope: none
runtime_exclusions:
  claude_ai: [requires_local_filesystem]
  chatgpt: [requires_local_filesystem]
discovery:
  verbs: [refactor, query, review]
  session_index: hidden
  fallback_search: true
bindings:
  upstream:
    - chittycanon://core/services/chittyauth
    - chittycanon://core/services/chittycanon
  downstream:
    - chittyagent-orchestrator
```

## ChittyAgent-Autobot Successor Pattern

Per `chittycanon://docs/tech/architecture/chittyagent-autobot`: long-form autonomous workflows (multi-PR, multi-day) are NOT inline service agents. They are projected onto `chittyagent-autobot` via `chittyagent-dispatch` and run in `agent-runtime` execution class. Reference the parent autobot manifest rather than duplicating logic.

## Refs

- `chittycanon://docs/ops/architecture/chittymarket-capability-router` — Capability Router v4 (JTBD groups + execution classes)
- `chittycanon://core/services/chittyagent-orchestrator` — orchestrator MCP at agent.chitty.cc/mcp
- `chittycanon://core/services/ch1tty` — MCP aggregator at mcp.chitty.cc/mcp
- `chittycanon://docs/tech/architecture/chittyagent-autobot` — autonomous workflow runner
