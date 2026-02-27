import mongoose from "mongoose";

const deliveryStaffSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      required: true,
    },
    areas: [
      {
        type: String,
      },
    ],
    zones: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Zone",
      },
    ],
    fcmToken: {
      type: String,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    joiningDate: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

const DeliveryStaff = mongoose.model("DeliveryStaff", deliveryStaffSchema);

export default DeliveryStaff;

