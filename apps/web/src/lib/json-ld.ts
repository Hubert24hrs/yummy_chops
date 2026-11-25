// The two characters that are line breaks to older JavaScript but allowed inside JSON text.
const LINE_SEPARATOR = String.fromCharCode(0x2028);
const PARAGRAPH_SEPARATOR = String.fromCharCode(0x2029);

/**
 * JSON that is safe to write inside a `<script>` tag (structured data for search engines). Shops write some of the
 * values (their name and address), so "<" is written as its JSON escape (u003c after a backslash): "</script>" in
 * a value then cannot end the tag and start another one. The two line-break characters above are escaped too. The
 * escaped text is still the same JSON: it reads back to the same values.
 */
export function jsonForScript(data: unknown): string {
  return JSON.stringify(data)
    .replaceAll("<", "\\u003c")
    .replaceAll(LINE_SEPARATOR, "\\u2028")
    .replaceAll(PARAGRAPH_SEPARATOR, "\\u2029");
}
