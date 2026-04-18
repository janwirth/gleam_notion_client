// Dedupe `pub type Anon...` and `pub fn anon_...` blocks in
// src/notion_client/operations.gleam. Generator emits one definition
// per occurrence of the same hashed inline schema; the hash is the same
// so the bodies are identical — keep the first, drop the rest.
import fs from "node:fs";

const path = process.argv[2] ?? "src/notion_client/operations.gleam";
const src = fs.readFileSync(path, "utf8");
const lines = src.split("\n");

const out = [];
const seen = new Set();
let i = 0;

const headerRe = /^pub (type|fn) ((?:Anon|anon_)[0-9a-fA-F]+(?:_(?:decoder|encode|encoder|decode))?)\b/;

while (i < lines.length) {
  const line = lines[i];
  const m = line.match(headerRe);
  if (m) {
    // Slurp the block: collect until the matching closing brace at column 0.
    const blockStart = i;
    // Find the `{` on this line or subsequent — count braces.
    let depth = 0;
    let started = false;
    while (i < lines.length) {
      for (const ch of lines[i]) {
        if (ch === "{") { depth++; started = true; }
        else if (ch === "}") { depth--; }
      }
      if (started && depth === 0) { i++; break; }
      i++;
    }
    const block = lines.slice(blockStart, i).join("\n");
    const key = m[1] + " " + m[2]; // hash already encodes body shape
    if (!seen.has(key)) {
      seen.add(key);
      out.push(block);
    } else {
      // skip; also skip a single trailing blank if present
      if (lines[i] === "") { i++; }
      continue;
    }
    // preserve trailing blank if present
    if (lines[i] === "") { out.push(""); i++; }
  } else {
    out.push(line);
    i++;
  }
}

fs.writeFileSync(path, out.join("\n"));
console.log(`dedupe complete: ${path}`);
