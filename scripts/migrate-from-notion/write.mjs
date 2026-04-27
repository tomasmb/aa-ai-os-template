#!/usr/bin/env node
// write.mjs — Two-pass writer.
//
// Pass 1: fetch every Notion row → migrators → in-memory records.
// Build a Notion-page-id → KB-path index.
// Pass 2: rewrite cross-references in body strings, then flush each
// record to disk via writer.writeIfStale.
//
// Idempotent: re-runs only touch files whose Notion last_edited_at is
// strictly newer than the local frontmatter's `notion.last_edited_at`.

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
import { writeIfStale, appendSkipReport } from "./lib/writer.mjs";
import { kbRoot, relativeKbPath, inboxPath } from "./lib/paths.mjs";
import { inboxFilename, slugify } from "./lib/slug.mjs";
import {
  migratePerson, migrateProject, migrateMeeting, migrateGoal,
  migrateDecision, migrateInsight, migrateArchiveOnly, migrateOnboarding,
  migrateFrameworkPage,
} from "./lib/migrators.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SKIP_DOC = path.resolve(__dirname, "..", "..", "docs", "MIGRATION-SKIPPED.md");

const ENTITY_HANDLERS = {
  people: migratePerson,
  projects: migrateProject,
  meetings: migrateMeeting,
  goals: migrateGoal,
  decisions: migrateDecision,
  insights: migrateInsight,
};

async function collectFromDatabase(db, ctx, records, idIndex) {
  const handler = ENTITY_HANDLERS[db.entity];
  for await (const row of queryDatabaseAll(db.notionId)) {
    let recs;
    if (handler) {
      recs = await handler(row, ctx);
    } else {
      recs = await migrateArchiveOnly(row, ctx, { entity: db.entity, targetArchive: db.targetArchive });
    }
    for (const r of recs) {
      records.push(r);
      idIndex.set(row.id, idIndex.get(row.id) || relativeKbPath(r.filePath));
    }
  }
}

async function collectOnboarding(ctx, records, idIndex) {
  for await (const row of queryDatabaseAll(ONBOARDING_DATABASE.notionId)) {
    const recs = await migrateOnboarding(row, ctx);
    for (const r of recs) {
      records.push(r);
      idIndex.set(row.id, relativeKbPath(r.filePath));
    }
  }
}

async function collectFramework(ctx, records, idIndex) {
  async function walk(blockId, depth) {
    if (depth > 4) return;
    const children = await listBlockChildrenAll(blockId);
    for (const c of children) {
      if (c.type !== "child_page") continue;
      const page = await retrievePage(c.id);
      const recs = await migrateFrameworkPage({ ...page, child_page: c.child_page }, ctx);
      for (const r of recs) {
        records.push(r);
        idIndex.set(c.id, relativeKbPath(r.filePath));
      }
      await walk(c.id, depth + 1);
    }
  }
  await walk(OPERATING_FRAMEWORK_ROOT.notionId, 0);
}

// Pull `## Assistant Updates` bullets from the listed pages into
// inbox/ files. The KB inbox semantic is "AI promotions awaiting
// review", but at migration-time we one-shot import them so nothing
// is lost.
async function collectAssistantUpdates(ctx, records) {
  for (const pageId of ASSISTANT_UPDATES_SOURCES) {
    let page;
    try {
      page = await retrievePage(pageId);
    } catch (err) {
      console.warn(`Skipping assistant-updates source ${pageId}: ${err.message}`);
      continue;
    }
    const blocks = await listBlockChildrenAll(pageId);
    let inSection = false;
    let bulletIndex = 0;
    const sourceTitle = (page?.properties?.title?.title || page?.properties?.Name?.title || [])
      .map((t) => t.plain_text).join("") || pageId;
    for (const b of blocks) {
      if (b.type === "heading_2") {
        const text = (b.heading_2?.rich_text || []).map((t) => t.plain_text).join("");
        inSection = /assistant updates/i.test(text);
        continue;
      }
      if (!inSection) continue;
      if (b.type !== "bulleted_list_item") continue;
      const text = (b.bulleted_list_item?.rich_text || []).map((t) => t.plain_text).join("").trim();
      if (!text) continue;
      bulletIndex += 1;
      const promotedAt = b.created_time || page?.last_edited_time || new Date().toISOString();
      const slug = slugify(text.split("\n")[0]).slice(0, 60) || `update-${bulletIndex}`;
      const filename = inboxFilename({ promotedAt, entity: "insights", slug });
      records.push({
        filePath: inboxPath(filename),
        data: {
          type: "inbox",
          entity: "insights",
          source: { notion_page: pageId, source_title: sourceTitle },
          promoted_at: promotedAt,
          status: "pending",
        },
        body: `${text}\n`,
        notionEditedAt: b.last_edited_time || promotedAt,
      });
    }
  }
}

// After pass 1, replace any `<<notion:PAGE_ID>>` placeholders the
// migrators emitted in their bodies with the resolved KB path.
function rewriteCrossLinks(records, idIndex) {
  const placeholder = /<<notion:([0-9a-fA-F-]+)>>/g;
  for (const rec of records) {
    if (!rec.body) continue;
    rec.body = rec.body.replace(placeholder, (_, id) => {
      const target = idIndex.get(id) || idIndex.get(id.replace(/-/g, ""));
      return target ? `\`${target}\`` : `<!-- unresolved Notion ref ${id} -->`;
    });
  }
}

async function flush(records, ctx) {
  const stats = { written: 0, skipped: 0, identical: 0, oversized: 0 };
  for (const rec of records) {
    const res = await writeIfStale(rec);
    if (res.written) {
      stats.written += 1;
      console.log(`  + ${path.relative(kbRoot(), rec.filePath)} (${res.reason})`);
    } else if (res.skipped === "too_large") {
      stats.oversized += 1;
      console.warn(`  ! oversized, skipped: ${path.relative(kbRoot(), rec.filePath)} (${res.sizeBytes} bytes)`);
    } else if (res.reason === "identical") {
      stats.identical += 1;
    } else {
      stats.skipped += 1;
    }
  }
  await appendSkipReport({
    docPath: SKIP_DOC,
    rows: ctx.skippedBinaries.map((s) => ({ ...s, reason: "binary" })),
  });
  return stats;
}

async function main() {
  const records = [];
  const idIndex = new Map();
  const ctx = { skippedBinaries: [] };

  console.log("Pass 1: collecting Notion content…");
  for (const db of CORE_DATABASES) {
    console.log(`  · core ${db.label} (${db.entity})`);
    await collectFromDatabase(db, ctx, records, idIndex);
  }
  for (const db of ARCHIVE_DATABASES) {
    console.log(`  · archive ${db.label} (${db.entity})`);
    await collectFromDatabase(db, ctx, records, idIndex);
  }
  console.log(`  · onboarding ${ONBOARDING_DATABASE.label}`);
  await collectOnboarding(ctx, records, idIndex);
  console.log(`  · operating framework`);
  await collectFramework(ctx, records, idIndex);
  console.log(`  · assistant-updates bullets`);
  await collectAssistantUpdates(ctx, records);

  console.log("Pass 2: rewriting cross-links and flushing…");
  rewriteCrossLinks(records, idIndex);
  const stats = await flush(records, ctx);

  console.log("\nDone.");
  console.log(`  written:    ${stats.written}`);
  console.log(`  identical:  ${stats.identical}`);
  console.log(`  oversized:  ${stats.oversized}`);
  console.log(`  skipped binaries: ${ctx.skippedBinaries.length} (see ${path.relative(process.cwd(), SKIP_DOC)})`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
