#!/usr/bin/env bash
# Catch Shared naming drift in company cursor rules before it ships.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 - "$ROOT" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
rules = root / "rules"
readme = root / "README.md"
errors: list[str] = []


def die(msg: str) -> None:
    errors.append(msg)
    print(f"lint-rules: {msg}", file=sys.stderr)


print(f"lint-rules: scanning {rules}")

# --- Assets/ paths only allowed on globs: frontmatter lines ---
for path in sorted(rules.rglob("*.mdc")):
    in_fm = False
    for i, line in enumerate(path.read_text().splitlines(), 1):
        if i == 1 and line.strip() == "---":
            in_fm = True
            continue
        if in_fm and line.strip() == "---":
            in_fm = False
            continue
        if "Assets/" not in line:
            continue
        if in_fm and line.startswith("globs:"):
            continue
        die(f"Assets/ path in shared rule body (use assembly + type names): {path}:{i}:{line}")

# --- No bare MonkeyTilt.Shared assembly (feature suffix required) ---
allow = [
    re.compile(r"namespace\s+`?MonkeyTilt\.Shared`?"),
    re.compile(r"MonkeyTilt\.Shared\.[A-Za-z0-9_.]+"),
]
bare = re.compile(r"MonkeyTilt\.Shared")
for path in sorted(rules.rglob("*.mdc")):
    prev = ""
    for i, line in enumerate(path.read_text().splitlines(), 1):
        # Join with previous line so "namespace\n`MonkeyTilt.Shared`" wraps are allowed.
        cleaned = f"{prev} {line}"
        for pat in allow:
            cleaned = pat.sub("", cleaned)
        if bare.search(cleaned) and bare.search(line):
            die(
                "bare assembly MonkeyTilt.Shared "
                f"(need MonkeyTilt.Shared.<Feature>): {path}:{i}:{line}"
            )
        prev = line

# --- Foundation + SingletonBehaviour must say SharedSingletonBehaviour ---
for path in sorted(rules.rglob("*.mdc")):
    for i, line in enumerate(path.read_text().splitlines(), 1):
        if "MonkeyTilt.Foundation" not in line:
            continue
        if "SingletonBehaviour" in line and "SharedSingletonBehaviour" not in line:
            die(f"Shared singleton base must be SharedSingletonBehaviour: {path}:{i}:{line}")

# --- Every MonkeyTilt.* assembly named in a rule must exist in BuildTools ---
# Keep in sync with the asmdefs under Assets/BuildTools in the unity-buildtools repo.
KNOWN_ASSEMBLIES = {
    "MonkeyTilt.Foundation",
    "MonkeyTilt.Shared.AssetCatalog",
    "MonkeyTilt.Shared.AssetCatalog.Editor",
    "MonkeyTilt.Shared.BuildPipeline.Editor",
    "MonkeyTilt.Shared.DevOverlays",
    "MonkeyTilt.Shared.DevOverlays.Editor",
    "MonkeyTilt.Shared.EditorTools.Editor",
    "MonkeyTilt.Shared.Guards.Editor",
    "MonkeyTilt.Shared.NumericInput",
    "MonkeyTilt.Shared.NumericInput.Editor",
    "MonkeyTilt.Shared.Optimization.Editor",
}
assembly_token = re.compile(r"`(MonkeyTilt\.[A-Za-z0-9_.]+)`")
for path in sorted(rules.rglob("*.mdc")):
    for i, line in enumerate(path.read_text().splitlines(), 1):
        for m in assembly_token.finditer(line):
            name = m.group(1)
            if name == "MonkeyTilt.Shared":
                continue  # namespace, checked by the bare-assembly rule above
            if name not in KNOWN_ASSEMBLIES:
                die(f"unknown assembly `{name}` (not in KNOWN_ASSEMBLIES): {path}:{i}:{line}")

# --- Frontmatter ---
# A glob may key only on a Unity-mandated folder (Editor) or a folder convention the rule
# itself states (Contracts). Never on an assumed project layout.
ALLOWED_GLOBS = {"**/*.cs", "**/Editor/**/*.cs", "**/Contracts/**/*.cs", "**/*.md"}
for path in sorted(rules.rglob("*.mdc")):
    text = path.read_text()
    rel = path.relative_to(root)
    if not text.startswith("---\n"):
        die(f"missing frontmatter: {rel}")
        continue
    end = text.find("\n---\n", 4)
    if end < 0:
        die(f"unclosed frontmatter: {rel}")
        continue
    fm = text[4:end]
    if not re.search(r"^description:\s+\S", fm, re.M):
        die(f"missing description frontmatter: {rel}")
    always = re.search(r"^alwaysApply:\s*(true|false)\s*$", fm, re.M)
    if not always:
        die(f"missing/invalid alwaysApply frontmatter: {rel}")
    if re.search(r"^globs:\s*$", fm, re.M):
        die(f"empty globs: key (omit the key for alwaysApply or description-attached rules): {rel}")
    globs_line = re.search(r"^globs:\s+(\S.*)$", fm, re.M)
    if globs_line:
        if always and always.group(1) == "true":
            die(f"alwaysApply: true must not also have globs: {rel}")
        for g in (g.strip() for g in globs_line.group(1).split(",")):
            if g not in ALLOWED_GLOBS:
                die(f"glob assumes project layout ({g}); allowed: {sorted(ALLOWED_GLOBS)}: {rel}")

# --- Every rule ends with an Agent checklist ---
for path in sorted(rules.rglob("*.mdc")):
    if not re.search(r"^## Agent checklist\s*$", path.read_text(), re.M):
        die(f"missing '## Agent checklist' section: {path.relative_to(root)}")

# --- Length budget ---
for path in sorted(rules.rglob("*.mdc")):
    lines = len(path.read_text().splitlines())
    if lines > 130:
        die(f"rule too long ({lines} lines, budget ~120): {path.relative_to(root)}")

# --- README must not restate which files are alwaysApply ---
readme_text = readme.read_text()
for pat in (
    r"only .+alwaysApply",
    r"alwaysApply: true \(only",
    r"only `00-mindset`",
):
    for m in re.finditer(pat, readme_text):
        # locate line
        line_no = readme_text.count("\n", 0, m.start()) + 1
        line = readme_text.splitlines()[line_no - 1]
        die(f"README restates which rules are alwaysApply (use frontmatter only): {readme}:{line_no}:{line}")

if errors:
    print("lint-rules: FAILED", file=sys.stderr)
    sys.exit(1)

print("lint-rules: OK")
PY
