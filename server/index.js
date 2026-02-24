import { createServer } from "http";
import { Server } from "socket.io";
import { app } from "./server.js";
import dotenv from "dotenv";
import connectMongoDB from "./db/connectMongoDB.js";
import config from "./config/index.js";
import { startDeliveryCron } from "./jobs/deliveryCron.js";
import { startSubscriptionExpiryCron } from "./jobs/subscriptionExpiryCron.js";
import { initDeliverySocket } from "./socket/delivery.socket.js";

dotenv.config({ path: "./config/.env" });

const PORT = config.PORT || 5000;

const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin:
      config.NODE_ENV === "production" ? process.env.CORS_ORIGIN || "*" : "*",
  },
});

app.set("io", io);

connectMongoDB()
  .then(() => {
    startDeliveryCron();
    startSubscriptionExpiryCron();
    initDeliverySocket(io);

    app.on("error", (error) => {
      console.log(`app is not able to connect :: ${error} 😭📉`);
      throw error;
    });

    httpServer.listen(PORT, () => {
      console.log(`app is listening on port :: ${PORT} 💯📈`);
    });
  })
  .catch((error) => {
    console.log(`index.js :: connectDB connection failed  :: ${error} 😭📉`);
  });
