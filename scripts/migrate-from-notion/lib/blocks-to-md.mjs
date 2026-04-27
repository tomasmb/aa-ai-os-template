// lib/blocks-to-md.mjs — Notion block tree → GitHub-flavored markdown.
//
// Intentionally narrow: we only handle the block types our Notion
// workspace actually uses. Unsupported blocks emit an HTML comment so
// the maintainer can spot them in the diff.

import { listBlockChildrenAll, richTextToPlain } from "./notion.mjs";

export async function pageToMarkdown(pageId, { skippedBinaries }) {
  const blocks = await listBlockChildrenAll(pageId);
  return await renderBlocks(blocks, { skippedBinaries, indent: 0 });
}

async function renderBlocks(blocks, ctx) {
  const lines = [];
  for (const block of blocks) {
    const rendered = await renderBlock(block, ctx);
    if (rendered !== null) lines.push(rendered);
  }
  return lines.join("\n\n").replace(/\n{3,}/g, "\n\n").trim() + "\n";
}

async function renderBlock(block, ctx) {
  const t = block.type;
  const data = block[t];
  const indent = "  ".repeat(ctx.indent);

  switch (t) {
    case "paragraph":
      return indent + richInline(data.rich_text);
    case "heading_1":
      return `# ${richInline(data.rich_text)}`;
    case "heading_2":
      return `## ${richInline(data.rich_text)}`;
    case "heading_3":
      return `### ${richInline(data.rich_text)}`;
    case "bulleted_list_item":
      return await listItem("-", block, ctx);
    case "numbered_list_item":
      return await listItem("1.", block, ctx);
    case "to_do":
      return await listItem(data.checked ? "- [x]" : "- [ ]", block, ctx);
    case "toggle":
      return await toggleBlock(block, ctx);
    case "quote":
      return indent + "> " + richInline(data.rich_text).split("\n").join(`\n${indent}> `);
    case "callout":
      return indent + "> " + richInline(data.rich_text);
    case "divider":
      return "---";
    case "code": {
      const lang = data.language || "";
      const body = richInline(data.rich_text);
      return "```" + lang + "\n" + body + "\n```";
    }
    case "bookmark":
    case "embed":
    case "link_preview":
      return indent + (data.url ? `[${data.url}](${data.url})` : "");
    case "image":
    case "file":
    case "pdf":
    case "video":
    case "audio": {
      const url = data?.file?.url || data?.external?.url || "";
      ctx.skippedBinaries.push({ type: t, url, blockId: block.id });
      return indent + `<!-- skipped ${t}: ${url || "(no url)"} -->`;
    }
    case "table":
      return await renderTable(block, ctx);
    case "child_page":
      return indent + `<!-- child_page: ${data.title || block.id} (migrated separately if listed in config) -->`;
    case "synced_block":
    case "column_list":
    case "column":
      return await renderContainer(block, ctx);
    case "table_of_contents":
    case "breadcrumb":
      return null; // Skip — we regenerate navigation in the KB.
    default:
      return indent + `<!-- unsupported block: ${t} -->`;
  }
}

async function listItem(marker, block, ctx) {
  const data = block[block.type];
  const indent = "  ".repeat(ctx.indent);
  let line = `${indent}${marker} ${richInline(data.rich_text)}`;
  if (block.has_children) {
    const children = await listBlockChildrenAll(block.id);
    const child = await renderBlocks(children, { ...ctx, indent: ctx.indent + 1 });
    if (child) line += `\n${child}`;
  }
  return line;
}

async function toggleBlock(block, ctx) {
  const data = block.toggle;
  const summary = richInline(data.rich_text);
  let body = "";
  if (block.has_children) {
    const children = await listBlockChildrenAll(block.id);
    body = await renderBlocks(children, { ...ctx, indent: ctx.indent });
  }
  return `<details><summary>${summary}</summary>\n\n${body}\n</details>`;
}

async function renderContainer(block, ctx) {
  if (!block.has_children) return null;
  const children = await listBlockChildrenAll(block.id);
  return await renderBlocks(children, ctx);
}

async function renderTable(block, ctx) {
  if (!block.has_children) return "";
  const rows = await listBlockChildrenAll(block.id);
  if (rows.length === 0) return "";
  const cells = rows.map((r) => (r.table_row?.cells || []).map((c) => richTextToPlain(c).replace(/\|/g, "\\|")));
  const header = cells[0];
  const sep = header.map(() => "---");
  const body = cells.slice(1);
  const fmt = (r) => "| " + r.join(" | ") + " |";
  return [fmt(header), fmt(sep), ...body.map(fmt)].join("\n");
}

function richInline(rt) {
  if (!Array.isArray(rt)) return "";
  return rt.map((t) => {
    let s = t.plain_text || "";
    const a = t.annotations || {};
    if (a.code) s = "`" + s + "`";
    if (a.bold) s = `**${s}**`;
    if (a.italic) s = `*${s}*`;
    if (a.strikethrough) s = `~~${s}~~`;
    if (t.href) s = `[${s}](${t.href})`;
    return s;
  }).join("");
}
