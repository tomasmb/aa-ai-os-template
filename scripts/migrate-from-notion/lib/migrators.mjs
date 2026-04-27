// lib/migrators.mjs — Per-entity Notion-row → KB-file converters.
//
// Each migrator returns a list of {filePath, data, body, notionEditedAt}
// records. The writer in write.mjs is responsible for actually writing
// them (so we keep IO concerns out of mapping logic).

import path from "node:path";

import { kbRoot, corePath, archivePath, relativeKbPath } from "./paths.mjs";
import { pageToMarkdown } from "./blocks-to-md.mjs";
import {
  asTitle, asText, asSelect, asMultiSelect, asDate, asEmail, asUrl,
  asPeople, asRelation, asStatus, pick,
} from "./props.mjs";
import {
  slugify, peopleSlug, emailLocalSlug, datePrefixedSlug, periodPrefixedSlug,
} from "./slug.mjs";
import { LIMITS } from "../config.mjs";

const NOTION_META = (row) => ({
  notion: {
    id: row.id,
    url: row.url,
    last_edited_at: row.last_edited_time,
  },
});

// Decide whether a body is "long enough to deserve its own archive
// file". Short bodies stay inline in the core row.
function isLongBody(body) {
  if (!body) return false;
  const trimmed = body.trim();
  if (!trimmed) return false;
  return trimmed.split("\n").length >= LIMITS.longBodyLineThreshold;
}

export async function migratePerson(row, ctx) {
  const name = asTitle(pick(row, ["Name", "Full name", "Person"]));
  const email = asEmail(pick(row, ["Email", "Work email"]));
  const githubUsername = asText(pick(row, ["GitHub", "Github", "GH username", "GitHub username"]));
  const role = asText(pick(row, ["Role", "Title"]));
  const team = asText(pick(row, ["Team"]));
  const slug = peopleSlug({ githubUsername, name, email });
  const body = await pageToMarkdown(row.id, ctx);

  const out = [];
  let bodyPath;
  if (isLongBody(body)) {
    const arc = archivePath("archive/people", slug);
    bodyPath = relativeKbPath(arc);
    out.push({
      filePath: arc,
      data: {
        type: "person",
        name,
        slug,
        ...NOTION_META(row),
      },
      body,
      notionEditedAt: row.last_edited_time,
    });
  }

  out.push({
    filePath: corePath("core/people", slug),
    data: {
      type: "person",
      slug,
      name,
      email: email || undefined,
      github_username: githubUsername || undefined,
      role: role || undefined,
      team: team || undefined,
      body_path: bodyPath,
      ...NOTION_META(row),
    },
    body: bodyPath ? `Full profile: \`${bodyPath}\`.\n` : (body || `Lean profile for **${name}**.\n`),
    notionEditedAt: row.last_edited_time,
  });
  return out;
}

export async function migrateProject(row, ctx) {
  const name = asTitle(pick(row, ["Name", "Project"]));
  const status = asStatus(pick(row, ["Status"])) || asSelect(pick(row, ["Status"]));
  const owners = asPeople(pick(row, ["Owner", "Owners", "Lead"]));
  const goalRel = asRelation(pick(row, ["Goal", "Goals"]));
  const slug = slugify(name);
  const body = await pageToMarkdown(row.id, ctx);

  const out = [];
  let bodyPath;
  if (isLongBody(body)) {
    const arc = archivePath("archive/projects", slug);
    bodyPath = relativeKbPath(arc);
    out.push({
      filePath: arc,
      data: { type: "project", name, slug, ...NOTION_META(row) },
      body,
      notionEditedAt: row.last_edited_time,
    });
  }

  out.push({
    filePath: corePath("core/projects", slug),
    data: {
      type: "project",
      slug,
      name,
      status: status || undefined,
      owners: owners.map((p) => p.email || p.name).filter(Boolean),
      goal_refs: goalRel,
      body_path: bodyPath,
      ...NOTION_META(row),
    },
    body: bodyPath ? `Full project page: \`${bodyPath}\`.\n` : (body || `Lean project row for **${name}**.\n`),
    notionEditedAt: row.last_edited_time,
  });
  return out;
}

export async function migrateMeeting(row, ctx) {
  const title = asTitle(pick(row, ["Name", "Title", "Meeting"]));
  const date = asDate(pick(row, ["Date", "When"]));
  const attendees = asPeople(pick(row, ["Attendees", "Participants"]));
  const projectRel = asRelation(pick(row, ["Project", "Projects"]));
  const slug = datePrefixedSlug({ date, title });
  const body = await pageToMarkdown(row.id, ctx);

  const arc = archivePath("archive/meeting-notes", slug);
  const notesPath = relativeKbPath(arc);

  return [
    {
      filePath: arc,
      data: { type: "meeting-notes", title, date, slug, ...NOTION_META(row) },
      body: body || `_No notes recorded for ${title} on ${date}._\n`,
      notionEditedAt: row.last_edited_time,
    },
    {
      filePath: corePath("core/meetings", slug),
      data: {
        type: "meeting",
        slug,
        title,
        date,
        attendees: attendees.map((p) => p.email || p.name).filter(Boolean),
        project_refs: projectRel,
        notes_path: notesPath,
        ...NOTION_META(row),
      },
      body: `Full notes: \`${notesPath}\`.\n`,
      notionEditedAt: row.last_edited_time,
    },
  ];
}

