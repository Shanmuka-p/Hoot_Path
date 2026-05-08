// proxy_server.js
// Simple local proxy to bypass CORS for Flutter Web testing.
// Run this with: node proxy_server.js
// Then Flutter Web calls localhost:8080 instead of aihoot.in:5001 directly.

const http = require('http');
const https = require('https');

const PORT = 8080;
const TARGET_HOST = 'aihoot.in';
const TARGET_PORT = 5001;

const server = http.createServer((req, res) => {
    // Allow all CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept');

    // Handle preflight
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    console.log(`[Proxy] ${req.method} ${req.url}`);

    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
        const options = {
            hostname: TARGET_HOST,
            port: TARGET_PORT,
            path: req.url,
            method: req.method,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Content-Length': Buffer.byteLength(body),
            },
            rejectUnauthorized: false, // Allow self-signed certs on port 5001
        };

        const proxyReq = https.request(options, (proxyRes) => {
            let data = '';
            proxyRes.on('data', (chunk) => { data += chunk; });
            proxyRes.on('end', () => {
                res.writeHead(proxyRes.statusCode, { 'Content-Type': 'application/json' });
                res.end(data);
                console.log(`[Proxy] Response ${proxyRes.statusCode} for ${req.url}`);
            });
        });

        proxyReq.on('error', (err) => {
            console.error(`[Proxy] Error: ${err.message}`);
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: err.message }));
        });

        proxyReq.write(body);
        proxyReq.end();
    });
});

server.listen(PORT, () => {
    console.log(`✅ Proxy running at http://localhost:${PORT}`);
    console.log(`   Forwarding to https://${TARGET_HOST}:${TARGET_PORT}`);
    console.log(`\n   Now run Flutter Web normally: flutter run -d chrome`);
});