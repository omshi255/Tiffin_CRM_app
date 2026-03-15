import cron from "node-cron";
import User from "../models/User.model.js";
import { generateDailyOrdersForDate } from "../services/dailyOrder.service.js";

const schedule = process.env.DELIVERY_CRON_SCHEDULE || "0 0 * * *";

export const startDeliveryCron = () => {
  cron.schedule(schedule, async () => {
    // Only vendors have subscriptions — filter out customers, delivery staff, admin.
    const owners = await User.find({ role: "vendor", isActive: true })
      .select("_id")
      .lean();

    const daysAhead = 7;

    // Build date range in UTC to avoid local-midnight timezone issues.
    const nowUtc = new Date();
    const todayUtc = new Date(
      Date.UTC(nowUtc.getUTCFullYear(), nowUtc.getUTCMonth(), nowUtc.getUTCDate())
    );

    let succeeded = 0;
    let failed = 0;

    for (const o of owners) {
      for (let i = 0; i < daysAhead; i++) {
        const date = new Date(todayUtc);
        date.setUTCDate(todayUtc.getUTCDate() + i);

        try {
          await generateDailyOrdersForDate(o._id, date);
          succeeded++;
        } catch (err) {
          // One owner/date failure must not abort the remaining owners.
          console.error(
            `[DailyOrderCron] Failed for owner ${o._id} on ${date.toISOString().slice(0, 10)}: ${err.message}`
          );
          failed++;
        }
      }
    }

    console.log(
      `[DailyOrderCron] Done — ${owners.length} vendors × ${daysAhead} days | ok: ${succeeded} | failed: ${failed}`
    );
  });

  console.log(`[DailyOrderCron] Scheduled: ${schedule}`);
};
