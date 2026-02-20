import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { dateUtil } from "../utils/index.util.js";

//create logs directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const logsDir = path.join(__dirname, "../logs");

const createLogsDir = async () => {
  try {
    await fs.mkdir(logsDir, { recursive: true });
  } catch (err) {
    console.error("Failed to create logs directory:", err);
  }
};

createLogsDir();

// Define the log file path
const logFilePath = path.join(logsDir, "error.log");

// Added patterns for card numbers, email addresses, phone numbers, and passwords
const sanitizeLogMessage = (message) => {
  const patterns = [
    { regex: /\b\d{12,19}\b/g, replacement: "[REDACTED_CARD]" },
    {
      regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b/g,
      replacement: "[REDACTED_EMAIL]",
    },
    { regex: /\b\d{10}\b/g, replacement: "[REDACTED_PHONE]" },
    {
      regex: /password\s*[:=]\s*["']?([^"'\s]+)/gi,
      replacement: "password: [REDACTED]",
    },
  ];

  let sanitizedMessage = message;
  patterns.forEach(({ regex, replacement }) => {
    sanitizedMessage = sanitizedMessage.replace(regex, replacement);
  });

  return sanitizedMessage;
};

// Write log messages to the file
const logError = async (err) => {
  const dateIST = dateUtil();
  console.log(dateIST);

  const logMessage = `[${dateIST}] ${sanitizeLogMessage(err.message)}\n${err.stack || ""}\n\n`;
  console.error(logMessage);

  try {
    await fs.appendFile(logFilePath, logMessage, { flag: "a" }); // Added append mode flag for safer file writing
  } catch (writeErr) {
    console.error("Failed to write log message to file:", writeErr);
  }
};

// Define the error handler
const errorHandler = (err, req, res, next) => {
  const {
    statusCode = 500,
    message = "Internal Server Error",
    errors = [],
  } = err;

  logError(err);

  const responseMessage =
    process.env.NODE_ENV === "development"
      ? message
      : "An unexpected error occurred."; // Adjusted message for production

  res.status(statusCode).json({
    success: false,
    message: responseMessage,
    ...(errors.length > 0 && { errors }),
    ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
  });
};

export { errorHandler };
