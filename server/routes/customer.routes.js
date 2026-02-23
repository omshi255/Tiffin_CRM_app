import { Router } from "express";
import rateLimit from "express-rate-limit";
import {
  listCustomers,
  getCustomerById,
  createCustomer,
  updateCustomer,
  bulkCreateCustomers,
  deleteCustomer,
} from "../controllers/customer.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();
router.use(authMiddleware);

const bulkRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { success: false, message: "Too many bulk import attempts, try again later" },
});

router.get("/", listCustomers);
router.get("/:id", getCustomerById);
router.post("/", createCustomer);
router.post("/bulk", bulkRateLimit, bulkCreateCustomers);
router.put("/:id", updateCustomer);
router.delete("/:id", deleteCustomer);

export default router;
