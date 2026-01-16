const express = require('express');
const router = express.Router();
const { BusinessAd, adsStorage } = require('../models/BusinessAdSimple');
const { v4: uuidv4 } = require('uuid');

// Create new business ad
router.post('/create', async (req, res) => {
  try {
    const adData = {
      ...req.body,
      _id: uuidv4(),
      status: 'pending_review'
    };
    
    const ad = new BusinessAd(adData);
    adsStorage.set(ad._id, ad);
    
    res.status(201).json({
      success: true,
      message: 'Business ad created successfully',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create business ad',
      error: error.message
    });
  }
});

// Get all ads for a business
router.get('/business/:businessId', async (req, res) => {
  try {
    const ads = Array.from(adsStorage.values()).filter(
      ad => ad.businessId === req.params.businessId
    );
    
    res.json({
      success: true,
      ads: ads
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch ads',
      error: error.message
    });
  }
});

// Get ad by ID
router.get('/:adId', async (req, res) => {
  try {
    const ad = adsStorage.get(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    res.json({
      success: true,
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch ad',
      error: error.message
    });
  }
});

// Update ad
router.put('/:adId', async (req, res) => {
  try {
    const ad = await BusinessAd.findByIdAndUpdate(
      req.params.adId,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Ad updated successfully',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update ad',
      error: error.message
    });
  }
});

// Submit ad for review
router.post('/:adId/submit', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    ad.status = 'pending_review';
    await ad.save();
    
    res.json({
      success: true,
      message: 'Ad submitted for review',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit ad',
      error: error.message
    });
  }
});

// Approve ad (admin only)
router.post('/:adId/approve', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    ad.status = 'active';
    await ad.save();
    
    res.json({
      success: true,
      message: 'Ad approved and activated',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to approve ad',
      error: error.message
    });
  }
});

// Reject ad (admin only)
router.post('/:adId/reject', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    ad.status = 'rejected';
    ad.rejectionReason = req.body.reason || 'Does not meet guidelines';
    await ad.save();
    
    res.json({
      success: true,
      message: 'Ad rejected',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to reject ad',
      error: error.message
    });
  }
});

// Pause ad
router.post('/:adId/pause', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    ad.status = 'paused';
    await ad.save();
    
    res.json({
      success: true,
      message: 'Ad paused',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to pause ad',
      error: error.message
    });
  }
});

// Resume ad
router.post('/:adId/resume', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    ad.status = 'active';
    await ad.save();
    
    res.json({
      success: true,
      message: 'Ad resumed',
      ad: ad
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to resume ad',
      error: error.message
    });
  }
});

// Get ads to show (for feed/shorts)
router.post('/serve', async (req, res) => {
  try {
    const {
      placement, // 'feed', 'shorts', 'search', etc.
      userLocation,
      userAge,
      userGender,
      userInterests,
      category,
      limit = 1
    } = req.body;
    
    // Find active ads for this placement
    const now = new Date();
    const ads = await BusinessAd.find({
      status: 'active',
      placements: placement,
      'schedule.startDate': { $lte: now },
      'schedule.endDate': { $gte: now },
      'budget.spent': { $lt: '$budget.total' }
    }).sort({ priority: -1 });
    
    // Filter ads based on targeting
    const eligibleAds = ads.filter(ad => 
      ad.shouldShow(userLocation, userAge, userGender, userInterests)
    );
    
    // Select random ads from eligible ones
    const selectedAds = [];
    const shuffled = eligibleAds.sort(() => 0.5 - Math.random());
    
    for (let i = 0; i < Math.min(limit, shuffled.length); i++) {
      selectedAds.push(shuffled[i]);
      // Record impression
      await shuffled[i].recordImpression();
    }
    
    res.json({
      success: true,
      ads: selectedAds
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to serve ads',
      error: error.message
    });
  }
});

// Record ad click
router.post('/:adId/click', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    await ad.recordClick();
    
    res.json({
      success: true,
      message: 'Click recorded'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to record click',
      error: error.message
    });
  }
});

// Record ad conversion
router.post('/:adId/conversion', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    await ad.recordConversion();
    
    res.json({
      success: true,
      message: 'Conversion recorded'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to record conversion',
      error: error.message
    });
  }
});

// Get ad analytics
router.get('/:adId/analytics', async (req, res) => {
  try {
    const ad = await BusinessAd.findById(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    const analytics = {
      overview: {
        impressions: ad.metrics.impressions,
        clicks: ad.metrics.clicks,
        conversions: ad.metrics.conversions,
        ctr: ad.metrics.ctr.toFixed(2) + '%',
        conversionRate: ad.metrics.conversionRate.toFixed(2) + '%',
        spent: '₹' + ad.budget.spent.toFixed(2),
        remaining: '₹' + (ad.budget.total - ad.budget.spent).toFixed(2)
      },
      dailyStats: ad.dailyStats.map(stat => ({
        date: stat.date.toISOString().split('T')[0],
        impressions: stat.impressions,
        clicks: stat.clicks,
        conversions: stat.conversions,
        spent: '₹' + stat.spent.toFixed(2)
      })),
      performance: {
        avgCPC: ad.metrics.clicks > 0 ? '₹' + (ad.budget.spent / ad.metrics.clicks).toFixed(2) : '₹0',
        avgCPA: ad.metrics.conversions > 0 ? '₹' + (ad.budget.spent / ad.metrics.conversions).toFixed(2) : '₹0',
        roi: ad.metrics.conversions > 0 ? ((ad.metrics.conversions * 100 - ad.budget.spent) / ad.budget.spent * 100).toFixed(2) + '%' : '0%'
      }
    };
    
    res.json({
      success: true,
      analytics: analytics
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch analytics',
      error: error.message
    });
  }
});

// Get all pending ads (admin only)
router.get('/admin/pending', async (req, res) => {
  try {
    const ads = await BusinessAd.find({ status: 'pending_review' })
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      ads: ads
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pending ads',
      error: error.message
    });
  }
});

// Delete ad
router.delete('/:adId', async (req, res) => {
  try {
    const ad = await BusinessAd.findByIdAndDelete(req.params.adId);
    
    if (!ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Ad deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete ad',
      error: error.message
    });
  }
});

module.exports = router;
