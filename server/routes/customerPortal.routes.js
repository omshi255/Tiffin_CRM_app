import { Router } from "express";
import {
  getMyProfile,
  updateMyProfile,
  getMyActivePlan,
  getMyOrders,
  getMyNotifications,
  markNotificationRead,
} from "../controllers/customerPortal.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/rbac.middleware.js";

const router = Router();

router.use(authMiddleware);
router.use(requireRole(["customer"]));

router.get("/me", getMyProfile);
router.put("/me", updateMyProfile);
router.get("/me/plan", getMyActivePlan);
router.get("/me/orders", getMyOrders);
router.get("/me/notifications", getMyNotifications);
router.patch("/me/notifications/:id/read", markNotificationRead);

export default router;
