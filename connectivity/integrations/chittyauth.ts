/**
 * ChittyAuth — END-USER OAuth validation middleware for Hono.
 *
 * Service-to-service auth in ChittyOS uses **Workers service bindings**
 * (see wrangler.jsonc `services[]`), NOT bearer tokens. This middleware is
 * only for validating end-user OAuth tokens issued by Ch1tty's device-code
 * flow. If your service only handles inter-service traffic (called via
 * binding), you don't need this middleware at all.
 *
 * For user-facing routes:
 *   import { chittyAuth } from './integrations/chittyauth';
 *   app.use('/api/v1/user/*', chittyAuth());
 *
 * For service-binding-only services, omit this middleware entirely.
 */
import type { Context, MiddlewareHandler } from 'hono';
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';

const JWKS_URL = 'https://auth.chitty.cc/.well-known/jwks.json';
const ISSUER = 'https://auth.chitty.cc';

let jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJWKS() {
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(JWKS_URL), {
      cacheMaxAge: 10 * 60 * 1000, // 10 min
      cooldownDuration: 30 * 1000,
    });
  }
  return jwks;
}

export interface ChittyAuthClaims extends JWTPayload {
  chittyid?: string;
  user_id?: string;
  scopes?: string[];
  trust_score?: number;
}

declare module 'hono' {
  interface ContextVariableMap {
    chittyauth: ChittyAuthClaims;
  }
}

/**
 * Hono middleware: validates user OAuth token from Authorization header.
 * Stores verified claims at c.var.chittyauth.
 *
 * Bypasses /health and /api/v1/status (those are always unauthenticated).
 */
export function chittyAuth(
  opts: { audience?: string; required?: boolean } = {},
): MiddlewareHandler {
  const required = opts.required ?? true;
  return async (c, next) => {
    const path = new URL(c.req.url).pathname;
    if (path === '/health' || path === '/api/v1/status') return next();

    const header = c.req.header('Authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';

    if (!token) {
      if (!required) return next();
      return c.json(
        {
          error: 'unauthorized',
          reason: 'missing_user_token',
          authorize_url: 'https://ch1tty.com/auth/device',
        },
        401,
      );
    }

    try {
      const { payload } = await jwtVerify(token, getJWKS(), {
        issuer: ISSUER,
        audience: opts.audience,
      });
      c.set('chittyauth', payload as ChittyAuthClaims);
      return next();
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'verification_failed';
      return c.json({ error: 'unauthorized', reason: msg }, 401);
    }
  };
}

export function getChittyAuth(c: Context): ChittyAuthClaims {
  const claims = c.get('chittyauth') as ChittyAuthClaims | undefined;
  if (!claims) throw new Error('chittyAuth claims not available — was middleware applied?');
  return claims;
}

export function requireScope(scope: string): MiddlewareHandler {
  return async (c, next) => {
    const claims = getChittyAuth(c);
    if (!claims.scopes?.includes(scope)) {
      return c.json({ error: 'forbidden', reason: 'missing_scope', required: scope }, 403);
    }
    return next();
  };
}
