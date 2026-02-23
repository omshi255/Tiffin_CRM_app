import cron from "node-cron";
import { getTodaysDeliveries } from "../services/delivery.service.js";

/**
 * Cron: run at 00:00 (midnight) daily.
 * Creates Delivery documents for all active subscriptions for today.
 */
const schedule = process.env.DELIVERY_CRON_SCHEDULE || "0 0 * * *"; // 0 0 * * * = midnight every day

export const startDeliveryCron = () => {
  cron.schedule(schedule, async () => {
    try {
      const today = new Date();
      await getTodaysDeliveries(today);
      console.log(`[DeliveryCron] Generated deliveries for ${today.toISOString().slice(0, 10)}`);
    } catch (err) {
      console.error("[DeliveryCron] Error:", err.message);
    }
  });
  console.log(`[DeliveryCron] Scheduled: ${schedule}`);
};
