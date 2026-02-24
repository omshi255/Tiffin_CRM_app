import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { testNotification } from "../controllers/notification.controller.js";

const router = Router();

router.use(authMiddleware);
router.post("/test", testNotification);

export default router;
