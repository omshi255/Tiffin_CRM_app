import { getSummaryReport } from "../services/report.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

export const getSummary = asyncHandler(async (req, res) => {
  const { period = "monthly" } = req.query;

  const allowed = ["daily", "weekly", "monthly"];

  if (!allowed.includes(period)) {
    throw new ApiError(400, "Invalid period. Use daily, weekly, monthly.");
  }

  const data = await getSummaryReport(period);

  const response = new ApiResponse(200, "Summary report fetched", data);
  res.status(response.statusCode).json(response);
});
