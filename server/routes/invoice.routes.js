import { Router } from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import {
  listInvoices,
  generateInvoiceForRange,
  getInvoiceById,
  updateInvoice,
  shareInvoice,
  voidInvoice,
  getOverdueInvoices,
} from "../controllers/invoice.controller.js";

const router = Router();

router.use(authMiddleware);

router.get("/", listInvoices);
router.post("/generate", generateInvoiceForRange);
router.get("/overdue", getOverdueInvoices);
router.get("/:id", getInvoiceById);
router.put("/:id", updateInvoice);
router.post("/:id/share", shareInvoice);
router.post("/:id/void", voidInvoice);

export default router;
