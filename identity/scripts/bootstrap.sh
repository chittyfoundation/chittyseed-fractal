#!/usr/bin/env bash
# bootstrap.sh — ChittyOS service onboarding orchestrator
#
# The "get.chitty.cc register path": this script orchestrates the 10 hookups
# that take a fresh chittyseed-fractal clone to a fully-registered, certified,
# and discoverable ChittyOS service.
#
# AUTH MODEL: Service-to-service uses Workers service bindings (declared in
# wrangler.jsonc). NO service tokens. This script runs LOCALLY before bindings
# exist, so it uses device-code OAuth through Ch1tty for the one-time
# registration calls. After deploy, all inter-service calls go through bindings.
#
# Step  Hookup          Endpoint                                          Local-auth
# ----  --------------  ------------------------------------------------  ----------
#  1    schema          schema.chitty.cc (validate)                       none (public)
#  2    canon           canon.chitty.cc (register URIs)                   device-code
#  3    auth            auth.chitty.cc (issue ChittyID)                   device-code
#  4    cert            cert.chitty.cc (SOVEREIGNTY_AFFIRMATION)          device-code
#  5    register        register.chitty.cc (scope registration)           device-code
#  6    marketplace     ChittyMarket repo (capability registration)       gh PR (opt-in)
#  7    ch1tty          ch1tty.com (MCP backend registration)             device-code (opt-in)
#  8    agent-sdk       npm install @chittyos/agent-sdk                   none (skip if no agents/)
#  9    chittytrack     wrangler tail_consumer                            validate-only
# 10    chittybeacon    deploy beacon (post-deploy)                       runtime
#
# Usage:
#   npm run bootstrap          # interactive
#   npm run bootstrap -- --dry # dry-run, no remote writes
#   npm run bootstrap -- --ci  # CI mode, fails on any unresolved REPLACE-ME

set -euo pipefail

# ─── Config ─────────────────────────────────────────────────────────────────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCOPE_JSON="${ROOT}/scope.json"
SOVEREIGNTY_CERT="${ROOT}/SOVEREIGNTY.cert"
TOKEN_CACHE="${ROOT}/.chitty-bootstrap-token"

DRY_RUN="false"
CI_MODE="false"
for arg in "$@"; do
  case "$arg" in
    --dry|--dry-run) DRY_RUN="true" ;;
    --ci) CI_MODE="true" ;;
  esac
done

# ─── Helpers ────────────────────────────────────────────────────────────────
log() { printf '\033[36m[bootstrap]\033[0m %s\n' "$*"; }
err() { printf '\033[31m[bootstrap]\033[0m %s\n' "$*" >&2; }
ok()  { printf '\033[32m[bootstrap]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[bootstrap]\033[0m %s\n' "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }
}
require_cmd curl
require_cmd jq
require_cmd npm

# ─── Device-code OAuth (for local CLI bootstrap only) ──────────────────────
acquire_user_token() {
  # Reuse cached token if still valid
  if [[ -f "${TOKEN_CACHE}" ]]; then
    local cached
    cached="$(cat "${TOKEN_CACHE}")"
    # Probe an auth-required endpoint cheaply
    if curl -sS -o /dev/null -w '%{http_code}' --max-time 5 \
         -H "Authorization: Bearer ${cached}" \
         "https://auth.chitty.cc/api/v1/whoami" | grep -q '^2'; then
      echo "${cached}"
      return 0
    fi
    rm -f "${TOKEN_CACHE}"
  fi

  log "No cached token. Starting device-code OAuth..."
  local init
  init=$(curl -sS --max-time 8 -X POST "https://ch1tty.com/auth/device/init" \
    -H 'Content-Type: application/json' \
    -d '{"scopes":["bootstrap:register","bootstrap:canon","bootstrap:cert"]}')
  local code device_code verification_url
  code=$(echo "${init}" | jq -r '.user_code // empty')
  device_code=$(echo "${init}" | jq -r '.device_code // empty')
  verification_url=$(echo "${init}" | jq -r '.verification_url // "https://ch1tty.com/auth/device"')

  if [[ -z "${device_code}" ]]; then
    err "Device-code init failed. Response: ${init}"
    return 1
  fi

  echo
  echo "  ┌──────────────────────────────────────────────────────────┐"
  echo "  │  Open: ${verification_url}"
  echo "  │  Code: ${code}"
  echo "  │  Waiting up to 90s for authorization..."
  echo "  └──────────────────────────────────────────────────────────┘"
  echo

  local i token
  for i in $(seq 1 30); do
    sleep 3
    local resp
    resp=$(curl -sS --max-time 5 -X POST "https://ch1tty.com/auth/device/poll" \
      -H 'Content-Type: application/json' \
      -d "$(jq -n --arg dc "${device_code}" '{device_code:$dc}')")
    token=$(echo "${resp}" | jq -r '.access_token // empty')
    if [[ -n "${token}" ]]; then
      echo "${token}" > "${TOKEN_CACHE}"
      chmod 600 "${TOKEN_CACHE}"
      ok "  Authorized."
      echo "${token}"
      return 0
    fi
  done

  warn "  Device-code timed out. Run: npm run bootstrap:auth to resume."
  return 1
}

