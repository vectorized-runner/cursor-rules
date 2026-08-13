---
name: full-verify
description: Full verification loop — compile, play mode, console, and harness screenshot read before claiming a change is done. Use only when the user explicitly invokes /full-verify.
disable-model-invocation: true
---

# Full-Verify Mode

Nothing is done until it has been run. Holds for the rest of the conversation.

## Loop

1. Make the change.
2. `refresh_asset_db` → `get_compilation_errors`. Zero errors before going further.
3. **UI change** — open the project's UI harness / review scene (or the target scene), feed representative data including stress cases (long names, large values, full lists), `get_game_screenshot`, and **read the image**: positions, overlap, truncation, and fonts against the project's design reference.
4. **Behaviour change** — `play_scene` at the project's reference resolution, exercise the path, `get_console_logs`, `stop_scene`. Views fail loudly on missing serialized refs, so wiring breaks surface here.
5. Anything failed → fix and rerun from step 2. Don't report a failure you could have fixed.

## Report

Attach the screenshot. State what you ran, what you saw, and what the loop could **not** cover — live backend responses, real-device performance, and anything else that needs the user.
