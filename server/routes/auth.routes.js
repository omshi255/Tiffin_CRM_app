import { Router } from "express";
import {
  sendOtpController,
  verifyOtpController,
  refreshTokenController,
  logoutController,
  updateMe,
  forgotPasswordController,
  resetPasswordController,
  getMeController,
  changePasswordController,
} from "../controllers/auth.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/send-otp", sendOtpController);
router.post("/verify-otp", verifyOtpController);
router.post("/forgot-password", forgotPasswordController);
router.post("/reset-password", resetPasswordController);
router.post("/refresh-token", refreshTokenController);
router.post("/logout", authMiddleware, logoutController);
router.put("/me", authMiddleware, updateMe);

router.get("/me", authMiddleware, getMeController);
router.put("/change-password", authMiddleware, changePasswordController);

export default router;
