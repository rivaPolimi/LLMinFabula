// Debug mode toggle
const bool DEBUG = false;

// API Endpoints
const String PRODUCTION_API_URL = 'https://llminfabula.onrender.com/api';
const String LOCALHOST_API_URL = 'http://192.168.69.151:8000/api';

const String PRODUCTION_WS_URL = 'wss://llminfabula.onrender.com/ws';
const String LOCALHOST_WS_URL = 'ws://192.168.69.151:8000/ws';

// Get active API endpoint
String getApiUrl() => DEBUG ? LOCALHOST_API_URL : PRODUCTION_API_URL;

// Get active WebSocket endpoint
String getWsUrl() => DEBUG ? LOCALHOST_WS_URL : PRODUCTION_WS_URL;

