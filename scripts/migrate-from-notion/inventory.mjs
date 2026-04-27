#!/usr/bin/env node
// inventory.mjs — Read-only audit pass.
//
// Counts rows in each Notion source DB / page and writes the totals
// into docs/MIGRATION-INVENTORY.md so the maintainer can verify
// nothing fell through the cracks before approving the writer pass.

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  CORE_DATABASES,
  ARCHIVE_DATABASES,
  ONBOARDING_DATABASE,
  OPERATING_FRAMEWORK_ROOT,
  ASSISTANT_UPDATES_SOURCES,
} from "./config.mjs";
import { queryDatabaseAll, listBlockChildrenAll, retrievePage } from "./lib/notion.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const INVENTORY_PATH = path.resolve(__dirname, "..", "..", "docs", "MIGRATION-INVENTORY.md");

async function countDatabaseRows(databaseId) {
  let n = 0;
  for await (const _ of queryDatabaseAll(databaseId)) n++;
  return n;
}

async function countAssistantUpdatesBullets(pageId) {
  const blocks = await listBlockChildrenAll(pageId);
  let inSection = false;
  let count = 0;
  for (const b of blocks) {
    if (b.type === "heading_2") {
      const text = (b.heading_2?.rich_text || []).map((t) => t.plain_text).join("");
      inSection = /assistant updates/i.test(text);
      continue;
    }
    if (inSection && b.type === "bulleted_list_item") count++;
  }
  return count;
}

async function walkOperatingFramework(rootId) {
  const out = [];
  async function walk(blockId, depth) {
    if (depth > 4) return;
    const children = await listBlockChildrenAll(blockId);
    for (const c of children) {
      if (c.type === "child_page") {
        out.push({ id: c.id, title: c.child_page?.title || "(untitled)" });
        await walk(c.id, depth + 1);
      }
    }
  }
  await walk(rootId, 0);
  return out;
}

async function main() {
  const sections = [];

  sections.push("## Core databases\n");
  sections.push("| Notion DB | Notion ID | Target | Row count |");
  sections.push("| --- | --- | --- | --- |");
  for (const db of CORE_DATABASES) {
    const n = await countDatabaseRows(db.notionId);
    sections.push(`| ${db.label} | \`${db.notionId}\` | \`${db.targetCore}/\` | ${n} |`);
  }

  sections.push("\n## Archive databases\n");
  sections.push("| Notion DB | Notion ID | Target | Row count |");
  sections.push("| --- | --- | --- | --- |");
  for (const db of ARCHIVE_DATABASES) {
    const n = await countDatabaseRows(db.notionId);
    sections.push(`| ${db.label} | \`${db.notionId}\` | \`${db.targetArchive}/\` | ${n} |`);
  }

  const onboardingCount = await countDatabaseRows(ONBOARDING_DATABASE.notionId);
  sections.push("\n## Onboarding database\n");
  sections.push(`- **${ONBOARDING_DATABASE.label}** \`${ONBOARDING_DATABASE.notionId}\` → \`${ONBOARDING_DATABASE.targetArchive}/\` — ${onboardingCount} rows`);

  sections.push("\n## Operating Framework subtree\n");
  const framework = await walkOperatingFramework(OPERATING_FRAMEWORK_ROOT.notionId);
  sections.push(`Root: \`${OPERATING_FRAMEWORK_ROOT.notionId}\` (${framework.length} child pages found)`);
  for (const p of framework) sections.push(`- ${p.title} \`${p.id}\``);

  sections.push("\n## Pages with `## Assistant Updates` sections\n");
  sections.push("| Notion page ID | Bullet count |");
  sections.push("| --- | --- |");
  for (const id of ASSISTANT_UPDATES_SOURCES) {
    let n = 0;
    let title = "(unknown)";
    try {
      const page = await retrievePage(id);
      title = (page?.properties?.title?.title || page?.properties?.Name?.title || [])
        .map((t) => t.plain_text).join("") || "(untitled)";
      n = await countAssistantUpdatesBullets(id);
    } catch (err) {
      title = `(error: ${err.message})`;
    }
    sections.push(`| ${title} \`${id}\` | ${n} |`);
  }

  sections.push("\n_Last refreshed: " + new Date().toISOString() + "_\n");

  const block = sections.join("\n") + "\n";
  let existing = "";
  try {
    existing = await fs.readFile(INVENTORY_PATH, "utf8");
  } catch {
    existing = "# MIGRATION-INVENTORY\n\n";
  }

  const marker = "<!-- migration-inventory:auto-start -->";
  const endMarker = "<!-- migration-inventory:auto-end -->";
  const wrapped = `${marker}\n${block}${endMarker}`;
  let next;
  if (existing.includes(marker) && existing.includes(endMarker)) {
    next = existing.replace(new RegExp(`${marker}[\\s\\S]*?${endMarker}`), wrapped);
  } else {
    next = existing.trimEnd() + "\n\n" + wrapped + "\n";
  }
  await fs.writeFile(INVENTORY_PATH, next, "utf8");
  console.log(`Wrote inventory snapshot to ${INVENTORY_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
