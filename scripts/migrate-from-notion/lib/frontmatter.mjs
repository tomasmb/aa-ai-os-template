// lib/frontmatter.mjs — YAML frontmatter helpers.
//
// Frontmatter is the contract between the KB linter
// (alpha-anywhere-kb/.github/workflows/lint.mjs) and the migration
// writer. Keep schemas in sync with KB-CONVENTIONS.md.

import yaml from "js-yaml";

const FENCE = "---";

// Parse a markdown file's YAML frontmatter. Returns {data, body}.
export function parseFile(text) {
  if (!text.startsWith(FENCE)) return { data: {}, body: text };
  const end = text.indexOf(`\n${FENCE}`, FENCE.length);
  if (end === -1) return { data: {}, body: text };
  const yamlBlock = text.slice(FENCE.length, end).trim();
  const body = text.slice(end + FENCE.length + 1).replace(/^\n/, "");
  let data = {};
  try {
    data = yaml.load(yamlBlock) || {};
  } catch (err) {
    data = { __parse_error: String(err) };
  }
  return { data, body };
}

// Stamp a markdown file with a frontmatter block. Drops undefined and
// empty arrays so files stay easy to diff.
export function stampFile({ data, body }) {
  const cleaned = {};
  for (const [k, v] of Object.entries(data || {})) {
    if (v === undefined || v === null) continue;
    if (Array.isArray(v) && v.length === 0) continue;
    cleaned[k] = v;
  }
  const yamlBlock = yaml.dump(cleaned, { lineWidth: 120, noRefs: true }).trimEnd();
  return `${FENCE}\n${yamlBlock}\n${FENCE}\n\n${body.trimStart()}\n`;
}

// Merge frontmatter from two sources (later wins) and re-stamp.
export function mergeFile(existing, next) {
  const a = parseFile(existing);
  const b = parseFile(next);
  return stampFile({
    data: { ...a.data, ...b.data },
    body: b.body || a.body,
  });
}
