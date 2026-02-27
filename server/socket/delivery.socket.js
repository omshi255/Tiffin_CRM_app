import { verifyAccessToken } from "../services/token.service.js";

/**
 * Initialize the /delivery namespace with JWT auth and room joining.
 * Rooms:
 * - admin:{ownerId}
 * - customer:{customerId}
 * - staff:{staffId}
 * - zone:{zoneId}
 */
export const initDeliverySocket = (io) => {
  const delivery = io.of("/delivery");

  delivery.use((socket, next) => {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.auth?.accessToken ||
      socket.handshake.headers?.authorization?.replace("Bearer ", "");

    if (!token) {
      return next(new Error("Authentication required"));
    }

    try {
      const decoded = verifyAccessToken(token);
      socket.user = decoded;
      next();
    } catch {
      next(new Error("Invalid or expired token"));
    }
  });

  delivery.on("connection", (socket) => {
    const { userId, role, ownerId } = socket.user;

    if (role === "admin") socket.join(`admin:${ownerId || userId}`);
    if (role === "customer") socket.join(`customer:${userId}`);
    if (role === "delivery_boy" || role === "delivery_staff")
      socket.join(`staff:${userId}`);

    socket.on("join_zone", ({ zoneId }) => {
      if (zoneId) socket.join(`zone:${zoneId}`);
    });

    socket.on("leave_zone", ({ zoneId }) => {
      if (zoneId) socket.leave(`zone:${zoneId}`);
    });

    socket.on("location_update", ({ lat, lng, orderId }) => {
      if (typeof lat !== "number" || typeof lng !== "number") {
        socket.emit("location_error", { message: "Invalid lat/lng" });
        return;
      }
      delivery.to(`admin:${ownerId || userId}`).emit("location_update", {
        lat,
        lng,
        orderId,
        userId,
      });
    });
  });
};

