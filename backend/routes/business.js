const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

// Simple in-memory storage (replace with MongoDB in production)
const businesses = new Map();

// Signup
router.post('/signup', async (req, res) => {
  try {
    const {
      businessName,
      ownerName,
      email,
      phone,
      password,
      businessType,
      location,
    } = req.body;
    
    // Check if email already exists
    const existingBusiness = Array.from(businesses.values()).find(
      b => b.email === email.toLowerCase()
    );
    
    if (existingBusiness) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create business
    const businessId = uuidv4();
    const business = {
      businessId,
      businessName,
      ownerName,
      email: email.toLowerCase(),
      phone,
      password: hashedPassword,
      businessType,
      location,
      createdAt: new Date(),
    };
    
    businesses.set(businessId, business);
    
    // Generate token
    const token = jwt.sign(
      { businessId, email: business.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '30d' }
    );
    
    // Remove password from response
    const { password: _, ...businessData } = business;
    
    res.status(201).json({
      success: true,
      message: 'Business account created successfully',
      business: businessData,
      token,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Signup failed',
      error: error.message,
    });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find business
    const business = Array.from(businesses.values()).find(
      b => b.email === email.toLowerCase()
    );
    
    if (!business) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }
    
    // Check password
    const isPasswordValid = await bcrypt.compare(password, business.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }
    
    // Generate token
    const token = jwt.sign(
      { businessId: business.businessId, email: business.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '30d' }
    );
    
    // Remove password from response
    const { password: _, ...businessData } = business;
    
    res.json({
      success: true,
      message: 'Login successful',
      business: businessData,
      token,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message,
    });
  }
});

// Get business profile
router.get('/profile/:businessId', (req, res) => {
  try {
    const business = businesses.get(req.params.businessId);
    
    if (!business) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }
    
    // Remove password from response
    const { password: _, ...businessData } = business;
    
    res.json({
      success: true,
      business: businessData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile',
      error: error.message,
    });
  }
});

// Update business profile
router.put('/profile/:businessId', async (req, res) => {
  try {
    const business = businesses.get(req.params.businessId);
    
    if (!business) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }
    
    // Update fields
    const allowedUpdates = ['businessName', 'ownerName', 'phone', 'location'];
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        business[field] = req.body[field];
      }
    });
    
    business.updatedAt = new Date();
    businesses.set(req.params.businessId, business);
    
    // Remove password from response
    const { password: _, ...businessData } = business;
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      business: businessData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: error.message,
    });
  }
});

module.exports = router;
