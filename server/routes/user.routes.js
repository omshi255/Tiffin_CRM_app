import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { updateFcmToken } from "../controllers/user.controller.js";

const router = Router();

router.put("/fcm-token", authMiddleware, updateFcmToken);

export default router;
