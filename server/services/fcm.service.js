/**
 * @deprecated Push delivery uses OneSignal (onesignal.service.js). Stubs kept for safety.
 */
export const sendPushNotification = async () => {
  console.warn("[FCM] sendPushNotification is deprecated — use OneSignal sendPushToUser");
  return null;
};
