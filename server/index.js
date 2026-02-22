import { app } from "./server.js";
import dotenv from "dotenv";
import connectMongoDB from "./db/connectMongoDB.js";
import config from "./config/index.js";
import { startDeliveryCron } from "./jobs/deliveryCron.js";

dotenv.config({ path: "./config/.env" });

const PORT = config.PORT || 5000;

connectMongoDB()
  .then(() => {
    startDeliveryCron();
    app.on("error", (error) => {
      console.log(`app is not able to connect :: ${error} 😭📉`);
      throw error;
    });
    app.listen(PORT, () => {
      console.log(`app is listening on port :: ${PORT} 💯📈`);
    });
  })
  .catch((error) => {
    console.log(`index.js :: connectDB connection failed  :: ${error} 😭📉`);
  });
