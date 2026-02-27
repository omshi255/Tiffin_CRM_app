import { Router } from "express";
import Invoice from "../models/Invoice.model.js";
import Customer from "../models/Customer.model.js";
import { ApiError } from "../class/apiErrorClass.js";
import { asyncHandler } from "../utils/asyncHandler.js";

const router = Router();

router.get("/health", (req, res) => {
  res.json({ status: "ok", version: "4.0" });
});

router.get(
  "/invoice/:shareToken",
  asyncHandler(async (req, res) => {
    const { shareToken } = req.params;
    const invoice = await Invoice.findOne({ shareToken }).lean();
    if (!invoice) throw new ApiError(404, "Invoice not found");
    if (
      invoice.shareTokenExpiresAt &&
      invoice.shareTokenExpiresAt.getTime() < Date.now()
    ) {
      throw new ApiError(410, "TOKEN_EXPIRED");
    }
    res.json(invoice);
  })
);

router.get(
  "/customer-report/:token",
  asyncHandler(async (req, res) => {
    const { token } = req.params;
    const customer = await Customer.findOne({ reportToken: token }).lean();
    if (!customer) throw new ApiError(404, "Customer not found");
    if (
      customer.reportTokenExpiresAt &&
      customer.reportTokenExpiresAt.getTime() < Date.now()
    ) {
      throw new ApiError(410, "TOKEN_EXPIRED");
    }
    res.json(customer);
  })
);

export default router;

