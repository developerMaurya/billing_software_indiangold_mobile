const express = require('express');
const router = express.Router();
const Sale = require('../models/Sale');
const Product = require('../models/Product');
const Counter = require('../models/Counter');
const { protect } = require('../middleware/authMiddleware');

// Get all sales (Bill History)
router.get('/', protect, async (req, res) => {
  try {
    const sales = await Sale.find({ shop: req.shop._id })
      .populate('customer') 
      .sort({ createdAt: -1 });
    res.json(sales);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching history' });
  }
});

// Delete Single Sale
router.delete('/:id', protect, async (req, res) => {
  try {
    const sale = await Sale.findOneAndDelete({ _id: req.params.id, shop: req.shop._id });
    if (!sale) return res.status(404).json({ message: 'Sale record not found' });
    res.json({ message: 'Record deleted from history' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting record' });
  }
});

// Bulk Delete Sales
router.post('/bulk-delete', protect, async (req, res) => {
  try {
    const { ids } = req.body;
    if (!ids || (Array.isArray(ids) && ids.length === 0)) return res.status(400).json({ message: 'No records selected' });
    
    await Sale.deleteMany({ _id: { $in: ids }, shop: req.shop._id });
    res.json({ message: 'Selected records deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting records' });
  }
});


// Create Sale (Generate Bill & Reduce Stock)
router.post('/', protect, async (req, res) => {
  const { customerId, customerName, items, subtotal, discount, gstType, gstAmount, grandTotal } = req.body;
  
  try {
    // 1. Generate Unique Bill ID Atomically
    const year = new Date().getFullYear();
    const prefix = `IG-${year}`;
    
    const counter = await Counter.findOneAndUpdate(
      { shop: req.shop._id, prefix: prefix },
      { $inc: { lastValue: 1 } },
      { upsert: true, new: true }
    );

    const billId = `${prefix}-${counter.lastValue.toString().padStart(4, '0')}`;


    // 2. Reduce Stock for each item & Validate
    for (const item of items) {
       const product = await Product.findOneAndUpdate(
         { _id: item.product, shop: req.shop._id, quantity: { $gte: item.quantity } },
         { $inc: { quantity: -item.quantity } },
         { new: true }
       );

       if (!product) {
         return res.status(400).json({ 
           message: `Stock too low or product not found: ${item.name}` 
         });
       }
    }

    // 3. Save the Sale
    const newSale = new Sale({
      shop: req.shop._id,
      customer: customerId || null,
      customerName: customerName,
      items,
      subtotal,
      discount,
      gstType,
      gstAmount,
      grandTotal,
      billId
    });

    await newSale.save();
    res.status(201).json(newSale);

  } catch (error) {
    console.error('Sale Error:', error);
    res.status(500).json({ message: 'Error processing sale/billing' });
  }
});

module.exports = router;
