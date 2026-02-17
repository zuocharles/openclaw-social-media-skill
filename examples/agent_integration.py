#!/usr/bin/env python3
"""
Example: How to integrate social media search into your agent
"""

import subprocess
import json
from datetime import datetime

def search_social(query):
    """Search X and LinkedIn for a query"""
    result = subprocess.run(
        ['python3', '/home/ubuntu/.openclaw/tools/agent-social-search.py', query],
        capture_output=True,
        text=True
    )

    # Parse JSON from stdout
    try:
        data = json.loads(result.stdout)
        return data
    except json.JSONDecodeError:
        print(f"Error parsing results: {result.stderr}")
        return None

def log_discovery(query, results):
    """Log discoveries to daily memory file"""
    if not results:
        return

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    date_str = datetime.now().strftime("%Y-%m-%d")

    log_file = f"/home/ubuntu/memory/{date_str}.md"

    with open(log_file, "a") as f:
        f.write(f"\n## Discovery Scan - {timestamp}\n\n")
        f.write(f"**Query:** {query}\n\n")

        # Log X results
        if results['x_results']:
            f.write("### X/Twitter\n\n")
            for tweet in results['x_results']:
                f.write(f"- [@{tweet['username']}]({tweet['url']}): {tweet['text'][:100]}...\n")

        # Log LinkedIn results
        if results['linkedin_results']:
            f.write("\n### LinkedIn\n\n")
            for post in results['linkedin_results']:
                f.write(f"- [{post['url']}]({post['url']})\n")

        f.write(f"\n**Total:** {results['total']} results\n")

def main():
    """Example agent discovery routine"""

    queries = [
        "@OpenClaw OR OpenClaw",
        "OpenClaw use case",
        "browser automation stuck",
        "autonomous agents 2026"
    ]

    all_discoveries = []

    print("🔍 Starting discovery scan...\n")

    for query in queries:
        print(f"Searching: {query}")
        results = search_social(query)

        if results:
            print(f"  ✅ Found {results['total']} results")
            log_discovery(query, results)
            all_discoveries.append(results)
        else:
            print(f"  ❌ Failed")

    print(f"\n✅ Discovery complete!")
    print(f"📊 Total queries: {len(queries)}")
    print(f"📊 Total results: {sum(r['total'] for r in all_discoveries)}")

if __name__ == "__main__":
    main()
