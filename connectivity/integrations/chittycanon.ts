/**
 * ChittyCanon — canonical URI registration helper.
 *
 * Used by identity/scripts/bootstrap.sh (via this module) and runtime
 * lookups. Registers chittycanon:// URIs declared in chartered docs
 * (CHARTER.md, CHITTY.md, SECURITY.md, AGENTS.md) with canon.chitty.cc.
 */

const CANON_BASE = 'https://canon.chitty.cc';

export interface CanonURIRegistration {
  uri: string;
  source_path: string;
  service: string;
  metadata?: Record<string, unknown>;
}

export interface CanonRegistrationResult {
  uri: string;
  registered: boolean;
  alreadyExists?: boolean;
  error?: string;
}

/**
 * Register a canonical URI with chittycanon.
 * Idempotent: returning 409 (already registered) is treated as success.
 */
export async function registerCanonURI(
  reg: CanonURIRegistration,
  token: string,
): Promise<CanonRegistrationResult> {
  try {
    const res = await fetch(`${CANON_BASE}/api/v1/uris/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(reg),
    });
    if (res.status === 200 || res.status === 201) {
      return { uri: reg.uri, registered: true };
    }
    if (res.status === 409) {
      return { uri: reg.uri, registered: true, alreadyExists: true };
    }
    const errBody = await res.text().catch(() => '');
    return { uri: reg.uri, registered: false, error: `HTTP ${res.status}: ${errBody}` };
  } catch (err) {
    return {
      uri: reg.uri,
      registered: false,
      error: err instanceof Error ? err.message : 'unknown',
    };
  }
}

/**
 * Resolve a canonical URI to its current metadata.
 * Returns null if the URI is not registered.
 */
export async function resolveCanonURI(uri: string): Promise<Record<string, unknown> | null> {
  const encoded = encodeURIComponent(uri);
  const res = await fetch(`${CANON_BASE}/api/v1/uris/${encoded}`, {
    headers: { Accept: 'application/json' },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`canon resolve failed: HTTP ${res.status}`);
  return (await res.json()) as Record<string, unknown>;
}

/**
 * Validate that a string is a well-formed ChittyCanon URI.
 * Format: chittycanon://<namespace>/<path>[#fragment]
 */
export function isValidCanonURI(uri: string): boolean {
  return /^chittycanon:\/\/[a-z][a-z0-9-]*(?:\/[a-z0-9._-]+)+(?:#.+)?$/i.test(uri);
}