# ─── Resolve scope manifest ─────────────────────────────────────────────────
[[ -f "${SCOPE_JSON}" ]] || { err "scope.json not found at ${SCOPE_JSON}"; exit 1; }
SERVICE_NAME=$(jq -r '.name' "${SCOPE_JSON}")
CANON_URI=$(jq -r '.canon_uri' "${SCOPE_JSON}")
TIER=$(jq -r '.tier' "${SCOPE_JSON}")
CAPABILITY_GROUP=$(jq -r '.capability_router.capability_group' "${SCOPE_JSON}")
EXECUTION_CLASS=$(jq -r '.capability_router.execution_class' "${SCOPE_JSON}")

if [[ "${SERVICE_NAME}" == "REPLACE-ME" || "${CANON_URI}" == *REPLACE-ME* ]]; then
  err "scope.json still contains REPLACE-ME placeholders. Fill in service name + canon URI first."
  exit 1
fi

if [[ "${CI_MODE}" == "true" ]]; then
  if grep -rln "REPLACE-ME" "${ROOT}" --include="*.md" --include="*.json" --include="*.ts" 2>/dev/null \
     | grep -v node_modules | grep -v identity/dist; then
    err "REPLACE-ME placeholders still present (CI mode is strict). Resolve them first."
    exit 1
  fi
fi

log "Service: ${SERVICE_NAME}"
log "Canon URI: ${CANON_URI}"
log "Tier: ${TIER}"
log "Capability group: ${CAPABILITY_GROUP} / execution class: ${EXECUTION_CLASS}"
[[ "${DRY_RUN}" == "true" ]] && warn "DRY-RUN — no remote writes"

# ─── 1. ChittySchema — validate fractal layout ──────────────────────────────
log "[1/10] Validating fractal layout against chittyschema..."
if npm run validate:fractal --silent 2>/dev/null; then
  ok "Fractal layout valid"
else
  err "Fractal layout validation failed. Fix structure before re-running."
  exit 1
fi

# Acquire local bootstrap token if not dry-run
TOKEN=""
if [[ "${DRY_RUN}" != "true" ]]; then
  TOKEN=$(acquire_user_token) || { err "Bootstrap requires Ch1tty authorization."; exit 1; }
fi

auth_header() { [[ -n "${TOKEN}" ]] && echo "Authorization: Bearer ${TOKEN}" || echo "X-Skip-Auth: 1"; }

# ─── 2. ChittyCanon — register canonical URIs ───────────────────────────────
log "[2/10] Registering canonical URIs with chittycanon..."
for doc in CHARTER CHITTY SECURITY AGENTS; do
  [[ -f "${ROOT}/${doc}.md" ]] || continue
  uri=$(grep -m1 '^uri:' "${ROOT}/${doc}.md" 2>/dev/null | sed 's/^uri: *//' | tr -d '"')
  [[ -z "${uri}" || "${uri}" == *REPLACE-ME* ]] && { warn "${doc}.md uri unset or REPLACE-ME; skipping"; continue; }
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "  [dry] register ${uri}"
  else
    code=$(curl -sS -o /tmp/canon-resp.json -w '%{http_code}' --max-time 8 \
      -X POST "https://canon.chitty.cc/api/v1/uris/register" \
      -H 'Content-Type: application/json' \
      -H "$(auth_header)" \
      -d "$(jq -n --arg uri "${uri}" --arg doc "${doc}.md" --arg service "${SERVICE_NAME}" \
            '{uri:$uri, source_path:$doc, service:$service}')")
    if [[ "${code}" =~ ^(200|201|409)$ ]]; then ok "  ${uri}"; else warn "  ${uri} → HTTP ${code}"; fi
  fi
done

# Also register the two contract docs
for contract in AUTH_CONTRACT SECRETS_CONTRACT; do
  doc_path="${ROOT}/authority/contracts/${contract}.md"
  [[ -f "${doc_path}" ]] || continue
  uri=$(grep -m1 '^uri:' "${doc_path}" | sed 's/^uri: *//' | tr -d '"')
  [[ "${uri}" == *REPLACE-ME* ]] && continue
  if [[ "${DRY_RUN}" != "true" ]]; then
    curl -sS -o /dev/null --max-time 8 \
      -X POST "https://canon.chitty.cc/api/v1/uris/register" \
      -H 'Content-Type: application/json' \
      -H "$(auth_header)" \
      -d "$(jq -n --arg uri "${uri}" --arg doc "authority/contracts/${contract}.md" --arg s "${SERVICE_NAME}" \
            '{uri:$uri, source_path:$doc, service:$s}')" || warn "  ${contract} registration failed"
    ok "  ${uri}"
  fi
