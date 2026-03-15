import admin from "firebase-admin";
import config from "./index.js";

const { FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL } =
  config;

if (!FIREBASE_PROJECT_ID || !FIREBASE_PRIVATE_KEY || !FIREBASE_CLIENT_EMAIL) {
  throw new Error("Missing Firebase environment variables");
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: FIREBASE_PROJECT_ID,
      privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
      clientEmail: FIREBASE_CLIENT_EMAIL,
    }),
  });
}

export default admin;
