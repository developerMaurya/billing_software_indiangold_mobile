const mongoose = require('mongoose');

const SaleSchema = new mongoose.Schema({
  shop: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer' }, // Can be null for Guest
  customerName: { type: String, required: true }, // Backup for display
  
  items: [{
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    name: { type: String, required: true },
    quantity: { type: Number, required: true },
    salesRate: { type: Number, required: true },
    gstRate: { type: Number, default: 0 },
    hsnCode: { type: String, default: '3004' },
    total: { type: Number, required: true }
  }],

  
  subtotal: { type: Number, required: true },
  discount: { type: Number, default: 5 }, // Default discount as requested
  gstAmount: { type: Number, default: 0 },
  gstType: { type: String, enum: ['Inclusive', 'Exclusive'], default: 'Inclusive' },
  grandTotal: { type: Number, required: true },
  
  billId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

SaleSchema.index({ shop: 1, billId: 1 }, { unique: true });

module.exports = mongoose.model('Sale', SaleSchema);

