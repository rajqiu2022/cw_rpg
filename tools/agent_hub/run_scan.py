#!/usr/bin/env python3
"""Run scanner to rebuild the artifacts table with new fields."""
import sys
from pathlib import Path

# Add tools/agent_hub/ to sys.path so `import db` and `import scanner` work
HUB = Path(__file__).resolve().parent
sys.path.insert(0, str(HUB))

import db
import scanner


def main():
    conn = db.connect()
    db.init_db(conn)
    scanner.scan_all(conn)
    conn.close()
    print("Scan complete. Artifacts table rebuilt with category/adopted_status.")


if __name__ == "__main__":
    main()
