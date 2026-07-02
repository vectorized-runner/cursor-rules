---
name: webgl-build-size-audit
description: Audit and shrink a Unity WebGL build. Use when asked to reduce build size, investigate why the WebGL build got bigger, read a build report, or cut download/load time.
---

# WebGL Build Size Audit

Procedure for finding what's inflating a Unity WebGL build and cutting it.

## Step 1 — Get the numbers

1. Build (or use the last build) and open the **Editor.log** build report (Console → Open Editor Log, section "Build Report"), or use the Build Report Inspector / `BuildReport` API for structured data.
2. Record: total build size, `.wasm` size, `.data` size, and the "Used Assets and files, sorted by uncompressed size" list.
3. Compare against the previous build if the question is "why did it grow" — diff the asset list first; a single texture import change is the usual answer.

## Step 2 — Rank the contributors

**Data file (`.data`) — usually the bulk:**

- Top textures: check max size, compression format, whether mipmaps/readable flags are needed.
- Audio: music should be Vorbis-compressed streaming; SFX short clips; check for accidental WAV imports.
- Meshes/animations: check compression settings.
- `Resources/` folders: everything there ships whether referenced or not — audit for dead assets.
- Scenes in Build Settings that are no longer used.

**Code (`.wasm`):**

- `Packages/manifest.json`: list packages; question each one's necessity. Remove unused (Input System, Timeline, analytics SDKs left over from prototypes are common finds).
- Managed Stripping Level: should be **High** for WebGL. If lower, find out what forced it (usually reflection) and fix the code instead.
- `link.xml` files: each preserved assembly defeats stripping for that assembly — verify each entry is still needed.
- Grep for reflection (`Activator`, `GetMethod`, `Assembly.GetTypes`) and heavy generic utility layers — both inflate IL2CPP output.

## Step 3 — Apply fixes, biggest first

Work the ranked list top-down; don't micro-optimize 50 KB while a 8 MB texture ships unnoticed.

| Finding | Fix |
|---------|-----|
| Oversized texture | Reduce max size, enable crunch/ASTC-appropriate compression |
| Uncompressed audio | Vorbis, quality ~70%, streaming for music |
| Dead `Resources/` assets | Delete or move out of `Resources/` |
| Unused package | Remove from manifest |
| Stripping below High | Fix reflection, raise stripping |
| Broad `link.xml` | Narrow to specific types with a comment per entry |
| Compression format of the build | Ensure Brotli compression is enabled in Publishing Settings and the host serves the pre-compressed files with the right Content-Encoding headers |

## Step 4 — Verify and report

- Rebuild, compare total / wasm / data sizes before vs after.
- Report a table: contributor, size before, size after, action taken.
- Note remaining large items that were kept deliberately and why.
