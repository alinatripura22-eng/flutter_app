const mongoose = require('mongoose');

const businessAdSchema = new mongoose.Schema({
  // Business Information
  businessId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  businessName: {
    type: String,
    required: true,
    trim: true
  },
  businessType: {
    type: String,
    enum: [
      'restaurant', 'retail', 'service', 'education',
      'healthcare', 'real_estate', 'automotive', 'entertainment',
      'beauty', 'fitness', 'technology', 'other'
    ],
    required: true
  },
  ownerName: {
    type: String,
    required: true
  },
  contactEmail: {
    type: String,
    required: true,
    lowercase: true
  },
  contactPhone: {
    type: String,
    required: true
  },
  
  // Ad Content
  adTitle: {
    type: String,
    required: true,
    maxlength: 100
  },
  adDescription: {
    type: String,
    required: true,
    maxlength: 500
  },
  adImage: {
    type: String, // URL to image
    required: true
  },
  adVideo: {
    type: String, // URL to video (optional)
    default: null
  },
  callToAction: {
    type: String,
    enum: [
      'visit_website', 'call_now', 'get_directions',
      'book_now', 'order_now', 'learn_more',
      'shop_now', 'sign_up', 'download'
    ],
    default: 'learn_more'
  },
  websiteUrl: {
    type: String,
    default: null
  },
  
  // Location Targeting
  targetLocations: [{
    city: String,
    state: String,
    country: { type: String, default: 'India' },
    radius: { type: Number, default: 10 } // km
  }],
  
  // Audience Targeting
  targetAudience: {
    ageRange: {
      min: { type: Number, default: 18 },
      max: { type: Number, default: 65 }
    },
    gender: {
      type: String,
      enum: ['all', 'male', 'female', 'other'],
      default: 'all'
    },
    interests: [{
      type: String
    }],
    categories: [{
      type: String
    }]
  },
  
  // Ad Placement
  placements: [{
    type: String,
    enum: [
      'feed', 'shorts', 'search', 'category', 'profile'
    ]
  }],
  
  // Campaign Details
  campaignType: {
    type: String,
    enum: ['cpm', 'cpc', 'cpa', 'fixed'],
    default: 'cpm'
  },
  budget: {
    daily: { type: Number, required: true },
    total: { type: Number, required: true },
    spent: { type: Number, default: 0 }
  },
  pricing: {
    cpm: { type: Number, default: 100 }, // ₹100 per 1000 impressions
    cpc: { type: Number, default: 5 },   // ₹5 per click
    cpa: { type: Number, default: 50 }   // ₹50 per action
  },
  
  // Schedule
  schedule: {
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    timeSlots: [{
      day: {
        type: String,
        enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
      },
      startTime: String, // "09:00"
      endTime: String    // "21:00"
    }]
  },
  
  // Performance Metrics
  metrics: {
    impressions: { type: Number, default: 0 },
    clicks: { type: Number, default: 0 },
    conversions: { type: Number, default: 0 },
    ctr: { type: Number, default: 0 }, // Click-through rate
    conversionRate: { type: Number, default: 0 },
    avgEngagementTime: { type: Number, default: 0 } // seconds
  },
  
  // Status
  status: {
    type: String,
    enum: ['draft', 'pending_review', 'active', 'paused', 'completed', 'rejected'],
    default: 'draft'
  },
  rejectionReason: {
    type: String,
    default: null
  },
  
  // Payment
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  paymentId: {
    type: String,
    default: null
  },
  
  // Priority (for ad serving)
  priority: {
    type: Number,
    default: 1,
    min: 1,
    max: 10
  },
  
  // Analytics
  dailyStats: [{
    date: Date,
    impressions: Number,
    clicks: Number,
    conversions: Number,
    spent: Number
  }]
}, {
  timestamps: true
});