done

# ─── 3. ChittyAuth — resolve ChittyID ───────────────────────────────────────
log "[3/10] Resolving ChittyID via chittyauth..."
CURRENT_CHITTYID=$(jq -r '.chittyid' "${SOVEREIGNTY_CERT}" 2>/dev/null || echo "REPLACE-ME")
if [[ "${CURRENT_CHITTYID}" == "REPLACE-ME" || -z "${CURRENT_CHITTYID}" ]]; then
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "  [dry] would request new ChittyID for ${CANON_URI}"
  else
    resp=$(curl -sS --max-time 10 \
      -X POST "https://auth.chitty.cc/api/v1/chittyid/issue" \
      -H 'Content-Type: application/json' \
      -H "$(auth_header)" \
      -d "$(jq -n --arg uri "${CANON_URI}" --arg name "${SERVICE_NAME}" --argjson tier "${TIER}" \
            '{canonical_uri:$uri, legal_name:$name, tier:$tier, entity_type:"T", organization:"CHITTYFOUNDATION"}')" \
      || echo '{"error":"auth-unavailable"}')
    NEW_CHITTYID=$(echo "${resp}" | jq -r '.chittyid // empty')
    if [[ -n "${NEW_CHITTYID}" ]]; then
      ok "  ChittyID issued: ${NEW_CHITTYID}"
      tmp=$(mktemp)
      jq --arg id "${NEW_CHITTYID}" '.chittyid = $id' "${SOVEREIGNTY_CERT}" > "${tmp}" && mv "${tmp}" "${SOVEREIGNTY_CERT}"
    else
      warn "  ChittyID issuance failed; SOVEREIGNTY.cert remains stub. Response: ${resp}"
    fi
  fi
else
  ok "  Existing ChittyID: ${CURRENT_CHITTYID}"
fi

# ─── 4. ChittyCert — SOVEREIGNTY_AFFIRMATION ────────────────────────────────
log "[4/10] Issuing SOVEREIGNTY_AFFIRMATION via cert.chitty.cc..."
if [[ "${DRY_RUN}" == "true" ]]; then
  log "  [dry] would POST SOVEREIGNTY.cert to cert.chitty.cc/api/v1/issue"
else
  CHITTYID=$(jq -r '.chittyid' "${SOVEREIGNTY_CERT}")
  if [[ "${CHITTYID}" == "REPLACE-ME" ]]; then
    warn "  Skipping cert issuance (no ChittyID yet)"
  else
    resp=$(curl -sS --max-time 15 \
      -X POST "https://cert.chitty.cc/api/v1/issue" \
      -H 'Content-Type: application/json' \
      -d "$(cat "${SOVEREIGNTY_CERT}")" \
      || echo '{"error":"cert-unavailable"}')
    if echo "${resp}" | jq -e '.signature' >/dev/null 2>&1; then
      echo "${resp}" | jq '.' > "${SOVEREIGNTY_CERT}"
      ok "  Sovereignty cert signed and committed"
    else
      err_msg=$(echo "${resp}" | jq -r '.error // "unknown"')
      warn "  Cert issuance failed: ${err_msg}. Stub cert preserved."
    fi
  fi
fi

# ─── 5. ChittyRegister — scope registration ─────────────────────────────────
log "[5/10] Registering scope with chittyregister..."
if [[ "${DRY_RUN}" == "true" ]]; then
  log "  [dry] would POST scope.json to register.chitty.cc/api/v1/scopes"
else
  resp=$(curl -sS --max-time 10 \
    -X POST "https://register.chitty.cc/api/v1/scopes" \
    -H 'Content-Type: application/json' \
    -H "$(auth_header)" \
    -d "@${SCOPE_JSON}" \
    || echo '{"error":"register-unavailable"}')
  if echo "${resp}" | jq -e '.scope_id // .registered' >/dev/null 2>&1; then
    ok "  Scope registered"
    tmp=$(mktemp)
    jq '.registered_with = ((.registered_with // []) + ["chittyregister"] | unique)' "${SCOPE_JSON}" > "${tmp}" && mv "${tmp}" "${SCOPE_JSON}"
  else
    warn "  Registration failed: $(echo "${resp}" | jq -r '.error // "unknown"')"
  fi
fi

