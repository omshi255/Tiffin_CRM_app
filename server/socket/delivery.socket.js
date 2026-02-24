import { verifyAccessToken } from "../services/token.service.js";

const ROOM_DELIVERY_TODAY = "delivery-today";

/**
 * Initialize the /delivery namespace with JWT auth and location_update handling.
 * @param {import("socket.io").Server} io - Socket.io server instance
 */
export const initDeliverySocket = (io) => {
  const deliveryNs = io.of("/delivery");

  deliveryNs.use((socket, next) => {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.auth?.accessToken ||
      socket.handshake.headers?.authorization?.replace("Bearer ", "");

    if (!token) {
      return next(new Error("Authentication required"));
    }

    try {
      const decoded = verifyAccessToken(token);
      socket.user = { userId: decoded.userId, phone: decoded.phone };
      next();
    } catch (err) {
      next(new Error("Invalid or expired token"));
    }
  });

  deliveryNs.on("connection", (socket) => {
    socket.join(ROOM_DELIVERY_TODAY);

    socket.on("location_update", (data) => {
      const { lat, lng } = data || {};
      if (typeof lat !== "number" || typeof lng !== "number") {
        socket.emit("location_error", { message: "Invalid lat/lng" });
        return;
      }
      deliveryNs.to(ROOM_DELIVERY_TODAY).emit("location_updated", {
        userId: socket.user.userId,
        phone: socket.user.phone,
        lat,
        lng,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on("disconnect", () => {
      // leave room handled automatically
    });
  });
};
