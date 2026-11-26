import { describe, expect, it } from "vitest";
import { INVALID_PHONE, MISSING_PHONE, normaliseNigerianPhone, phoneProblem } from "./contact-phone";

describe("normaliseNigerianPhone", () => {
  it("accepts the usual ways of writing a Nigerian mobile number", () => {
    for (const input of ["0803 123 4567", "803-123-4567", "+234 803 123 4567", "2348031234567", "+234 (0) 803 123 4567", "+2340803 123 4567"]) {
      expect(normaliseNigerianPhone(input)).toBe("+2348031234567");
    }
  });

  it("refuses what is not a Nigerian mobile number", () => {
    for (const input of ["", "12345", "+44 20 7946 0958", "0803 123 456", "2340803123456789", "+235 803 123 4567"]) {
      expect(normaliseNigerianPhone(input)).toBeNull();
    }
    expect(phoneProblem(" ")).toBe(MISSING_PHONE);
    expect(phoneProblem("12345")).toBe(INVALID_PHONE);
    expect(phoneProblem("2348031234567")).toBeNull();
  });
});
