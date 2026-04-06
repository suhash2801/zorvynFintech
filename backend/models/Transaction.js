const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  type: { 
    type: String, 
    required: true, 
    enum: ['income', 'expense'] 
  },
  amount: { 
    type: Number, 
    required: true 
  },
  category: { 
    type: String, 
    default: "General" 
  },
  description: { 
    type: String, 
    default: "No description" // If empty, it shows this instead of "unnamed"
  },
  date: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Transaction', transactionSchema);