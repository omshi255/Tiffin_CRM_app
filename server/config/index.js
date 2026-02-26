import path from "path";
import dotenv from "dotenv";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, ".env") });

const required = ["MONGODB_URL"];
const optional = {
  PORT: 5000,
  NODE_ENV: "development",
  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || "",
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || "",
  MSG91_AUTH_KEY: process.env.MSG91_AUTH_KEY || "",
  MSG91_TEMPLATE_ID: process.env.MSG91_TEMPLATE_ID || "",
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID || "",
  RAZORPAY_KEY_SECRET: process.env.RAZORPAY_KEY_SECRET || "",
  RAZORPAY_WEBHOOK_SECRET: process.env.RAZORPAY_WEBHOOK_SECRET || "",
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || "",
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY || "",
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || "",
  RATE_LIMIT: {
    windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: Number(process.env.RATE_LIMIT_MAX) || 100,
    message:
      process.env.RATE_LIMIT_MESSAGE ||
      "Too many requests, please try again later.",
  },
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || "",
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || "",
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY || "",
};

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required env: ${key}`);
  }
}

export default {
  PORT: Number(process.env.PORT) || optional.PORT,
  NODE_ENV: process.env.NODE_ENV || optional.NODE_ENV,
  MONGODB_URL: process.env.MONGODB_URL,
  JWT_ACCESS_SECRET:
    process.env.JWT_ACCESS_SECRET || optional.JWT_ACCESS_SECRET,
  JWT_REFRESH_SECRET:
    process.env.JWT_REFRESH_SECRET || optional.JWT_REFRESH_SECRET,
  MSG91_AUTH_KEY: process.env.MSG91_AUTH_KEY || optional.MSG91_AUTH_KEY,
  MSG91_TEMPLATE_ID:
    process.env.MSG91_TEMPLATE_ID || optional.MSG91_TEMPLATE_ID,
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID || optional.RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET:
    process.env.RAZORPAY_KEY_SECRET || optional.RAZORPAY_KEY_SECRET,
  RAZORPAY_WEBHOOK_SECRET:
    process.env.RAZORPAY_WEBHOOK_SECRET || optional.RAZORPAY_WEBHOOK_SECRET,
  FIREBASE_PROJECT_ID:
    process.env.FIREBASE_PROJECT_ID || optional.FIREBASE_PROJECT_ID,
  FIREBASE_PRIVATE_KEY:
    process.env.FIREBASE_PRIVATE_KEY || optional.FIREBASE_PRIVATE_KEY,
  FIREBASE_CLIENT_EMAIL:
    process.env.FIREBASE_CLIENT_EMAIL || optional.FIREBASE_CLIENT_EMAIL,
  RATE_LIMIT: {
    windowMs:
      Number(process.env.RATE_LIMIT_WINDOW_MS) || optional.RATE_LIMIT.windowMs,
    max: Number(process.env.RATE_LIMIT_MAX) || optional.RATE_LIMIT.max,
    message: process.env.RATE_LIMIT_MESSAGE || optional.RATE_LIMIT.message,
  },
};
