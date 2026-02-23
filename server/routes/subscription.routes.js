import { Router } from "express";
import {
  listSubscriptions,
  getSubscriptionById,
  createSubscription,
  renewSubscription,
  cancelSubscription,
} from "../controllers/subscription.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.use(authMiddleware);

router.get("/", listSubscriptions);
router.get("/:id", getSubscriptionById);
router.post("/", createSubscription);
router.put("/:id/renew", renewSubscription);
router.put("/:id/cancel", cancelSubscription);

export default router;
