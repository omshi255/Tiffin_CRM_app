import mongoose from "mongoose";

const lineItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    quantity: { type: Number, default: 1, min: 0 },
    unitPrice: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

/**
 * Ledger entries for customer wallet / subscription adjustments (customer details APIs).
 */
const transactionSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
      index: true,
    },
    date: {
      type: Date,
      required: true,
      index: true,
    },
    description: {
      type: String,
      default: "",
      trim: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    type: {
      type: String,
      enum: ["credit", "debit"],
      required: true,
    },
    paymentMode: {
      type: String,
      default: "cash",
      trim: true,
    },
    /** e.g. wallet_topup, extra_charge_separate, extra_charge_subscription */
    source: {
      type: String,
      default: "manual",
      trim: true,
    },
    items: {
      type: [lineItemSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

transactionSchema.index({ customerId: 1, date: -1 });
transactionSchema.index({ ownerId: 1, createdAt: -1 });

const Transaction = mongoose.model("Transaction", transactionSchema);

export default Transaction;
