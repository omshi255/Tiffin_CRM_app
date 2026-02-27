import mongoose from "mongoose";

const CUSTOMER_STATUSES = ["active", "inactive", "blocked"];

const customerSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      lowercase: true,
      trim: true,
    },
    address: {
      type: String,
      required: true,
      trim: true,
    },
    area: {
      type: String,
      trim: true,
    },
    landmark: {
      type: String,
      trim: true,
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
    photoUrl: {
      type: String,
    },
    notes: {
      type: String,
    },
    tags: [
      {
        type: String,
      },
    ],
    customerCode: {
      type: String, // Auto: C001, C002...
    },
    status: {
      type: String,
      enum: CUSTOMER_STATUSES,
      default: "active",
    },
    balance: {
      type: Number,
      default: 0,
    },
    creditLimit: {
      type: Number,
      default: 0,
    },
    totalDue: {
      type: Number,
      default: 0,
    },
    fcmToken: {
      type: String,
      default: null,
    },
    portalEnabled: {
      type: Boolean,
      default: true,
    },
    reportToken: {
      type: String,
    },
    reportTokenExpiresAt: {
      type: Date,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
    deletedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

customerSchema.index({ ownerId: 1, phone: 1 });
customerSchema.index({ location: "2dsphere" });
customerSchema.index({ status: 1 });
customerSchema.index({ createdAt: -1 });
customerSchema.index({ isDeleted: 1 });

const Customer = mongoose.model("Customer", customerSchema);

export default Customer;
export { CUSTOMER_STATUSES };
