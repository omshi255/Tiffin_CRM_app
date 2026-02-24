import { Router } from "express";
import {
  sendOtpController,
  verifyOtpController,
  refreshTokenController,
  logoutController,
  updateMe,
} from "../controllers/auth.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/send-otp", sendOtpController);
router.post("/verify-otp", verifyOtpController);
router.post("/refresh-token", refreshTokenController);
router.post("/logout", authMiddleware, logoutController);
router.put("/me", authMiddleware, updateMe);

export default router;
