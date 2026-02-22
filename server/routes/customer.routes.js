import { Router } from "express";
import {
  listCustomers,
  getCustomerById,
  createCustomer,
  updateCustomer,
} from "../controllers/customer.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = Router();

router.use(authMiddleware);

router.get("/", listCustomers);
router.get("/:id", getCustomerById);
router.post("/", createCustomer);
router.put("/:id", updateCustomer);

export default router;
