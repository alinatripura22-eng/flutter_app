// Simple in-memory storage for business ads
// Replace with MongoDB in production

class BusinessAd {
  constructor(data) {
    this._id = data._id || this.generateId();
    this.businessId = data.businessId;
    this.businessName = data.businessName;
    this.businessType = data.businessType;
    this.ownerName = data.ownerName;
    this.contactEmail = data.contactEmail;
    this.contactPhone = data.contactPhone;
    
    this.adTitle = data.adTitle;
    this.adDescription = data.adDescription;
    this.adImage = data.adImage;
    this.adVideo = data.adVideo || null;
    this.callToAction = data.callToAction || 'learn_more';
    this.websiteUrl = data.websiteUrl || null;
    
    this.targetLocations = data.targetLocations || [];
    this.targetAudience = data.targetAudience || {
      ageRange: { min: 18, max: 65 },
      gender: 'all',
      interests: [],
      categories: []
    };
    
    this.placements = data.placements || ['feed'];
    this.campaignType = data.campaignType || 'cpm';
    this.budget = data.budget || { daily: 0, total: 0, spent: 0 };
    this.pricing = data.pricing || { cpm: 100, cpc: 5, cpa: 50 };
    
    this.schedule = data.schedule || {
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    };
    
    this.metrics = data.metrics || {
      impressions: 0,
      clicks: 0,
      conversions: 0,
      ctr: 0,
      conversionRate: 0
    };
    
    this.status = data.status || 'draft';
    this.paymentStatus = data.paymentStatus || 'pending';
    this.priority = data.priority || 1;
    this.dailyStats = data.dailyStats || [];
    
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }
  
  generateId() {
    return 'ad_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }
  
  shouldShow(userLocation, userAge, userGender, userInterests) {
    if (this.status !== 'active') return false;
    if (this.budget.spent >= this.budget.total) return false;
    
    const now = new Date();
    if (now < new Date(this.schedule.startDate) || now > new Date(this.schedule.endDate)) {
      return false;
    }
    
    if (this.targetLocations.length > 0) {
      const locationMatch = this.targetLocations.some(loc => 
        loc.city === userLocation.city || loc.state === userLocation.state
      );
      if (!locationMatch) return false;
    }
    
    if (userAge < this.targetAudience.ageRange.min || userAge > this.targetAudience.ageRange.max) {
      return false;
    }
    
    if (this.targetAudience.gender !== 'all' && this.targetAudience.gender !== userGender) {
      return false;
    }
    
    return true;
  }
  
  async recordImpression() {
    this.metrics.impressions += 1;
    if (this.campaignType === 'cpm') {
      this.budget.spent += this.pricing.cpm / 1000;
    }
    this.updateDailyStats('impressions');
    return this;
  }
  
  async recordClick() {
    this.metrics.clicks += 1;
    if (this.campaignType === 'cpc') {
      this.budget.spent += this.pricing.cpc;
    }
    this.metrics.ctr = (this.metrics.clicks / this.metrics.impressions) * 100;
    this.updateDailyStats('clicks');
    return this;
  }
  
  async recordConversion() {
    this.metrics.conversions += 1;
    if (this.campaignType === 'cpa') {
      this.budget.spent += this.pricing.cpa;
    }
    this.metrics.conversionRate = (this.metrics.conversions / this.metrics.clicks) * 100;
    this.updateDailyStats('conversions');
    return this;
  }
  
  updateDailyStats(metric) {
    const today = new Date().toISOString().split('T')[0];
    let todayStats = this.dailyStats.find(stat => 
      new Date(stat.date).toISOString().split('T')[0] === today
    );
    
    if (!todayStats) {
      todayStats = {
        date: new Date(),
        impressions: 0,
        clicks: 0,
        conversions: 0,
        spent: 0
      };
      this.dailyStats.push(todayStats);
    }
    
    todayStats[metric] = (todayStats[metric] || 0) + 1;
    
    if (metric === 'impressions' && this.campaignType === 'cpm') {
      todayStats.spent += this.pricing.cpm / 1000;
    } else if (metric === 'clicks' && this.campaignType === 'cpc') {
      todayStats.spent += this.pricing.cpc;
    } else if (metric === 'conversions' && this.campaignType === 'cpa') {
      todayStats.spent += this.pricing.cpa;
    }
  }
}

// In-memory storage
const adsStorage = new Map();

module.exports = {
  BusinessAd,
  adsStorage
};
