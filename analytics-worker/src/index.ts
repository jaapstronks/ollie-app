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

// Helper functions for table rendering
function renderAppVersionsTable(versions: Array<{ app_version: string; users: number }>): string {
  if (versions.length === 0) return '<div class="empty-state">No data yet</div>';
  const rows = versions.map(v =>
    `<tr><td>${v.app_version || 'Unknown'}</td><td>${v.users}</td></tr>`
  ).join('');
  return `<table><thead><tr><th>Version</th><th>Users</th></tr></thead><tbody>${rows}</tbody></table>`;
}

function renderDeviceModelsTable(models: Array<{ device_model: string; count: number }>): string {
  if (models.length === 0) return '<div class="empty-state">No data yet</div>';
  const rows = models.slice(0, 10).map(d =>
    `<tr><td>${d.device_model || 'Unknown'}</td><td>${d.count}</td></tr>`
  ).join('');
  return `<table><thead><tr><th>Model</th><th>Count</th></tr></thead><tbody>${rows}</tbody></table>`;
}

// Dashboard HTML template
function getDashboardHTML(data: {
  period: string;
  unique_devices: number;
  total_events: number;
  launches: number;
  events_logged: number;
  event_types: Array<{ event_type: string; count: number }>;
  daily_active_users: Array<{ day: string; dau: number }>;
  app_versions: Array<{ app_version: string; users: number }>;
  device_models: Array<{ device_model: string; count: number }>;
}) {
  const dauData = JSON.stringify(data.daily_active_users);
  const eventTypesData = JSON.stringify(data.event_types);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Otis Analytics</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0f0f0f;
      color: #e5e5e5;
      min-height: 100vh;
      padding: 2rem;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 2rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid #2a2a2a;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    .logo svg { width: 32px; height: 32px; }
    h1 { font-size: 1.5rem; font-weight: 600; }
    .period-select {
      background: #1a1a1a;
      border: 1px solid #333;
      color: #e5e5e5;
      padding: 0.5rem 1rem;
      border-radius: 8px;
      font-size: 0.875rem;
      cursor: pointer;
    }
    .metrics {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
      margin-bottom: 2rem;
    }
    .metric-card {
      background: #1a1a1a;
      border: 1px solid #2a2a2a;
      border-radius: 12px;
      padding: 1.5rem;
    }
    .metric-label {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #888;
      margin-bottom: 0.5rem;
    }
    .metric-value {
      font-size: 2rem;
      font-weight: 700;
      color: #fff;
    }
    .charts {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 1rem;
      margin-bottom: 2rem;
    }
    @media (max-width: 768px) {
      .charts { grid-template-columns: 1fr; }
    }
    .chart-card {
      background: #1a1a1a;
      border: 1px solid #2a2a2a;
      border-radius: 12px;
      padding: 1.5rem;
    }
    .chart-title {
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 1rem;
      color: #ccc;
    }
    .chart-container { position: relative; height: 250px; }
    .tables {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1rem;
    }
    .table-card {
      background: #1a1a1a;
      border: 1px solid #2a2a2a;
      border-radius: 12px;
      padding: 1.5rem;
    }
    .table-title {
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 1rem;
      color: #ccc;
    }
    table { width: 100%; border-collapse: collapse; }
    th, td {
      text-align: left;
      padding: 0.75rem 0;
      border-bottom: 1px solid #2a2a2a;
      font-size: 0.875rem;
    }
    th { color: #888; font-weight: 500; }
    td:last-child { text-align: right; font-variant-numeric: tabular-nums; }
    .empty-state {
      color: #666;
      font-style: italic;
      padding: 2rem;
      text-align: center;
    }
    .paw-icon { color: #f97316; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="logo">
        <svg viewBox="0 0 24 24" fill="currentColor" class="paw-icon">
          <path d="M12 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm6-4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zM6 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm3.5-3C8.4 3 7.5 3.9 7.5 5S8.4 7 9.5 7s2-.9 2-2-.9-2-2-2zm5 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm-2.5 9c-2.2 0-4 1.8-4 4v3h8v-3c0-2.2-1.8-4-4-4z"/>
        </svg>
        <h1>Otis Analytics</h1>
      </div>
      <select class="period-select" onchange="window.location.href='/?key=' + new URLSearchParams(window.location.search).get('key') + '&period=' + this.value">
        <option value="7d" ${data.period === '7d' ? 'selected' : ''}>Last 7 days</option>
        <option value="30d" ${data.period === '30d' ? 'selected' : ''}>Last 30 days</option>
        <option value="90d" ${data.period === '90d' ? 'selected' : ''}>Last 90 days</option>
      </select>
    </header>

    <div class="metrics">
      <div class="metric-card">
        <div class="metric-label">Unique Devices</div>
        <div class="metric-value">${data.unique_devices.toLocaleString()}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">App Launches</div>
        <div class="metric-value">${data.launches.toLocaleString()}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Events Logged</div>
        <div class="metric-value">${data.events_logged.toLocaleString()}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Total Events</div>
        <div class="metric-value">${data.total_events.toLocaleString()}</div>
      </div>
    </div>

    <div class="charts">
      <div class="chart-card">
        <div class="chart-title">Daily Active Users</div>
        <div class="chart-container">
          <canvas id="dauChart"></canvas>
        </div>
      </div>
      <div class="chart-card">
        <div class="chart-title">Event Types</div>
        <div class="chart-container">
          <canvas id="eventsChart"></canvas>
        </div>
      </div>
    </div>

    <div class="tables">
      <div class="table-card">
        <div class="table-title">App Versions</div>
        ${renderAppVersionsTable(data.app_versions)}
      </div>
      <div class="table-card">
        <div class="table-title">Device Models</div>
        ${renderDeviceModelsTable(data.device_models)}
      </div>
    </div>
  </div>

  <script>
    const dauData = ${dauData};
    const eventTypesData = ${eventTypesData};

    // DAU Chart
    if (dauData.length > 0) {
      new Chart(document.getElementById('dauChart'), {
        type: 'line',
        data: {
          labels: dauData.map(d => d.day),
          datasets: [{
            label: 'Daily Active Users',
            data: dauData.map(d => d.dau),
            borderColor: '#f97316',
            backgroundColor: 'rgba(249, 115, 22, 0.1)',
            fill: true,
            tension: 0.3,
            pointRadius: 4,
            pointBackgroundColor: '#f97316'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: {
            x: {
              grid: { color: '#2a2a2a' },
              ticks: { color: '#888' }
            },
            y: {
              beginAtZero: true,
              grid: { color: '#2a2a2a' },
              ticks: { color: '#888', stepSize: 1 }
            }
          }
        }
      });
    }

    // Event Types Chart
    if (eventTypesData.length > 0) {
      new Chart(document.getElementById('eventsChart'), {
        type: 'doughnut',
        data: {
          labels: eventTypesData.map(e => e.event_type || 'Unknown'),
          datasets: [{
            data: eventTypesData.map(e => e.count),
            backgroundColor: [
              '#f97316', '#eab308', '#22c55e', '#3b82f6',
              '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16'
            ]
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'right',
              labels: { color: '#888', padding: 12 }
            }
          }
        }
      });
    }
  </script>
</body>
</html>`;
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

    // GET / - Dashboard (requires API key via cookie or query param for simplicity)
    if (url.pathname === '/' && request.method === 'GET') {
      const apiKey = url.searchParams.get('key') || request.headers.get('X-API-Key');
      if (apiKey !== env.API_KEY) {
        return new Response('Unauthorized - add ?key=YOUR_API_KEY to access', {
          status: 401,
          headers: { 'Content-Type': 'text/plain' }
        });
      }

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
      `).bind(days).first() as any;

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

      const appVersions = await env.DB.prepare(`
        SELECT app_version, COUNT(DISTINCT device_id) as users
        FROM events
        WHERE event_name = 'app_launch'
          AND created_at >= datetime('now', '-' || ? || ' days')
        GROUP BY app_version
        ORDER BY users DESC
        LIMIT 10
      `).bind(days).all();

      const deviceModels = await env.DB.prepare(`
        SELECT device_model, COUNT(*) as count
        FROM events
        WHERE created_at >= datetime('now', '-' || ? || ' days')
        GROUP BY device_model
        ORDER BY count DESC
        LIMIT 10
      `).bind(days).all();

      const html = getDashboardHTML({
        period,
        unique_devices: stats?.unique_devices || 0,
        total_events: stats?.total_events || 0,
        launches: stats?.launches || 0,
        events_logged: stats?.events_logged || 0,
        event_types: eventTypes.results as any,
        daily_active_users: dailyLaunches.results as any,
        app_versions: appVersions.results as any,
        device_models: deviceModels.results as any,
      });

      return new Response(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' }
      });
    }

    // API endpoints require API key header
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