// Indexes for performance
businessAdSchema.index({ status: 1, 'schedule.startDate': 1, 'schedule.endDate': 1 });
businessAdSchema.index({ 'targetLocations.city': 1 });
businessAdSchema.index({ businessType: 1 });
businessAdSchema.index({ priority: -1 });

// Calculate CTR before saving
businessAdSchema.pre('save', function(next) {
  if (this.metrics.impressions > 0) {
    this.metrics.ctr = (this.metrics.clicks / this.metrics.impressions) * 100;
  }
  if (this.metrics.clicks > 0) {
    this.metrics.conversionRate = (this.metrics.conversions / this.metrics.clicks) * 100;
  }
  next();
});

// Method to check if ad should be shown
businessAdSchema.methods.shouldShow = function(userLocation, userAge, userGender, userInterests) {
  // Check status
  if (this.status !== 'active') return false;
  
  // Check budget
  if (this.budget.spent >= this.budget.total) return false;
  
  // Check schedule
  const now = new Date();
  if (now < this.schedule.startDate || now > this.schedule.endDate) return false;
  
  // Check location targeting
  if (this.targetLocations.length > 0) {
    const locationMatch = this.targetLocations.some(loc => 
      loc.city === userLocation.city || loc.state === userLocation.state
    );
    if (!locationMatch) return false;
  }
  
  // Check age targeting
  if (userAge < this.targetAudience.ageRange.min || userAge > this.targetAudience.ageRange.max) {
    return false;
  }
  
  // Check gender targeting
  if (this.targetAudience.gender !== 'all' && this.targetAudience.gender !== userGender) {
    return false;
  }
  
  // Check interests (at least one match)
  if (this.targetAudience.interests.length > 0 && userInterests.length > 0) {
    const interestMatch = this.targetAudience.interests.some(interest => 
      userInterests.includes(interest)
    );
    if (!interestMatch) return false;
  }
  
  return true;
};

// Method to record impression
businessAdSchema.methods.recordImpression = async function() {
  this.metrics.impressions += 1;
  
  // Calculate cost based on campaign type
  if (this.campaignType === 'cpm') {
    this.budget.spent += this.pricing.cpm / 1000;
  }
  
  // Update daily stats
  const today = new Date().toISOString().split('T')[0];
  const todayStats = this.dailyStats.find(stat => 
    stat.date.toISOString().split('T')[0] === today
  );
  
  if (todayStats) {
    todayStats.impressions += 1;
  } else {
    this.dailyStats.push({
      date: new Date(),
      impressions: 1,
      clicks: 0,
      conversions: 0,
      spent: this.pricing.cpm / 1000
    });
  }
  
  await this.save();
};

// Method to record click
businessAdSchema.methods.recordClick = async function() {
  this.metrics.clicks += 1;
  
  // Calculate cost based on campaign type
  if (this.campaignType === 'cpc') {
    this.budget.spent += this.pricing.cpc;
  }
  
  // Update daily stats
  const today = new Date().toISOString().split('T')[0];
  const todayStats = this.dailyStats.find(stat => 
    stat.date.toISOString().split('T')[0] === today
  );
  
  if (todayStats) {
    todayStats.clicks += 1;
    if (this.campaignType === 'cpc') {
      todayStats.spent += this.pricing.cpc;
    }
  }
  
  await this.save();
};

// Method to record conversion
businessAdSchema.methods.recordConversion = async function() {
  this.metrics.conversions += 1;
  
  // Calculate cost based on campaign type
  if (this.campaignType === 'cpa') {
    this.budget.spent += this.pricing.cpa;
  }
  
  // Update daily stats
  const today = new Date().toISOString().split('T')[0];
  const todayStats = this.dailyStats.find(stat => 
    stat.date.toISOString().split('T')[0] === today
  );
  
  if (todayStats) {
    todayStats.conversions += 1;
    if (this.campaignType === 'cpa') {
      todayStats.spent += this.pricing.cpa;
    }
  }
  
  await this.save();
};

module.exports = mongoose.model('BusinessAd', businessAdSchema);
