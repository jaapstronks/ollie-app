/**
 * Otis Analytics Worker
 * Cloudflare Worker for collecting app analytics
 */

export interface Env {
  DB: D1Database;
  API_KEY: string;
}

interface EventPayload {
  device_id: string;
  event_name: string;
  event_data?: Record<string, unknown>;
  app_version?: string;
  ios_version?: string;
  device_model?: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Simple API key auth
    const apiKey = request.headers.get('X-API-Key');
    if (apiKey !== env.API_KEY) {
      return new Response('Unauthorized', { status: 401, headers: corsHeaders });
    }

    // POST /events - Log event(s)
    if (url.pathname === '/events' && request.method === 'POST') {
      try {
        const body = await request.json() as EventPayload | EventPayload[];
        const events = Array.isArray(body) ? body : [body];

        const stmt = env.DB.prepare(`
          INSERT INTO events (device_id, event_name, event_data, app_version, ios_version, device_model)
          VALUES (?, ?, ?, ?, ?, ?)
        `);

        const batch = events.map(e => stmt.bind(
          e.device_id,
          e.event_name,
          JSON.stringify(e.event_data || {}),
          e.app_version || null,
          e.ios_version || null,
          e.device_model || null
        ));

        await env.DB.batch(batch);

        return new Response(JSON.stringify({ success: true, count: events.length }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: 'Invalid request' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }

    // GET /stats - Basic stats endpoint
    if (url.pathname === '/stats' && request.method === 'GET') {
      const period = url.searchParams.get('period') || '7d';
      const days = period === '30d' ? 30 : period === '90d' ? 90 : 7;

      const stats = await env.DB.prepare(`
        SELECT
          COUNT(DISTINCT device_id) as unique_devices,
          COUNT(*) as total_events,
          COUNT(CASE WHEN event_name = 'app_launch' THEN 1 END) as launches,
          COUNT(CASE WHEN event_name = 'event_logged' THEN 1 END) as events_logged
        FROM events
        WHERE created_at >= datetime('now', '-' || ? || ' days')
      `).bind(days).first();

      const eventTypes = await env.DB.prepare(`
        SELECT json_extract(event_data, '$.event_type') as event_type, COUNT(*) as count
        FROM events
        WHERE event_name = 'event_logged'
          AND created_at >= datetime('now', '-' || ? || ' days')
        GROUP BY event_type
        ORDER BY count DESC
      `).bind(days).all();

      const dailyLaunches = await env.DB.prepare(`
        SELECT date(created_at) as day, COUNT(DISTINCT device_id) as dau
        FROM events
        WHERE event_name = 'app_launch'
          AND created_at >= datetime('now', '-' || ? || ' days')
        GROUP BY day
        ORDER BY day
      `).bind(days).all();

      return new Response(JSON.stringify({
        period,
        ...stats,
        event_types: eventTypes.results,
        daily_active_users: dailyLaunches.results
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response('Not found', { status: 404, headers: corsHeaders });
  }
};
