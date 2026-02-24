import { Router } from "express";
import config from "../config/index.js";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
} from "../services/index.js";
import authRoutes from "./auth.routes.js";
import customerRoutes from "./customer.routes.js";
import planRoutes from "./plan.routes.js";
import subscriptionRoutes from "./subscription.routes.js";
import deliveryRoutes from "./delivery.routes.js";
import paymentRoutes from "./payment.routes.js";
import { authMiddleware } from "../middleware/auth.middleware.js";
import notificationRoutes from "./notification.routes.js";
import reportRoutes from "./report.routes.js";

const router = Router();

router.use("/auth", authRoutes);
router.use("/customers", customerRoutes);
router.use("/plans", planRoutes);
router.use("/subscriptions", subscriptionRoutes);
router.use("/deliveries", deliveryRoutes);
router.use("/payments", paymentRoutes);
router.use("/notifications", notificationRoutes);
router.use("/reports", reportRoutes);

// Protected route for testing: GET /api/v1/me (requires Authorization: Bearer <token>)
router.get("/me", authMiddleware, (req, res) => {
  res.json({ success: true, data: { user: req.user } });
});

router.post("/test-body", (req, res) => {
  res.json({ body: req.body });
});

// Day 3 Step 5: Token service test — dev only
if (config.NODE_ENV !== "production") {
  router.get("/test-token", (req, res) => {
    const payload = { userId: "test-user-123", phone: "9876543210" };
    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    const decodedAccess = verifyAccessToken(accessToken);
    const decodedRefresh = verifyRefreshToken(refreshToken);

    const payloadMatch =
      decodedAccess.userId === payload.userId &&
      decodedAccess.phone === payload.phone &&
      decodedRefresh.userId === payload.userId &&
      decodedRefresh.phone === payload.phone;

    res.json({
      success: true,
      payloadMatch,
      originalPayload: payload,
      accessToken: accessToken.substring(0, 50) + "...",
      refreshToken: refreshToken.substring(0, 50) + "...",
      decodedAccess: {
        userId: decodedAccess.userId,
        phone: decodedAccess.phone,
        iat: decodedAccess.iat,
        exp: decodedAccess.exp,
      },
      decodedRefresh: {
        userId: decodedRefresh.userId,
        phone: decodedRefresh.phone,
        iat: decodedRefresh.iat,
        exp: decodedRefresh.exp,
      },
    });
  });
}

export default router;
