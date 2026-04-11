const mongoose = require('mongoose');

const CustomerSchema = new mongoose.Schema({
  shop: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  name: { type: String, required: true },
  address: { type: String },
  mobile: { type: String, required: true },
  email: { type: String },
  gstNumber: { type: String },
  country: { type: String, default: 'India' },
  state: { type: String },
  district: { type: String },
  image: { type: String },

  createdAt: { type: Date, default: Date.now }

});

module.exports = mongoose.model('Customer', CustomerSchema);
