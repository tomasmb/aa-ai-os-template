// lib/writer.mjs — Filesystem write helpers shared by all entity
// migrators. Centralizes idempotency and "skip if not stale" logic.

import fs from "node:fs/promises";
import path from "node:path";

import { stampFile, parseFile } from "./frontmatter.mjs";
import { LIMITS } from "../config.mjs";

export async function ensureDir(filePath) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
}

// Write iff the body or frontmatter actually changed, or if Notion
// reports a newer last_edited_at than the existing frontmatter.
export async function writeIfStale({ filePath, data, body, notionEditedAt }) {
  await ensureDir(filePath);
  const next = stampFile({ data, body });
  const sizeBytes = Buffer.byteLength(next, "utf8");
  if (sizeBytes > LIMITS.maxFileBytes) {
    return { written: false, skipped: "too_large", sizeBytes };
  }
  let existing = null;
  try {
    existing = await fs.readFile(filePath, "utf8");
  } catch {
    existing = null;
  }
  if (existing === null) {
    await fs.writeFile(filePath, next, "utf8");
    return { written: true, reason: "created" };
  }
  if (existing === next) return { written: false, reason: "identical" };
  if (notionEditedAt) {
    const { data: prev } = parseFile(existing);
    const prevEdited = prev?.notion?.last_edited_at;
    if (prevEdited && Date.parse(prevEdited) >= Date.parse(notionEditedAt)) {
      return { written: false, reason: "older_than_local" };
    }
  }
  await fs.writeFile(filePath, next, "utf8");
  return { written: true, reason: "updated" };
}

// Append to a binary-skip report. Maintainer reviews after the run.
export async function appendSkipReport({ docPath, rows }) {
  if (rows.length === 0) return;
  await ensureDir(docPath);
  let existing = "";
  try {
    existing = await fs.readFile(docPath, "utf8");
  } catch {
    existing = "# MIGRATION-SKIPPED\n\n_Files skipped during the Notion → KB migration because they were binary or oversized. The maintainer is responsible for re-uploading important attachments to Drive/S3 and patching the relevant KB entry._\n\n";
  }
  const header = "| Source page | Block type | Original URL | Reason |\n| --- | --- | --- | --- |\n";
  const lines = rows.map((r) => `| ${r.sourcePage || "(unknown)"} | ${r.type} | ${r.url || "(no url)"} | ${r.reason || "binary"} |`);
  const block = `\n## Run ${new Date().toISOString()}\n\n${header}${lines.join("\n")}\n`;
  await fs.writeFile(docPath, existing.trimEnd() + "\n" + block + "\n", "utf8");
}
