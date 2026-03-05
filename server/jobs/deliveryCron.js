import cron from "node-cron";
import User from "../models/User.model.js";
import { generateDailyOrdersForDate } from "../services/dailyOrder.service.js";

const schedule = process.env.DELIVERY_CRON_SCHEDULE || "0 0 * * *";

export const startDeliveryCron = () => {
  cron.schedule(schedule, async () => {
    try {
      const owners = await User.find({ isActive: true }).select("_id").lean();

      const daysAhead = 7;

      for (const o of owners) {
        for (let i = 0; i < daysAhead; i++) {
          const date = new Date();
          date.setDate(date.getDate() + i);

          await generateDailyOrdersForDate(o._id, date);
        }
      }

      console.log(
        `[DailyOrderCron] Generated orders for next ${daysAhead} days`
      );
    } catch (err) {
      console.error("[DailyOrderCron] Error:", err.message);
    }
  });

  console.log(`[DailyOrderCron] Scheduled: ${schedule}`);
};
