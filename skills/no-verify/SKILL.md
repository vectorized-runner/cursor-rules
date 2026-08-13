---
name: no-verify
description: Edit-only mode — make the change, skip the compile / play-mode / screenshot loop, and hand the check off to the user. Use only when the user explicitly invokes /no-verify.
disable-model-invocation: true
---

# No-Verify Mode

The user checks this change themselves. Make the edit, then stop and report.

Holds for the rest of the conversation, until the user says otherwise or invokes `/full-verify`.

## Skip

| Skip | Tools |
|------|-------|
| Compile / console round-trips | `get_compilation_errors`, `get_console_logs`, `refresh_asset_db` |
| Running anything | `play_scene`, `run_tests`, `build_player` |
| Visual checks | `get_game_screenshot`, `get_editor_screenshot`, `compare_screenshots`, opening a scene just to look at it |

Also skip asking "want me to verify?" — finish the edit and hand off instead.

This suspends `no-code-built-ui` §5 ("Screenshot or it didn't happen") and any run-it-to-check step in the project's own rules. **Nothing else relaxes** — prefab-authored UI, allocation discipline, the non-null contract, and every other standard still apply in full. Skipping the check is not licence to write it sloppily; it is the opposite.

## Still do

- **Read enough surrounding code to get it right the first time.** Reading files is free and is not verification — not being able to run the change makes reading *more* important, not less.
- **Prefab authoring via Unity MCP.** `instantiate_prefab` → edit → `apply_prefab_overrides` → delete the instance is how a UI change is made at all, not a check on it. Screenshotting the result is the check, and that is the part being skipped.
- **Static lint** on files you edited — no engine needed.
- **Re-read your own diff** for typos, wrong field names, unwired serialized refs.

## Hand off

End the turn with three short sections:

**Changed** — files touched, one line each.

**Check this** — exact steps: which scene to open, what to click, what should happen.

**Unverified** — what you couldn't confirm without running it, and the most likely place this breaks.

Keep it tight. The point of this mode is speed.
