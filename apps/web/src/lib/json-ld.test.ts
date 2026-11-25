import { describe, expect, it } from "vitest";
import { jsonForScript } from "./json-ld";

describe("JSON written inside a <script> tag", () => {
  it("cannot end the tag: a shop's address with </script> in it stays data", () => {
    const data = { name: "Mama's Kitchen", address: { streetAddress: "12 Road</script><script>alert(1)</script>" } };
    const out = jsonForScript(data);
    expect(out).not.toContain("<");
    expect(out).toContain("\\u003c/script>");
    expect(JSON.parse(out)).toEqual(data); // the same values come back
  });

  it("escapes the two line breaks that older JavaScript does not allow in text", () => {
    const data = { note: "one\u2028two\u2029three" };
    const out = jsonForScript(data);
    expect(out).not.toMatch(/[\u2028\u2029]/);
    expect(out).toContain("\\u2028");
    expect(out).toContain("\\u2029");
    expect(JSON.parse(out)).toEqual(data);
  });

  it("leaves ordinary values as JSON.stringify writes them", () => {
    const data = { "@type": "Restaurant", priceRange: "₦₦", rating: 4.5, cuisines: ["Nigerian", "Grills"] };
    expect(jsonForScript(data)).toBe(JSON.stringify(data));
  });
});
