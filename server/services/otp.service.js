import twilio from "twilio";
import config from "../config/index.js";

const client = twilio(config.TWILIO_ACCOUNT_SID, config.TWILIO_AUTH_TOKEN);

/**
 * Send OTP using Twilio Verify
 */
export const sendOtp = async (phone) => {
  try {
    const formattedPhone = `+91${String(phone).replace(/^\+?91/, "")}`;

    await client.verify.v2
      .services(config.TWILIO_SERVICE_SID)
      .verifications.create({
        to: formattedPhone,
        channel: "sms",
      });

    return { success: true };
  } catch (error) {
    return {
      success: false,
      message: error.message,
    };
  }
};

/**
 * Verify OTP using Twilio Verify
 */
export const verifyOtp = async (phone, otp) => {
  try {
    const formattedPhone = `+91${String(phone).replace(/^\+?91/, "")}`;

    const response = await client.verify.v2
      .services(config.TWILIO_SERVICE_SID)
      .verificationChecks.create({
        to: formattedPhone,
        code: otp,
      });

    return response.status === "approved";
  } catch (error) {
    return false;
  }
};
