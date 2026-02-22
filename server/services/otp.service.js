import Otp from "../models/Otp.model.js";
import config from "../config/index.js";

const OTP_EXPIRY_MINUTES = 10;
const OTP_LENGTH = 6;

/**
 * Generate a 6-digit numeric OTP
 * @returns {string}
 */
const generateOtpCode = () => {
  const min = 10 ** (OTP_LENGTH - 1);
  const max = 10 ** OTP_LENGTH - 1;
  return String(Math.floor(min + Math.random() * (max - min + 1)));
};

/**
 * Send OTP via MSG91 API (control.msg91.com / api.msg91.com)
 * If MSG91_AUTH_KEY is not set (e.g. dev), only save to DB and return success.
 * @param {string} phone - 10-digit Indian mobile number (no country code)
 * @returns {Promise<{ success: boolean, message?: string }>}
 */
export const sendOtp = async (phone) => {
  const trimmedPhone = String(phone)
    .trim()
    .replace(/^\+?91/, "");
  const otpCode = generateOtpCode();
  console.log("otpCode", otpCode);
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // Delete any existing OTP for this phone (one active OTP per phone)
  await Otp.deleteMany({ phone: trimmedPhone });

  await Otp.create({
    phone: trimmedPhone,
    otp: otpCode,
    expiresAt,
  });

  if (config.MSG91_AUTH_KEY && config.MSG91_TEMPLATE_ID) {
    const mobile = `91${trimmedPhone}`;
    const res = await fetch("https://control.msg91.com/api/v5/otp", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        authkey: config.MSG91_AUTH_KEY,
      },
      body: JSON.stringify({
        template_id: config.MSG91_TEMPLATE_ID,
        mobile,
        otp: otpCode,
        otp_expiry: OTP_EXPIRY_MINUTES,
        otp_length: OTP_LENGTH,
      }),
    });

    const data = await res.json().catch(() => ({}));

    if (data.type === "success" || res.ok) {
      return { success: true };
    }
    return {
      success: false,
      message: data.message || data.description || "Failed to send OTP via SMS",
    };
  }

  // Dev: no MSG91 key — OTP saved in DB only (e.g. check DB or use test OTP)
  return { success: true };
};

/**
 * Verify OTP against DB: find by phone, check not expired, compare OTP, delete document.
 * @param {string} phone - 10-digit mobile (no country code)
 * @param {string} otp - 6-digit OTP
 * @returns {Promise<boolean>}
 */
export const verifyOtp = async (phone, otp) => {
  const trimmedPhone = String(phone)
    .trim()
    .replace(/^\+?91/, "");
  const trimmedOtp = String(otp).trim();

  const doc = await Otp.findOne({
    phone: trimmedPhone,
    otp: trimmedOtp,
    expiresAt: { $gt: new Date() },
  });

  if (!doc) {
    return false;
  }

  await Otp.deleteOne({ _id: doc._id });
  return true;
};
