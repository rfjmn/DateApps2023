#!/usr/bin/env python3
"""Run the checked-in build/test inventory from any working directory."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TARGETS = json.loads((ROOT / "quality-targets.json").read_text())

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="Print the CI matrix without running tools")
    parser.add_argument("--index", type=int, help="Run one zero-based entry")
    args = parser.parse_args()
    if args.list:
        print(json.dumps({"include": [{"index": i, "name": t["name"]} for i, t in enumerate(TARGETS)]}))
        return
    if args.index is not None and not 0 <= args.index < len(TARGETS):
        parser.error("index is outside quality-targets.json")
    indices = range(len(TARGETS)) if args.index is None else [args.index]
    for index in indices:
        target = TARGETS[index]
        print(f"[{index}] {target['name']}", flush=True)
        with tempfile.TemporaryDirectory(prefix="repository-quality-") as scratch:
            if target["kind"] == "package":
                command = ["swift", "test", "--package-path", target["path"],
                           "--scratch-path", scratch, "--jobs", "2"]
            else:
                container = "workspace" if target.get("workspace") else "project"
                command = ["xcodebuild", "-" + container, target[container],
                           "-scheme", target["scheme"], "-destination",
                           "generic/platform=iOS Simulator", "-derivedDataPath", scratch,
                           "-jobs", "2", "CODE_SIGNING_ALLOWED=NO", "build"]
            subprocess.run(command, cwd=ROOT, check=True)

if __name__ == "__main__":
    main()
