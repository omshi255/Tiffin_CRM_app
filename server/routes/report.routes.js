import { Router } from "express";
import { getSummary } from "../controllers/report.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.use(authMiddleware);

router.get("/summary", getSummary);

export default router;
