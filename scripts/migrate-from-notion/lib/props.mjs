// lib/props.mjs — Notion property → JS-friendly value extraction.
//
// Helpers shared between writers for each entity type. None of these
// touch the filesystem; they purely reshape Notion property values.

import { richTextToPlain } from "./notion.mjs";

export function asTitle(prop) {
  if (!prop) return "";
  if (prop.title) return richTextToPlain(prop.title);
  if (prop.rich_text) return richTextToPlain(prop.rich_text);
  return "";
}

export function asText(prop) {
  if (!prop) return "";
  if (prop.rich_text) return richTextToPlain(prop.rich_text);
  if (prop.title) return richTextToPlain(prop.title);
  return "";
}

export function asSelect(prop) {
  return prop?.select?.name || "";
}

export function asMultiSelect(prop) {
  return (prop?.multi_select || []).map((s) => s.name);
}

export function asDate(prop) {
  return prop?.date?.start || "";
}

export function asEmail(prop) {
  return prop?.email || "";
}

export function asUrl(prop) {
  return prop?.url || "";
}

export function asPeople(prop) {
  return (prop?.people || []).map((p) => ({ id: p.id, name: p.name || "", email: p.person?.email || "" }));
}

export function asRelation(prop) {
  return (prop?.relation || []).map((r) => r.id);
}

export function asNumber(prop) {
  return typeof prop?.number === "number" ? prop.number : null;
}

export function asCheckbox(prop) {
  return Boolean(prop?.checkbox);
}

export function asStatus(prop) {
  return prop?.status?.name || "";
}

// Best-effort: pick the first property whose name matches any of the
// candidate strings (case-insensitive). Notion DBs in this workspace
// have inconsistent capitalization, so we avoid hard-coding.
export function pick(row, candidates) {
  const props = row?.properties || {};
  const lower = Object.fromEntries(
    Object.entries(props).map(([k, v]) => [k.toLowerCase(), v])
  );
  for (const name of candidates) {
    const v = lower[name.toLowerCase()];
    if (v) return v;
  }
  return null;
}
