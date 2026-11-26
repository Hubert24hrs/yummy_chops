/**
 * The phone number the rider calls about a delivery. Checkout needs one for delivery orders (the API refuses a
 * delivery order without it), fills it in from the saved address, this browser or the account, and remembers it.
 * The app does the same (`mobile/customer/lib/features/cart/contact_phone.dart`).
 */

export const MISSING_PHONE = "Add a phone number so the rider can call you";
export const INVALID_PHONE = "Enter a Nigerian phone number, like 0803 000 0000 or +234 803 000 0000";

const STORAGE_KEY = "gudmeal.contact-phone.v1";

/** Accepts 0803 000 0000, 803 000 0000 or +234 803 000 0000 and returns E.164 (+234…), or null. */
export function normaliseNigerianPhone(input: string | null | undefined): string | null {
  const digits = (input ?? "").replace(/[^\d+]/g, "");
  if (/^\+234[789][01]\d{8}$/.test(digits)) return digits;
  if (/^0[789][01]\d{8}$/.test(digits)) return `+234${digits.slice(1)}`;
  if (/^[789][01]\d{8}$/.test(digits)) return `+234${digits}`;
  return null;
}

/** Why the number cannot be used for a delivery, or null when it can. */
export function phoneProblem(input: string): string | null {
  if (!input.trim()) return MISSING_PHONE;
  return normaliseNigerianPhone(input) ? null : INVALID_PHONE;
}

/** The number used at the last checkout in this browser. */
export function rememberedPhone(): string | null {
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export function rememberPhone(phone: string): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, phone);
  } catch {
    // private window or blocked storage: the saved address still has it
  }
}
