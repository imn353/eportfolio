"""run_pipeline.py - Orchestrate all 5 pipeline stages in order.

Runs each stage as a subprocess so failures are isolated (one bad stage
won't corrupt the orchestrator's Python state) and so each script's own
stdout streams live to the terminal.
"""

import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
SCRIPTS_DIR = PROJECT_ROOT / "scripts"

# Ordered list of (phase number, friendly name, script filename).
PHASES = [
    (1, "Ingest",     "01_ingest.py"),
    (2, "Clean",      "02_clean.py"),
    (3, "Transform",  "03_transform.py"),
    (4, "Load",       "04_load.py"),
    (5, "Visualise",  "05_visualise.py"),
]


def main() -> None:
    for number, name, filename in PHASES:
        script_path = SCRIPTS_DIR / filename

        print(f"\n=== Running Phase {number}: {name} ===\n")

        # Use sys.executable so the child uses the same Python interpreter
        # as the orchestrator. check=False because we want to handle the
        # error ourselves with a clear message instead of a raw traceback.
        result = subprocess.run([sys.executable, str(script_path)], check=False)

        if result.returncode != 0:
            print(
                f"\n!!! Pipeline aborted at Phase {number}: {name} !!!\n"
                f"    Script:      {script_path}\n"
                f"    Exit code:   {result.returncode}\n"
                f"    See the output above for the underlying error.",
                file=sys.stderr,
            )
            sys.exit(result.returncode)

        print(f"\n=== Phase {number} Complete ===")

    print("\nAll 5 phases completed successfully.")


if __name__ == "__main__":
    main()
