/**
 * ChittyOS Service Bindings — typed accessors for Cloudflare Workers
 * service bindings to other ChittyOS services.
 *
 * Service-to-service auth in ChittyOS is binding-based, NOT token-based.
 * Bindings are declared in wrangler.jsonc `services[]` and resolve at deploy
 * time to direct Worker-to-Worker fetch. No bearer tokens cross between
 * services; the binding itself is the trust boundary.
 *
 * To call a bound service:
 *   const res = await c.env.CHITTYCANON.fetch(
 *     new Request('https://internal/api/v1/uris/register', {...})
 *   );
 *
 * The hostname in the Request is ignored — bindings route by binding name.
 */

/**
 * Standard ChittyOS service bindings every chittyseed-fractal service
 * declares in wrangler.jsonc. Make this interface part of your Env type.
 *
 * Example:
 *   interface Env extends ChittyBindings {
 *     ENVIRONMENT: string;
 *     SERVICE_NAME: string;
 *   }
 */
export interface ChittyBindings {
  /** ChittyCanon — canonical URI registry */
  CHITTYCANON: Fetcher;
  /** ChittyAuth — user identity + ChittyID issuance */
  CHITTYAUTH: Fetcher;
  /** ChittyCert — certificate authority (SOVEREIGNTY_AFFIRMATION, X.509) */
  CHITTYCERT: Fetcher;
  /** ChittyRegister — service onboarding registration */
  CHITTYREGISTER: Fetcher;
  /** ChittyConnect — credential vault + connector orchestration */
  CHITTYCONNECT: Fetcher;
  /** ChittySchema — meta-schemas + validation */
  CHITTYSCHEMA: Fetcher;
  /** ChittyTrust — trust score queries */
  CHITTYTRUST: Fetcher;
}

/**
 * Optional bindings — opt-in per service capability.
 */
export interface ChittyOptionalBindings {
  /** Ch1tty MCP aggregator (only if service exposes an MCP backend) */
  CH1TTY?: Fetcher;
  /** ChittyMarket capability registry (only if service exposes capabilities) */
  CHITTYMARKET?: Fetcher;
  /** ChittyAgent Orchestrator (only if service ships agents) */
  CHITTYAGENT_ORCHESTRATOR?: Fetcher;
  /** ChittyBeacon — deploy beacon (firing handled by chittybeacon's tail) */
  CHITTYBEACON?: Fetcher;
}

/**
 * Convenience JSON-RPC-ish wrapper around a binding. Returns parsed JSON
 * or throws with the upstream status. Use this for boilerplate-free
 * inter-service calls.
 */
export async function callBinding<T = unknown>(
  binding: Fetcher,
  path: string,
  init?: RequestInit,
): Promise<T> {
  const url = `https://internal${path}`;
  const res = await binding.fetch(new Request(url, init));
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`binding call ${path} failed: HTTP ${res.status} — ${body}`);
  }
  return (await res.json()) as T;
}
