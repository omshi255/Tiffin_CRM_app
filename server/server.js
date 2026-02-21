import express from "express";

import { errorHandler } from "./middleware/errorHandler.js";

const app = express();

app.use("/public", express.static("public"));

app.use(errorHandler);

export { app };
