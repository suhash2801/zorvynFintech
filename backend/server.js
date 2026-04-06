const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const Transaction = require('./models/Transaction');

const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

// Logger for debugging
app.use((req, res, next) => {
  console.log(`📡 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

const mongoURI = 'mongodb://127.0.0.1:27017/finance_db';
mongoose.connect(mongoURI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch(err => console.error("❌ Connection Error:", err));

const Goal = mongoose.models.Goal || mongoose.model('Goal', new mongoose.Schema({
  target: { type: Number, default: 50000 }
}));

// --- UPDATED STREAK LOGIC ---
app.get('/streak', async (req, res) => {
  try {
    // Find the single most recent expense
    const lastExpense = await Transaction.findOne({ type: 'expense' }).sort({ date: -1 });
    
    if (!lastExpense) {
      return res.json({ streak: 0, status: "Start your streak! 🌱" });
    }

    const today = new Date();
    const lastDate = new Date(lastExpense.date);

    // CRITICAL: Normalize both dates to midnight in LOCAL time
    today.setHours(0, 0, 0, 0);
    lastDate.setHours(0, 0, 0, 0);

    // 1. If the last expense was TODAY, the streak is BROKEN (0)
    if (today.getTime() === lastDate.getTime()) {
      return res.json({ streak: 0, status: "Spent today! 💸" });
    }

    // 2. Calculate the difference in days
    // If last expense was yesterday, difference is 1 day, so streak is 1.
    const diffTime = Math.abs(today - lastDate);
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    res.json({ streak: diffDays });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- REMAINING ROUTES (Unchanged but included for completeness) ---

app.get('/transactions', async (req, res) => {
  const txs = await Transaction.find().sort({ date: -1 });
  res.json(txs);
});

app.post('/transactions', async (req, res) => {
  try {
    const tx = new Transaction({
      type: req.body.type,
      amount: req.body.amount,
      category: req.body.category || "General",
      description: req.body.description || req.body.desc || "No description",
      date: new Date() // Ensure new transactions get the current timestamp
    });
    await tx.save();
    res.status(201).json(tx);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put('/transactions/:id', async (req, res) => {
  try {
    const updated = await Transaction.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete('/transactions/:id', async (req, res) => {
  await Transaction.findByIdAndDelete(req.params.id);
  res.status(204).send();
});

app.get('/goal', async (req, res) => {
  let goal = await Goal.findOne();
  if (!goal) goal = await Goal.create({ target: 50000 });
  res.json(goal);
});

app.post('/goal', async (req, res) => {
  const goal = await Goal.findOneAndUpdate({}, { target: req.body.target }, { upsert: true, new: true });
  res.json(goal);
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server: http://192.168.0.134:${PORT}`);
});