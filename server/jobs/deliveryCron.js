import cron from "node-cron";
import User from "../models/User.model.js";
import { generateDailyOrdersForDate } from "../services/dailyOrder.service.js";

const schedule = process.env.DELIVERY_CRON_SCHEDULE || "0 0 * * *";

export const startDeliveryCron = () => {
  cron.schedule(schedule, async () => {
    try {
      const today = new Date();
      const owners = await User.find({ isActive: true }).select("_id").lean();

      for (const o of owners) {
        await generateDailyOrdersForDate(o._id, today);
      }

      console.log(
        `[DailyOrderCron] Generated daily orders for ${today
          .toISOString()
          .slice(0, 10)}`
      );
    } catch (err) {
      console.error("[DailyOrderCron] Error:", err.message);
    }
  });
  console.log(`[DailyOrderCron] Scheduled: ${schedule}`);
};
