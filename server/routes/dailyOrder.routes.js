import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import {
  getToday,
  processToday,
  markDelivered,
  debugOrders,
  generateOrders,
  debugSubscriptions,
  debugMatchForDate,
} from "../controllers/dailyOrder.controller.js";

const router = Router();

router.use(authMiddleware);

router.get("/today", getToday);
router.post("/process", processToday);
router.post("/mark-delivered", markDelivered);
router.post("/generate", generateOrders);
router.get("/debug/subscriptions", debugSubscriptions);
router.get("/debug/subscription/:subscriptionId", debugOrders);
router.get("/debug/match", debugMatchForDate);

export default router;
