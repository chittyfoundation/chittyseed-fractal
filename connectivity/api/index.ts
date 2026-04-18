/**
 * REPLACE-ME — Cloudflare Worker API entry point.
 *
 * Inbound HTTP surface for this service. Per ChittyOS standard:
 * - GET /health        → liveness, returns {"status":"ok","service":...}
 * - GET /api/v1/status → richer status with dependencies
 *
 * Real endpoints only — no mocks, no placeholders. If a route can't be
 * implemented end-to-end against a real backend right now, defer the route
 * (don't ship a stub).
 */

import { Hono } from 'hono';

interface Env {
  ENVIRONMENT: string;
  SERVICE_NAME: string;
}

const app = new Hono<{ Bindings: Env }>();

app.get('/health', (c) => {
  return c.json({ status: 'ok', service: c.env.SERVICE_NAME });
});

app.get('/api/v1/status', (c) => {
  return c.json({
    status: 'ok',
    service: c.env.SERVICE_NAME,
    environment: c.env.ENVIRONMENT,
    timestamp: new Date().toISOString(),
  });
});

export default app;
