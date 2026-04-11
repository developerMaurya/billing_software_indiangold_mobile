const mongoose = require('mongoose');

const CounterSchema = new mongoose.Schema({
  shop: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  prefix: { type: String, required: true },
  lastValue: { type: Number, default: 0 }
});

CounterSchema.index({ shop: 1, prefix: 1 }, { unique: true });

module.exports = mongoose.model('Counter', CounterSchema);
