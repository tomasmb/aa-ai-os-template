// lib/notion.mjs — Thin, retry-aware wrapper around @notionhq/client.

import { Client } from "@notionhq/client";

let _client = null;

export function client() {
  if (_client) return _client;
  const token = process.env.NOTION_TOKEN;
  if (!token) {
    throw new Error("NOTION_TOKEN environment variable not set. Create an internal integration and grant it page access first.");
  }
  _client = new Client({ auth: token, notionVersion: "2022-06-28" });
  return _client;
}

// Iterate every row of a database, transparently following pagination.
export async function* queryDatabaseAll(databaseId, filter) {
  let cursor = undefined;
  do {
    const res = await withRetry(() => client().databases.query({
      database_id: databaseId,
      start_cursor: cursor,
      page_size: 100,
      filter,
    }));
    for (const row of res.results) yield row;
    cursor = res.has_more ? res.next_cursor : undefined;
  } while (cursor);
}

// Fetch every block of a page (recursive children pulled by the
// caller in blocks-to-md when needed).
export async function listBlockChildrenAll(blockId) {
  const out = [];
  let cursor = undefined;
  do {
    const res = await withRetry(() => client().blocks.children.list({
      block_id: blockId,
      start_cursor: cursor,
      page_size: 100,
    }));
    out.push(...res.results);
    cursor = res.has_more ? res.next_cursor : undefined;
  } while (cursor);
  return out;
}

export async function retrievePage(pageId) {
  return withRetry(() => client().pages.retrieve({ page_id: pageId }));
}

// Notion enforces ~3 req/s. Back off + retry on 429 / 5xx.
async function withRetry(fn, attempt = 0) {
  try {
    return await fn();
  } catch (err) {
    const status = err?.status || err?.code;
    const retryable = status === 429 || (typeof status === "number" && status >= 500);
    if (!retryable || attempt >= 5) throw err;
    const delay = Math.min(1000 * 2 ** attempt, 8000);
    await new Promise((r) => setTimeout(r, delay));
    return withRetry(fn, attempt + 1);
  }
}

// Convert Notion `rich_text` / `title` into plain text (markdown
// inline formatting is handled in blocks-to-md).
export function richTextToPlain(rt) {
  if (!Array.isArray(rt)) return "";
  return rt.map((t) => t.plain_text || "").join("");
}

// Get a property from a row safely. Returns null if missing.
export function readProp(row, name) {
  return row?.properties?.[name] || null;
}
