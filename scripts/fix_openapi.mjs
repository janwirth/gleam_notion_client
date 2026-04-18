// Post-process postman2openapi output for spec compliance.
// 1. Add a `type` to any schema with `nullable: true` but no `type`.
//    (postman2openapi emits these for null example values.) Pick the
//    type from the `example` field when present and non-null; otherwise
//    default to "string".
// 2. Strip trailing slash from path keys: `/v1/databases/` -> `/v1/databases`.
import fs from "node:fs";

const path = process.argv[2] ?? "openapi.json";
const doc = JSON.parse(fs.readFileSync(path, "utf8"));

function inferType(v) {
  if (v === null || v === undefined) return "string";
  if (Array.isArray(v)) return "array";
  return typeof v === "number"
    ? (Number.isInteger(v) ? "integer" : "number")
    : typeof v;
}

let nullableFixed = 0;
let linkFixed = 0;
function walk(node, key) {
  if (Array.isArray(node)) { node.forEach((v) => walk(v)); return; }
  if (node && typeof node === "object") {
    // text.link in Notion is either null or {url: string}; declare as nullable object.
    if (key === "link" && node.nullable === true && node.type === undefined) {
      node.type = "object";
      node.properties = { url: { type: "string" } };
      delete node.example;
      linkFixed++;
    } else if (node.nullable === true && node.type === undefined) {
      node.type = inferType(node.example);
      nullableFixed++;
    }
    for (const [k, v] of Object.entries(node)) walk(v, k);
  }
}
walk(doc);

let pathsRenamed = 0;
const newPaths = {};
for (const [k, v] of Object.entries(doc.paths)) {
  let nk = k;
  if (k !== "/" && k.endsWith("/")) {
    nk = k.replace(/\/+$/, "");
    pathsRenamed++;
  }
  if (newPaths[nk]) Object.assign(newPaths[nk], v); else newPaths[nk] = v;
}
doc.paths = newPaths;

fs.writeFileSync(path, JSON.stringify(doc, null, 2) + "\n");
console.log(`fixed nullable-without-type: ${nullableFixed}`);
console.log(`fixed text.link schemas: ${linkFixed}`);
console.log(`renamed trailing-slash paths: ${pathsRenamed}`);
