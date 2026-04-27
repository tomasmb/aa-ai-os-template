// lib/slug.mjs — Deterministic kebab-case slug generation.

export function slugify(input) {
  if (!input) return "untitled";
  return String(input)
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/--+/g, "-")
    .slice(0, 80) || "untitled";
}

// People slug: prefer GitHub username when set, else `<first>-<last>`.
export function peopleSlug({ githubUsername, name, email }) {
  if (githubUsername) return slugify(githubUsername);
  if (name) return slugify(name);
  if (email) return slugify(email.split("@")[0]);
  return "untitled-person";
}

// Email-keyed slug for onboarding files (the local part, kebab-cased).
export function emailLocalSlug(email) {
  if (!email) return "untitled";
  return slugify(email.split("@")[0]);
}

// Date prefix for meetings, decisions, insights.
export function datePrefixedSlug({ date, title }) {
  const iso = date ? new Date(date).toISOString().slice(0, 10) : "0000-00-00";
  return `${iso}_${slugify(title)}`;
}

// Period prefix for goals (period like 2026-q2).
export function periodPrefixedSlug({ period, title }) {
  const p = slugify(period || "unknown-period");
  return `${p}_${slugify(title)}`;
}

// Inbox filenames carry full timestamp + entity type + slug.
export function inboxFilename({ promotedAt, entity, slug }) {
  const ts = new Date(promotedAt || Date.now()).toISOString()
    .replace(/[:.]/g, "-")
    .replace(/Z$/, "")
    .slice(0, 19);
  return `${ts}_${entity}_${slugify(slug)}.md`;
}
