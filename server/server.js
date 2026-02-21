import express from "express";
import cors from "cors";
import config from "./config/index.js";

import { errorHandler } from "./middleware/errorHandler.js";

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(
  cors({
    origin: config.NODE_ENV === "production" ? process.env.CORS_ORIGIN : "*",
  })
);

app.use("/public", express.static("public"));

app.post("/api/test-body", (req, res) => {
  res.json({ body: req.body });
});

app.use(errorHandler);

export { app };
