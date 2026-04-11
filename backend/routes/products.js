const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const { protect } = require('../middleware/authMiddleware');

// Get all products for a Shop
router.get('/', protect, async (req, res) => {
  try {
    const products = await Product.find({ shop: req.shop._id }).sort({ name: 1 });
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching products' });
  }
});

// Create Product
router.post('/', protect, async (req, res) => {
  try {
    const newProduct = new Product({
      ...req.body,
      shop: req.shop._id
    });
    await newProduct.save();
    res.status(201).json(newProduct);
  } catch (error) {
    res.status(500).json({ message: 'Error creating product' });
  }
});

// Update Product
router.put('/:id', protect, async (req, res) => {
  try {
    const product = await Product.findOneAndUpdate(
      { _id: req.params.id, shop: req.shop._id },
      req.body,
      { new: true }
    );
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: 'Error updating product' });
  }
});

// Delete Product
router.delete('/:id', protect, async (req, res) => {
  try {
    await Product.findOneAndDelete({ _id: req.params.id, shop: req.shop._id });
    res.json({ message: 'Product Deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting product' });
  }
});

module.exports = router;
