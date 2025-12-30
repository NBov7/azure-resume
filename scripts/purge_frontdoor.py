#!/usr/bin/env python3
import os
import subprocess
import sys

# Vul deze 3 in (1x) of zet ze als env vars (aanrader)
RESOURCE_GROUP = os.getenv("AFD_RESOURCE_GROUP", "")
AFD_PROFILE = os.getenv("AFD_PROFILE_NAME", "")
AFD_ENDPOINT = os.getenv("AFD_ENDPOINT_NAME", "")

# Wat je wil purgen (kan je uitbreiden)
DEFAULT_PATHS = [
    "/*",                 # brute-force: alles
    # "/index.html",
    # "/css/*",
    # "/js/*",
]

def run(cmd: list[str]) -> None:
    print(" ".join(cmd))
    subprocess.run(cmd, check=True)

def main() -> int:
    if not (RESOURCE_GROUP and AFD_PROFILE and AFD_ENDPOINT):
        print("❌ Missing config. Set env vars:", file=sys.stderr)
        print("  export AFD_RESOURCE_GROUP='...'", file=sys.stderr)
        print("  export AFD_PROFILE_NAME='...'", file=sys.stderr)
        print("  export AFD_ENDPOINT_NAME='...'", file=sys.stderr)
        return 1

    paths = DEFAULT_PATHS
    print("== Front Door cache purge ==")
    print(f"RG:       {RESOURCE_GROUP}")
    print(f"Profile:  {AFD_PROFILE}")
    print(f"Endpoint: {AFD_ENDPOINT}")
    print(f"Paths:    {paths}")

    cmd = [
        "az", "afd", "endpoint", "purge",
        "--resource-group", RESOURCE_GROUP,
        "--profile-name", AFD_PROFILE,
        "--endpoint-name", AFD_ENDPOINT,
        "--content-paths", *paths
    ]
    run(cmd)

    print("✅ Purge requested")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as e:
        print(f"❌ Purge FAILED (az exit code {e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)
