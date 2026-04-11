const express = require('express');
const jwt = require('jsonwebtoken');
const Shop = require('../models/Shop');

const router = express.Router();

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// @route   POST /api/auth/register
// @desc    Register a new shop
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, about, address, pinCode, gst, mobile, logo } = req.body;

    // Check if shop already exists
    const shopExists = await Shop.findOne({ email });
    if (shopExists) {
      return res.status(400).json({ message: 'Shop already exists with this email.' });
    }

    // Create new shop
    const shop = await Shop.create({
      name, email, password, about, address, pinCode, gst, mobile, logo
    });

    if (shop) {
      res.status(201).json({
        _id: shop._id,
        name: shop.name,
        email: shop.email,
        token: generateToken(shop._id)
      });
    } else {
      res.status(400).json({ message: 'Invalid shop data' });
    }
  } catch (error) {
    console.error("REGISTRATION ERROR:", error);
    res.status(500).json({ 
      message: 'Server Error during registration', 
      error: error.message,
      details: error.errors ? Object.values(error.errors).map(e => e.message) : []
    });
  }
});

// @route   POST /api/auth/login
// @desc    Login shop & get token
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const shop = await Shop.findOne({ email });

    if (shop && (await shop.comparePassword(password))) {
      res.json({
        _id: shop._id,
        name: shop.name,
        email: shop.email,
        token: generateToken(shop._id)
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error during login', error: error.message });
  }
});

// Forgot Password (Verify Email + Mobile)
router.post('/forgot-password', async (req, res) => {
  const { email, mobile } = req.body;
  try {
    const shop = await Shop.findOne({ email, mobile });
    if (!shop) return res.status(404).json({ message: 'No account found with this email and mobile.' });
    
    res.json({ message: 'Identity Verified. Proceed to Reset.', shopId: shop._id });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  const { shopId, newPassword } = req.body;
  try {
    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ message: 'User not found' });

    shop.password = newPassword; // The pre-save hook will hash it
    await shop.save();
    res.json({ message: 'Password Updated Successfully! Please Login.' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
});

const { protect } = require('../middleware/authMiddleware');

// @route   GET /api/auth/me (Get shop profile)
router.get('/me', protect, async (req, res) => {
  res.json(req.shop);
});

// @route   PUT /api/auth/profile
// @desc    Update shop profile
router.put('/profile', protect, async (req, res) => {
  try {
    const shop = await Shop.findById(req.shop._id);
    if (shop) {
      shop.name = req.body.name || shop.name;
      shop.entityLegalName = req.body.entityLegalName || shop.entityLegalName;
      shop.email = req.body.email || shop.email;
      shop.address = req.body.address || shop.address;
      shop.gst = req.body.gst || shop.gst;
      shop.about = req.body.about || shop.about;
      shop.pinCode = req.body.pinCode || shop.pinCode;
      shop.mobile = req.body.mobile || shop.mobile;
      shop.logo = req.body.logo || shop.logo;
      
      if (req.body.password) {
        shop.password = req.body.password;
      }

      const updatedShop = await shop.save();
      res.json({
         _id: updatedShop._id,
         name: updatedShop.name,
         entityLegalName: updatedShop.entityLegalName,
         email: updatedShop.email,
         gst: updatedShop.gst,
         address: updatedShop.address,
         about: updatedShop.about,
         pinCode: updatedShop.pinCode,
         mobile: updatedShop.mobile,
         logo: updatedShop.logo
      });

    } else {
      res.status(404).json({ message: 'Shop not found' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error updating profile' });
  }
});

module.exports = router;
