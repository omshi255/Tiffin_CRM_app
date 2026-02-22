import { Router } from "express";
import {
  listPayments,
  createPayment,
  createOrder,
} from "../controllers/payment.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();
router.use(authMiddleware);

router.get("/", listPayments);
router.post("/", createPayment);
router.post("/create-order", createOrder);

export default router;
