# MonkeyTilt Cursor Rules

Shared, layered Cursor rules for all company Unity WebGL game projects. Link this repo once and every project gets the same standards for clean, highly performant, robust code.

## How to link this repo in a project

**Preferred: git submodule at `.cursor/rules/shared`.**

```sh
git submodule add <this-repo-url> .cursor/rules/shared
```

Cursor picks up every `.mdc` under `.cursor/rules/`, including submodule folders. Update with `git submodule update --remote .cursor/rules/shared` and commit the pointer bump.

**Alternative: Remote Rule.** Cursor Settings → Rules → Project Rules → Add Rule → Remote Rule (GitHub) → paste this repo's URL. Cursor syncs the `.mdc` files into `.cursor/rules/imported/`.

**Skills are not auto-discovered from either location.** Cursor loads skills from `.cursor/skills/<name>/SKILL.md` only. Link each skill you want into the project:

```sh
ln -s ../rules/shared/skills/full-verify .cursor/skills/full-verify
```

(or copy the folder if symlinks are a problem on your platform — then keep the copy in sync on every submodule bump).

## Layer map

Rules are organized general → specific. A more specific layer may **tighten** a general rule, never contradict it — with one carve-out: verification depth (screenshot/play-mode loop) is a per-project default that a project's own `.cursor/rules/` may set differently.

| Folder | Layer | Contents |
|--------|-------|----------|
| `rules/00-mindset/` | Mantra | Senior gameplay programmer mindset, legacy code policy |
| `rules/10-csharp/` | Language | C# rules: naming/style, no LINQ, fail-fast, non-null contract, no reflection, allocation discipline, structs, async/events, parse at the boundary |
| `rules/20-gamedev/` | Game programming | No premature abstraction, no lazy init, data-oriented design, pooling, frame budget |
| `rules/30-unity/` | Engine | Domain reload statics, component access, update-loop hygiene, logging, config/wire data, prefab-authored UI, uGUI cost, safe area, required refs, dev-only systems, editor tooling, Unity.Mathematics, Unity.Collections |
| `rules/40-webgl/` | Platform | No threads, forbidden APIs (incl. Input System), build size, GC/memory constraints |
| `rules/50-company/` | Infrastructure | SharedSingletonBehaviour / game SingletonBehaviour, ResourceManager/AssetGroup catalog, assembly architecture, pure DTO contracts, server-authoritative outcome, money and numbers |
| `skills/` | Procedures | On-demand workflows: GC allocation audit, WebGL build-size audit, verification depth (`/no-verify`, `/full-verify`) |

## How rules attach

Frontmatter decides, and `scripts/lint-rules.sh` enforces it:

- `alwaysApply: true` — in every chat. Reserved for the mindset, the non-null contract, the UI pipeline, and the legacy policy. No `globs`.
- `globs: **/*.cs` — attaches on any C# edit. The default for language/engine/platform rules.
- `globs: **/Editor/**/*.cs` or `**/Contracts/**/*.cs` — the only folder-scoped globs allowed. `Editor` is Unity's own convention; `Contracts` is a convention the contracts rule itself states. **Never glob on an assumed project layout** (`UI/`, `Presentation/`, `Gameplay/`, `Assets/...`) — every project lays out folders differently and the rule silently goes dead.
- No `globs`, `alwaysApply: false` — Agent Requested: the agent pulls it in when the `description` matches the task. Write the description as "X. Use when Y."

## Contributing a rule

- **One concern per file.** If a rule covers two topics, split it.
- **Place it in the correct layer folder.** Language-level → `10-csharp`, engine-level → `30-unity`, etc.
- **Frontmatter:** `description` (one strong line — the agent uses it to decide relevance), `alwaysApply`, and `globs` only from the allowed set above. Frontmatter is authoritative; do not restate attach mode elsewhere.
- **Mandatory sections:** short principle statement, a concrete BAD/GOOD code pair, a narrow allowed-exceptions list, and an **Agent checklist** at the bottom (lint-enforced).
- **Keep it under ~120 lines.** Long rules get skimmed; split instead.
- **Be concrete.** "Avoid interfaces for single implementations" beats "don't over-abstract". Name the banned API, show the replacement.
- **Point at assemblies and types, never `Assets/...` paths.** A path is project-specific and goes stale the first time a project reorganises a folder — and a stale path in a shared rule reads as an instruction to recreate it.
- **Verify Shared names before writing them.** The shared runtime foundation is `MonkeyTilt.Foundation` (namespace `MonkeyTilt.Shared`: `SharedSingletonBehaviour`, `RequiredRefs`, `MainThreadDelay`, `DevSwitches`). Other features have their own asmdefs (`MonkeyTilt.Shared.AssetCatalog`, `MonkeyTilt.Shared.Guards.Editor`, …). Every `` `MonkeyTilt.*` `` token in a rule body must be in the lint's `KNOWN_ASSEMBLIES`; when the buildtools repo adds or renames an assembly, update that list and every rule that mentions it in the same change.
- **Run `scripts/lint-rules.sh` after every edit.**

## Project-specific rules

Rules that only apply to one game (wire contracts, project namespaces, scene names, folder maps, input gating for a specific table layout) stay in that project's own `.cursor/rules/` or `AGENTS.md` — do not add them here.