# ─── 6. ChittyMarket — capability registration (opt-in, PR-based) ───────────
MARKET_ENABLED=$(jq -r '.integrations.marketplace.enabled' "${SCOPE_JSON}")
if [[ "${MARKET_ENABLED}" == "true" ]]; then
  log "[6/10] ChittyMarket registration..."
  if [[ -f "${ROOT}/capabilities.generated.json" ]]; then
    log "  Marketplace manifest ready. File PR on chittyfoundation/chittymarket."
    log "  Path: capabilities.generated.json (append entries to chittymarket's marketplace.json)"
    ok "  Manifest ready"
  else
    warn "  marketplace.enabled=true but capabilities.generated.json missing. Generate it first."
  fi
else
  log "[6/10] Marketplace registration skipped (integrations.marketplace.enabled=false)"
fi

# ─── 7. Ch1tty — MCP backend registration (opt-in) ──────────────────────────
CH1TTY_ENABLED=$(jq -r '.integrations.ch1tty.enabled' "${SCOPE_JSON}")
if [[ "${CH1TTY_ENABLED}" == "true" ]]; then
  log "[7/10] Registering MCP backend with ch1tty..."
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "  [dry] would POST to ch1tty.com/api/v1/backends"
  else
    resp=$(curl -sS --max-time 10 \
      -X POST "https://ch1tty.com/api/v1/backends" \
      -H 'Content-Type: application/json' \
      -H "$(auth_header)" \
      -d "$(jq -n --arg name "${SERVICE_NAME}" --arg uri "${CANON_URI}" --arg domain "${SERVICE_NAME}.chitty.cc" --arg cg "${CAPABILITY_GROUP}" \
            '{name:$name, canonical_uri:$uri, backend_url:("https://"+$domain+"/mcp"), capability_group:$cg}')" \
      || echo '{"error":"ch1tty-unavailable"}')
    if echo "${resp}" | jq -e '.registered' >/dev/null 2>&1; then
      ok "  Ch1tty backend registered"
    else
      warn "  Ch1tty registration: $(echo "${resp}" | jq -r '.error // "unknown"')"
    fi
  fi
else
  log "[7/10] Ch1tty backend registration skipped (integrations.ch1tty.enabled=false)"
fi

# ─── 8. ChittyAgent-SDK — install (skip if no agents) ───────────────────────
AGENTS_COUNT=$(find "${ROOT}/identity/agents" -maxdepth 1 \( -name "*.md" -o -name "*.yaml" \) 2>/dev/null | wc -l | tr -d ' ')
if [[ "${AGENTS_COUNT}" -gt 0 ]]; then
  log "[8/10] Installing @chittyos/agent-sdk (found ${AGENTS_COUNT} agent definitions)..."
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "  [dry] would npm install @chittyos/agent-sdk + register agents"
  else
    if ! grep -q '"@chittyos/agent-sdk"' "${ROOT}/package.json" 2>/dev/null; then
      npm install @chittyos/agent-sdk --save 2>&1 | tail -3
    fi
    log "  Registering agents with orchestrator (agent.chitty.cc/mcp)..."
    for agent in "${ROOT}/identity/agents/"*.md "${ROOT}/identity/agents/"*.yaml; do
      [[ -f "${agent}" ]] || continue
      curl -sS --max-time 8 \
        -X POST "https://agent.chitty.cc/api/v1/agents/register" \
        -H 'Content-Type: application/json' \
        -H "$(auth_header)" \
        --data-binary "@${agent}" > /dev/null && ok "  Registered: $(basename "${agent}")" || warn "  Failed: $(basename "${agent}")"
    done
  fi
else
  log "[8/10] No agents in identity/agents/; skipping agent-sdk install"
fi

# ─── 9. ChittyTrack — tail consumer (validate) ──────────────────────────────
log "[9/10] Validating chittytrack tail consumer in wrangler.jsonc..."
if grep -q '"chittytrack"' "${ROOT}/wrangler.jsonc" 2>/dev/null; then
  ok "  Tail consumer present"
else
  warn "  wrangler.jsonc missing chittytrack tail_consumer (required for observability)"
fi

# ─── 10. ChittyBeacon — runtime deploy beacon (info only) ───────────────────
log "[10/10] ChittyBeacon hook (runtime — post-deploy)..."
log "  Beacons fire from connectivity/deployments/ after each deploy. No bootstrap action."
log "  Add CHITTYBEACON to wrangler.jsonc services[] when ready to emit."

# ─── Summary ────────────────────────────────────────────────────────────────
echo
ok "Bootstrap complete. Next steps:"
echo "  - Review SOVEREIGNTY.cert to confirm signature landed"
echo "  - Commit any auto-populated files (scope.json registered_with, SOVEREIGNTY.cert)"
echo "  - Open https://get.chitty.cc and search for '${SERVICE_NAME}' to confirm discoverability"
echo "  - Run: npm run deploy:staging"