export async function migrateGoal(row, ctx) {
  const title = asTitle(pick(row, ["Name", "Goal"]));
  const period = asText(pick(row, ["Period", "Quarter", "Cycle"])) || "unknown-period";
  const status = asStatus(pick(row, ["Status"])) || asSelect(pick(row, ["Status"]));
  const owners = asPeople(pick(row, ["Owner", "Owners"]));
  const slug = periodPrefixedSlug({ period, title });
  const body = await pageToMarkdown(row.id, ctx);

  return [{
    filePath: corePath("core/goals", slug),
    data: {
      type: "goal",
      slug,
      title,
      period,
      status: status || undefined,
      owners: owners.map((p) => p.email || p.name).filter(Boolean),
      ...NOTION_META(row),
    },
    body: body || `Goal **${title}** for ${period}.\n`,
    notionEditedAt: row.last_edited_time,
  }];
}

export async function migrateDecision(row, ctx) {
  const title = asTitle(pick(row, ["Name", "Decision"]));
  const date = asDate(pick(row, ["Date", "Decided on"]));
  const owners = asPeople(pick(row, ["Owner", "Decided by", "Owners"]));
  const slug = datePrefixedSlug({ date, title });
  const body = await pageToMarkdown(row.id, ctx);

  const out = [];
  let rationalePath;
  if (isLongBody(body)) {
    const arc = archivePath("archive/decision-rationale", slug);
    rationalePath = relativeKbPath(arc);
    out.push({
      filePath: arc,
      data: { type: "decision-rationale", title, date, slug, ...NOTION_META(row) },
      body,
      notionEditedAt: row.last_edited_time,
    });
  }

  out.push({
    filePath: corePath("core/decisions", slug),
    data: {
      type: "decision",
      slug,
      title,
      date,
      owners: owners.map((p) => p.email || p.name).filter(Boolean),
      rationale_path: rationalePath,
      ...NOTION_META(row),
    },
    body: rationalePath ? `Rationale: \`${rationalePath}\`.\n` : (body || `Decision: **${title}** on ${date}.\n`),
    notionEditedAt: row.last_edited_time,
  });
  return out;
}

export async function migrateInsight(row, ctx) {
  const title = asTitle(pick(row, ["Name", "Insight"]));
  const date = asDate(pick(row, ["Date", "Captured on"])) || (row.created_time || "").slice(0, 10);
  const tags = asMultiSelect(pick(row, ["Tags", "Topic"]));
  const slug = datePrefixedSlug({ date, title });
  const body = await pageToMarkdown(row.id, ctx);

  return [{
    filePath: corePath("core/insights", slug),
    data: {
      type: "insight",
      slug,
      title,
      date,
      tags,
      ...NOTION_META(row),
    },
    body: body || `Insight captured ${date}.\n`,
    notionEditedAt: row.last_edited_time,
  }];
}

export async function migrateArchiveOnly(row, ctx, { entity, targetArchive }) {
  const title = asTitle(pick(row, ["Name", "Title"]));
  const slug = slugify(title);
  const body = await pageToMarkdown(row.id, ctx);
  return [{
    filePath: archivePath(targetArchive, slug),
    data: { type: entity, slug, title, ...NOTION_META(row) },
    body: body || `_${title}_\n`,
    notionEditedAt: row.last_edited_time,
  }];
}

export async function migrateOnboarding(row, ctx) {
  const name = asTitle(pick(row, ["Name", "Hire", "Person"]));
  const email = asEmail(pick(row, ["Email", "Work email"]));
  const role = asText(pick(row, ["Role", "Title"]));
  const startDate = asDate(pick(row, ["Start date", "Start"])) || "";
  const slug = email ? emailLocalSlug(email) : slugify(name);
  const body = await pageToMarkdown(row.id, ctx);

  return [{
    filePath: archivePath("archive/onboarding", slug),
    data: {
      type: "onboarding",
      slug,
      name,
      email: email || undefined,
      role: role || undefined,
      start_date: startDate || undefined,
      ...NOTION_META(row),
    },
    body: body || `_Onboarding plan for ${name}._\n`,
    notionEditedAt: row.last_edited_time,
  }];
}

// Operating Framework: each child page becomes
// operating-framework/<slug>.md, body verbatim.
export async function migrateFrameworkPage(page, ctx) {
  const title = (page?.child_page?.title || page.title || "untitled").trim();
  const slug = slugify(title);
  const body = await pageToMarkdown(page.id, ctx);
  return [{
    filePath: path.join(kbRoot(), "operating-framework", `${slug}.md`),
    data: {
      type: "operating-framework",
      slug,
      title,
      notion: { id: page.id, url: page.url || "" },
    },
    body: body || `_${title}_\n`,
    notionEditedAt: page.last_edited_time,
  }];
}
