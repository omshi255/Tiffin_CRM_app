import { Router } from "express";
import authRoutes from "./auth.routes.js";
import customerRoutes from "./customer.routes.js";
import planRoutes from "./plan.routes.js";
import subscriptionRoutes from "./subscription.routes.js";
import paymentRoutes from "./payment.routes.js";
import invoiceRoutes from "./invoice.routes.js";
import notificationRoutes from "./notification.routes.js";
import reportRoutes from "./report.routes.js";
import dailyOrderRoutes from "./dailyOrder.routes.js";
import deliveryRoutes from "./delivery.routes.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.use("/auth", authRoutes);
router.use("/customers", customerRoutes);
router.use("/plans", planRoutes);
router.use("/subscriptions", subscriptionRoutes);
router.use("/payments", paymentRoutes);
router.use("/invoices", invoiceRoutes);
router.use("/notifications", notificationRoutes);
router.use("/reports", reportRoutes);
router.use("/daily-orders", dailyOrderRoutes);
router.use("/delivery", deliveryRoutes);

export default router;
