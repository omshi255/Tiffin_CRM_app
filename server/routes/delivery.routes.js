import { Router } from "express";
import { getToday, completeDelivery } from "../controllers/delivery.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();
router.use(authMiddleware);

router.get("/today", getToday);
router.put("/:id/complete", completeDelivery);

export default router;
