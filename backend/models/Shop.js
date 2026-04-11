const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ShopSchema = new mongoose.Schema({
  name: { type: String, required: true },
  entityLegalName: { type: String },
  email: { type: String, required: true, unique: true },

  password: { type: String, required: true },
  about: { type: String },
  address: { type: String },
  pinCode: { type: String },
  gst: { type: String },
  mobile: { type: String },
  logo: { type: String },
  createdAt: { type: Date, default: Date.now }
});

// Hash password before saving
ShopSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Match password
ShopSchema.methods.comparePassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('Shop', ShopSchema);
