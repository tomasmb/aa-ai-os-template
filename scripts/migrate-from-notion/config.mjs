// config.mjs — Notion source IDs and how each maps into the KB.
//
// Source of truth for the migration. Update this file (not the
// scripts) when the maintainer flags a new page worth migrating, or
// when an entity type's KB target folder changes.

export const CORE_DATABASES = [
  {
    notionId: "6b06c441-1b94-48be-b21e-14f4df69fa8b",
    label: "👤 People",
    entity: "people",
    targetCore: "core/people",
    targetArchive: "archive/people",
    archiveOnLongBody: true,
  },
  {
    notionId: "b23db324-3d41-46bf-85e6-0ede57dca759",
    label: "🚀 Projects",
    entity: "projects",
    targetCore: "core/projects",
    targetArchive: "archive/projects",
    archiveOnLongBody: true,
  },
  {
    notionId: "a31bc7be-1011-4aeb-861e-73fc83293f67",
    label: "🗓 Meetings",
    entity: "meetings",
    targetCore: "core/meetings",
    targetArchive: "archive/meeting-notes",
    archiveAlways: true,
    pathField: "notes_path",
    slugFromDate: true,
  },
  {
    notionId: "b059e5f7-c5fd-4b7e-8ddd-eea8b8de255f",
    label: "🎯 Goals",
    entity: "goals",
    targetCore: "core/goals",
    slugFromPeriod: true,
  },
  {
    notionId: "c1978663-1d3d-4144-8dac-8dc56b195604",
    label: "✅ Decisions",
    entity: "decisions",
    targetCore: "core/decisions",
    targetArchive: "archive/decision-rationale",
    archiveOnLongBody: true,
    pathField: "rationale_path",
    slugFromDate: true,
  },
  {
    notionId: "73815567-aaa9-4aea-90fb-1d9678f80f14",
    label: "💡 Insights",
    entity: "insights",
    targetCore: "core/insights",
    slugFromDate: true,
  },
];

export const ARCHIVE_DATABASES = [
  {
    notionId: "149cab67-67dd-4878-b316-2cf862f65adc",
    label: "🎓 Students / Families",
    entity: "students",
    targetArchive: "archive/students",
  },
  {
    notionId: "fb856e03-efca-4def-af37-59cb63296f67",
    label: "📘 Playbooks",
    entity: "playbooks",
    targetArchive: "archive/playbooks",
  },
  {
    notionId: "83c00d27-9167-4c8b-a859-68cca6f66727",
    label: "📖 Glossary",
    entity: "glossary",
    targetArchive: "archive/glossary",
  },
];

export const ONBOARDING_DATABASE = {
  notionId: "2922901d-7908-802a-b4d6-d0b79fb15722",
  label: "👋 New Hire Onboarding",
  entity: "onboarding",
  targetArchive: "archive/onboarding",
  slugFromEmail: true,
  windowMonths: 12,
};

// Operating Framework root page — children walked recursively.
export const OPERATING_FRAMEWORK_ROOT = {
  notionId: "2892901d-7908-8097-b23f-f06dbb41b4dc",
  label: "Operating Framework",
  targetFolder: "operating-framework",
};

// Pages whose `## Assistant Updates` section should be exploded into
// inbox/ files (one file per bullet). Add maintainer-flagged pages
// here as the inventory pass surfaces them.
export const ASSISTANT_UPDATES_SOURCES = [
  "3492901d-7908-81ad-b05d-f812f2aa4131", // 🧠 AI Memory
  "34b2901d-7908-816e-aa04-cd681e796e61", // 📚 AI Memory — Archive
  "3492901d-7908-81ec-8db9-fd7a27254af2", // AI Memory — Privacy & Sensitivity
  "3492901d-7908-81df-80e3-fbfefd7e7b70", // Alpha AI OS — V1
  "34b2901d-7908-81ec-9d4e-f396de3372e4", // Alpha Turbo Squad — Launch Tracker
];

// Hard limits — match alpha-anywhere-kb/.github/workflows/lint.mjs.
export const LIMITS = {
  maxFileBytes: 200 * 1024,
  longBodyLineThreshold: 16,
};
