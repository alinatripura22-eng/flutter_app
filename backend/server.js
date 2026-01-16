const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
const businessRoutes = require('./routes/business');
const businessAdsRoutes = require('./routes/businessAdsSimple');

app.use('/api/business', businessRoutes);
app.use('/api/business-ads', businessAdsRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Vibbeo Business Ads API is running!',
    version: '1.0.0',
    endpoints: {
      business: '/api/business',
      businessAds: '/api/business-ads'
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Business API: http://localhost:${PORT}/api/business`);
  console.log(`✅ Business Ads API: http://localhost:${PORT}/api/business-ads`);
});

module.exports = app;
