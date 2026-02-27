import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    // Core business owner fields (from spec)
    businessName: {
      type: String,
      trim: true,
      default: "",
    },
    ownerName: {
      type: String,
      trim: true,
      default: "",
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    email: {
      type: String,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    address: {
      type: String,
      trim: true,
    },
    city: {
      type: String,
      trim: true,
    },
    state: {
      type: String,
      default: "Maharashtra",
      trim: true,
    },
    logoUrl: {
      type: String,
    },
    fcmToken: {
      type: String,
      default: null,
    },
    appVersion: {
      type: String,
    },
    subscriptionPlan: {
      type: String,
      enum: ["free", "basic", "premium"],
      default: "free",
    },
    planExpiresAt: {
      type: Date,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    invoiceCounter: {
      type: Number,
      default: 0,
    },
    settings: {
      timezone: {
        type: String,
        default: "Asia/Kolkata",
      },
      currency: {
        type: String,
        default: "INR",
      },
      orderProcessCutoff: {
        type: String,
        default: "10:00",
      },
      autoGenerateInvoice: {
        type: Boolean,
        default: false,
      },
      whatsappEnabled: {
        type: Boolean,
        default: true,
      },
      emailEnabled: {
        type: Boolean,
        default: false,
      },
      notifyCustomerOnProcess: {
        type: Boolean,
        default: true,
      },
      notifyCustomerOnDelivery: {
        type: Boolean,
        default: true,
      },
    },
    lastLoginAt: {
      type: Date,
    },

    // Existing fields kept for compatibility
    name: {
      type: String,
      trim: true,
    },
    role: {
      type: String,
      enum: ["admin", "delivery", "delivery_staff", "customer"],
      default: "admin",
    },
  },
  {
    timestamps: true,
  }
);

const User = mongoose.model("User", userSchema);

export default User;
