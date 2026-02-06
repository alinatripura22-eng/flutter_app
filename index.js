const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Root endpoint - Return JSON instead of HTML
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Vibbeo Backend API is running!',
    version: '1.0.0',
    status: 'online',
    database: 'connected',
    endpoints: {
      health: '/health',
      business: '/api/business',
      businessAds: '/api/business-ads'
    },
    documentation: 'API for Vibbeo mobile app'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.get('/api/business', (req, res) => {
  res.json({
    success: true,
    message: 'Business API endpoint',
    data: []
  });
});

app.get('/api/business-ads', (req, res) => {
  res.json({
    success: true,
    message: 'Business Ads API endpoint',
    ads: []
  });
});

app.post('/api/business-ads', (req, res) => {
  res.json({
    success: true,
    message: 'Ad created successfully',
    data: req.body
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
