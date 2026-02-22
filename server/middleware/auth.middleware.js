import { verifyAccessToken } from "../services/token.service.js";
import { ApiError } from "../class/apiErrorClass.js";

/**
 * Auth middleware: extract Bearer token, verify JWT, attach req.user = { userId, phone }.
 * On missing/invalid/expired token returns 401 with ApiError.
 */
export const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next(new ApiError(401, "Authorization header missing or invalid"));
  }

  const token = authHeader.slice(7).trim();

  if (!token) {
    return next(new ApiError(401, "Token is required"));
  }

  try {
    const decoded = verifyAccessToken(token);
    req.user = {
      userId: decoded.userId,
      phone: decoded.phone,
    };
    next();
  } catch (err) {
    const message =
      err.name === "TokenExpiredError"
        ? "Token has expired"
        : "Invalid or expired token";
    next(new ApiError(401, message));
  }
};
