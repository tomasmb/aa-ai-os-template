// lib/paths.mjs — KB path resolution.
//
// Centralizes the rules for "given an entity + slug, where does it
// live in the KB?" so writer/validator/inventory all agree.

import path from "node:path";

export function kbRoot() {
  const root = process.env.KB_ROOT;
  if (!root) {
    throw new Error("KB_ROOT environment variable not set. Point it at the local alpha-anywhere-kb clone.");
  }
  return path.resolve(root);
}

export function corePath(entityFolder, slug) {
  return path.join(kbRoot(), entityFolder, `${slug}.md`);
}

export function archivePath(entityFolder, slug) {
  return path.join(kbRoot(), entityFolder, `${slug}.md`);
}

export function inboxPath(filename) {
  return path.join(kbRoot(), "inbox", filename);
}

// Always express cross-references in the KB as repo-root-relative
// paths (no leading ./, no .md omission). The lint workflow verifies
// these resolve.
export function relativeKbPath(absPath) {
  return path.relative(kbRoot(), absPath);
}
