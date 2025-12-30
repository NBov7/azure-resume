#!/usr/bin/env python3
import json
import sys
import urllib.request
import urllib.error

SITE = "https://resume.nielsbovre.com"
API_COUNTER = f"{SITE}/api/GetResumeCounter"
API_HEALTH = f"{SITE}/api/health"

def get_json(url: str, timeout: int = 10) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "azure-resume-smoketest/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read().decode("utf-8")
            return json.loads(data)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"HTTP {e.code} for {url} | body={body[:200]}")
    except Exception as e:
        raise RuntimeError(f"Request failed for {url}: {e}")

def main() -> int:
    print("== Smoke test ==")
    print(f"Health:   {API_HEALTH}")
    health = get_json(API_HEALTH)
    print(f"  -> {health}")

    print(f"Counter:  {API_COUNTER}")
    counter = get_json(API_COUNTER)

    # Je response kan bv. {count: 123, source: "python"} of legacy shape zijn.
    # We tonen wat we krijgen en checken minimum "count".
    if "count" not in counter:
        raise RuntimeError(f"Counter JSON has no 'count': {counter}")

    print(f"  -> count={counter.get('count')} source={counter.get('source','(none)')} raw={counter}")

    print("✅ Smoke test OK")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"❌ Smoke test FAILED: {e}", file=sys.stderr)
        sys.exit(1)
