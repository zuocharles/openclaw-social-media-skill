#!/bin/bash
# Example: Daily discovery script for your agent

echo "🔍 Running daily social media discovery..."

# Search for product mentions
echo "Searching for mentions..."
python3 ~/.openclaw/tools/agent-social-search.py "@OpenClaw OR OpenClaw" > /tmp/mentions.json

# Search for use cases
echo "Searching for use cases..."
python3 ~/.openclaw/tools/agent-social-search.py "OpenClaw use case" > /tmp/usecases.json

# Search for pain points
echo "Searching for pain points..."
python3 ~/.openclaw/tools/agent-social-search.py "browser automation stuck" > /tmp/pain-points.json

# Parse and summarize
echo ""
echo "📊 Results Summary:"
echo "=================="

# X results
x_count=$(cat /tmp/*.json | jq -s 'map(.x_results) | add | length')
echo "X/Twitter: $x_count tweets"

# LinkedIn results
li_count=$(cat /tmp/*.json | jq -s 'map(.linkedin_results) | add | length')
echo "LinkedIn: $li_count results"

# Total
total=$((x_count + li_count))
echo "Total: $total discoveries"

# Extract URLs
echo ""
echo "🔗 URLs Found:"
echo "=============="
cat /tmp/*.json | jq -r '.x_results[]? | "[\(.username)] \(.url)"' | head -5
cat /tmp/*.json | jq -r '.linkedin_results[]? | "\(.url)"' | head -3

echo ""
echo "✅ Discovery complete. Results saved to /tmp/*.json"
