import { Router } from "express";
import {
  getMyProfile,
  updateMyProfile,
  getMyActivePlan,
  getMyOrders,
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

export default router;
