# MonkeyTilt Cursor Rules

Shared, layered Cursor rules for all company Unity WebGL game projects. Link this repo once and every project gets the same standards for clean, highly performant, robust code.

## How to link this repo in Cursor

1. Open **Customize** in the Cursor sidebar (or Cursor Settings → Rules).
2. Under **Project Rules**, click **Add Rule**.
3. Select **Remote Rule (GitHub)**.
4. Paste this repository's URL.

Cursor scans the repo for all `.mdc` files and syncs them into the project at `.cursor/rules/imported/`, preserving this repo's folder structure. Rules auto-sync with this repo afterwards — update a rule here and every linked project picks it up.

Skills under `skills/` can be copied into a project's `.cursor/skills/` (or `~/.cursor/skills/` for personal global use), or imported the same way.

## Layer map

Rules are organized general → specific. A more specific layer may **tighten** a general rule, never contradict it.

| Folder | Layer | Contents |
|--------|-------|----------|
| `rules/00-mindset/` | Mantra | Senior gameplay programmer mindset — always applied |
| `rules/10-csharp/` | Language | C# rules: no LINQ, fail-fast, no reflection, allocation discipline, structs, style |
| `rules/20-gamedev/` | Game programming | No premature abstraction, data-oriented design, pooling, frame budget |
| `rules/30-unity/` | Engine | Domain reload statics, Unity.Mathematics, Unity.Collections, component access, update-loop hygiene |
| `rules/40-webgl/` | Platform | No threads, forbidden APIs, build size, GC/memory constraints |
| `rules/50-company/` | Infrastructure | SingletonBehaviour, ResourceManager/GameAssetDatabase, asmdef architecture, pure DTO contracts, modal input blocking |
| `skills/` | Procedures | On-demand workflows: GC allocation audit, WebGL build-size audit |

## Contributing a rule

- **One concern per file.** If a rule covers two topics, split it.
- **Place it in the correct layer folder.** Language-level → `10-csharp`, engine-level → `30-unity`, etc.
- **Frontmatter:** `description` (one strong line — the agent uses it to decide relevance), `globs` (usually `**/*.cs`), `alwaysApply: false` (only `00-mindset` is always-on).
- **Mandatory sections:** short principle statement, a concrete BAD/GOOD code pair, a narrow allowed-exceptions list, and an **Agent checklist** at the bottom.
- **Keep it under ~120 lines.** Long rules get skimmed; split instead.
- **Be concrete.** "Avoid interfaces for single implementations" beats "don't over-abstract". Name the banned API, show the replacement.

## Project-specific rules

Rules that only apply to one game (wire contracts, project namespaces, scene names) stay in that project's own `.cursor/rules/` — do not add them here.
