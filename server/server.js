import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import mongoose from "mongoose";

import config from "./config/index.js";
import requestId from "./middleware/requestId.js";
import { errorHandler } from "./middleware/errorHandler.js";
import routes from "./routes/index.js";
import webhookRoutes from "./routes/webhook.routes.js";
import publicRoutes from "./routes/public.routes.js";

const app = express();

app.use(helmet());

app.get("/health", (req, res) => {
  const dbConnected = mongoose.connection.readyState === 1;
  res.status(dbConnected ? 200 : 503).json({
    status: dbConnected ? "ok" : "degraded",
    uptime: process.uptime(),
    db: dbConnected ? "connected" : "disconnected",
  });
});

app.use(rateLimit(config.RATE_LIMIT));

app.use("/api/v1/webhooks", webhookRoutes);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    credentials: false,
  })
);
app.use(requestId);
app.use(morgan("combined"));
app.use("/public", express.static("public"));

const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    success: false,
    message: "Too many auth attempts, try again later",
  },
});

app.use("/api/v1/auth", authRateLimit);
app.use("/api/v1/public", publicRoutes);
app.use("/api/v1", routes);

app.use(errorHandler);

export { app };
