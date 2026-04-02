/**
 * Wallet helpers. `walletBalance` is canonical; `balance` is legacy fallback.
 * Display values are never negative (business rule).
 */

export function effectiveWallet(customer) {
  if (!customer || typeof customer !== "object") return 0;
  if (customer.walletBalance != null) return Number(customer.walletBalance);
  return Number(customer.balance ?? 0);
}

/** Shown wallet total — floored at zero. */
export function displayWalletBalance(customer) {
  return Math.max(0, effectiveWallet(customer));
}
