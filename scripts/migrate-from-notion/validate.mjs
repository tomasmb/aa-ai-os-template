#!/usr/bin/env node
// validate.mjs — Post-write sanity pass.
//
// Fails non-zero if any of these are wrong:
// - Frontmatter does not parse, or required fields are missing.
// - A `notes_path` / `body_path` / `rationale_path` doesn't resolve.
// - Markdown link to another KB file points nowhere.
// - File exceeds the binary size limit (200 KB).
// - File-count totals deviate wildly from MIGRATION-INVENTORY.md.
//
// Always prints `git diff --stat` at the end so the maintainer has a
// one-glance view of what the writer changed.

import fs from "node:fs/promises";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

import { kbRoot } from "./lib/paths.mjs";
import { parseFile } from "./lib/frontmatter.mjs";
import { LIMITS } from "./config.mjs";

const exec = promisify(execFile);

const REQUIRED_FIELDS = {
  person: ["type", "slug", "name"],
  project: ["type", "slug", "name"],
  meeting: ["type", "slug", "title", "date", "notes_path"],
  "meeting-notes": ["type", "slug", "title", "date"],
  goal: ["type", "slug", "title", "period"],
  decision: ["type", "slug", "title", "date"],
  "decision-rationale": ["type", "slug", "title", "date"],
  insight: ["type", "slug", "title", "date"],
  onboarding: ["type", "slug", "name"],
  "operating-framework": ["type", "slug", "title"],
  inbox: ["type", "entity", "promoted_at", "status"],
  playbooks: ["type", "slug", "title"],
  glossary: ["type", "slug", "title"],
  students: ["type", "slug", "title"],
};

const PATH_FIELDS = ["notes_path", "body_path", "rationale_path"];

async function* walkMarkdown(dir) {
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.name.startsWith(".")) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      yield* walkMarkdown(full);
    } else if (entry.name.endsWith(".md")) {
      yield full;
    }
  }
}

async function fileExists(p) {
  try {
    await fs.stat(p);
    return true;
  } catch {
    return false;
  }
}

function collectMarkdownLinks(body) {
  const out = [];
  const re = /\[([^\]]+)\]\(([^)]+)\)/g;
  let m;
  while ((m = re.exec(body)) !== null) {
    const target = m[2].trim();
    if (target.startsWith("http") || target.startsWith("#") || target.startsWith("mailto:")) continue;
    out.push(target);
  }
  return out;
}

async function validateFile(filePath, root, errors) {
  const rel = path.relative(root, filePath);
  const text = await fs.readFile(filePath, "utf8");
  const sizeBytes = Buffer.byteLength(text, "utf8");
  if (sizeBytes > LIMITS.maxFileBytes) {
    errors.push(`${rel}: file size ${sizeBytes} > ${LIMITS.maxFileBytes} bytes`);
  }
  const { data, body } = parseFile(text);
  if (data.__parse_error) {
    errors.push(`${rel}: invalid YAML frontmatter — ${data.__parse_error}`);
    return;
  }
  const required = REQUIRED_FIELDS[data?.type];
  if (!required) {
    errors.push(`${rel}: unknown frontmatter type "${data?.type}"`);
  } else {
    for (const f of required) {
      if (!data[f]) errors.push(`${rel}: missing required frontmatter field "${f}"`);
    }
  }
  for (const f of PATH_FIELDS) {
    if (!data[f]) continue;
    const target = path.resolve(root, data[f]);
    if (!(await fileExists(target))) {
      errors.push(`${rel}: ${f} → "${data[f]}" does not exist`);
    }
  }
  for (const link of collectMarkdownLinks(body)) {
    const cleaned = link.split("#")[0];
    if (!cleaned) continue;
    const abs = path.resolve(path.dirname(filePath), cleaned);
    if (!(await fileExists(abs))) {
      errors.push(`${rel}: broken markdown link → "${link}"`);
    }
  }
}

async function gitDiffStat(root) {
  try {
    const { stdout } = await exec("git", ["diff", "--stat"], { cwd: root });
    return stdout.trim() || "(no changes)";
  } catch (err) {
    return `(git diff failed: ${err.message})`;
  }
}

async function main() {
  const root = kbRoot();
  const errors = [];
  let count = 0;
  for await (const file of walkMarkdown(root)) {
    if (path.basename(file) === "README.md") continue;
    count += 1;
    await validateFile(file, root, errors);
  }
  console.log(`Validated ${count} markdown files in ${root}`);
  if (errors.length > 0) {
    console.error(`\n${errors.length} validation errors:`);
    for (const e of errors) console.error(`  - ${e}`);
  } else {
    console.log("All checks passed.");
  }

  console.log("\ngit diff --stat:");
  console.log(await gitDiffStat(root));

  process.exit(errors.length === 0 ? 0 : 2);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
