const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
  shop: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  name: { type: String, required: true },
  hsnCode: { type: String, default: '0000' },
  quantity: { type: Number, required: true, default: 0 },
  purchaseRate: { type: Number, required: true },
  mrp: { type: Number, required: true },
  salesRate: { type: Number, required: true },
  
  // Custom categories requested
  type: { 
    type: String, 
    enum: ['Tablet', 'Injection', 'Bottle', 'Medium', 'Antibiotic', 'All-In-One', 'Other'],
    default: 'Other'
  },
  
  // Units requested
  unit: {
    type: String,
    enum: ['ml', 'mg', 'Bundle', 'Pata', 'Nos', 'Box'],
    default: 'Nos'
  },
  image: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Product', ProductSchema);
