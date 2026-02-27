// HTTP shim for delivery-related endpoints. Core logic lives in dailyOrder.controller.js
import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { getToday } from "../controllers/dailyOrder.controller.js";

const router = Router();

router.use(authMiddleware);

// GET /api/v1/delivery -> today's delivery list (same as /daily-orders/today)
router.get("/", getToday);

export default router;
