const express = require('express');
const router = express.Router();
const Customer = require('../models/Customer');
const { protect } = require('../middleware/authMiddleware');

// Get all customers for a Shop
router.get('/', protect, async (req, res) => {
  try {
    const customers = await Customer.find({ shop: req.shop._id }).sort({ createdAt: -1 });
    res.json(customers);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching customers' });
  }
});

// Create Customer
router.post('/', protect, async (req, res) => {
  try {
    const newCustomer = new Customer({
      ...req.body,
      shop: req.shop._id
    });
    await newCustomer.save();
    res.status(201).json(newCustomer);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Error creating customer' });
  }
});

// Update Customer
router.put('/:id', protect, async (req, res) => {
  try {
    const customer = await Customer.findOneAndUpdate(
      { _id: req.params.id, shop: req.shop._id },
      req.body,
      { new: true }
    );
    res.json(customer);
  } catch (error) {
    res.status(500).json({ message: 'Error updating customer' });
  }
});

// Delete Customer
router.delete('/:id', protect, async (req, res) => {
  try {
    await Customer.findOneAndDelete({ _id: req.params.id, shop: req.shop._id });
    res.json({ message: 'Customer Deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting customer' });
  }
});

module.exports = router;
