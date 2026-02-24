import cron from "node-cron";
import Subscription from "../models/Subscription.model.js";
import { sendToToken } from "../services/notification.service.js";

export const startSubscriptionExpiryCron = () => {
  cron.schedule("0 1 * * *", async () => {
    try {
      const today = new Date();

      // 1️⃣ Find subscriptions that should expire
      const expiredSubscriptions = await Subscription.find({
        status: "active",
        endDate: { $lt: today },
      }).populate("customerId");

      if (!expiredSubscriptions.length) {
        console.log("No subscriptions to expire.");
        return;
      }

      // 2️⃣ Update status to expired
      await Subscription.updateMany(
        {
          _id: { $in: expiredSubscriptions.map((s) => s._id) },
        },
        { $set: { status: "expired" } }
      );

      console.log(
        `Subscription expiry cron ran. Expired: ${expiredSubscriptions.length}`
      );

      // 3️⃣ Send FCM notifications
      for (const sub of expiredSubscriptions) {
        const customer = sub.customerId;

        if (customer?.fcmToken) {
          await sendToToken(
            customer.fcmToken,
            "Subscription Expired ❌",
            "Your subscription has expired. Please renew to continue service.",
            { type: "subscription_expired" }
          );
        }
      }
    } catch (error) {
      console.error("Subscription expiry cron error:", error.message);
    }
  });
};
