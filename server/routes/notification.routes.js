import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/rbac.middleware.js";
import {
  testNotification,
  listMyNotifications,
  markNotificationRead,
} from "../controllers/notification.controller.js";

const router = Router();

router.use(authMiddleware);
router.use(requireRole(["vendor", "admin", "delivery_staff"]));
router.get("/", listMyNotifications);
router.patch("/:id/read", markNotificationRead);
router.post("/test", testNotification);

export default router;
