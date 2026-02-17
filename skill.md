# Social Media Search Skill

Search X/Twitter and LinkedIn for mentions, use cases, pain points, and trending topics.

**Cost:** $0/month (vs $200/month for Twitter API)

---

## When to Use This Skill

Use this skill when you need to:
- 🔍 **Discover use cases** - See what people are building with your product
- 💬 **Find mentions** - Track what people say about your product
- 😫 **Identify pain points** - See what problems people are struggling with
- 📈 **Monitor trends** - Track trending topics in your space
- 🤝 **Find collaborators** - Discover people working on similar projects
- 📊 **Market research** - Understand what your audience cares about

**Do NOT use this for:**
- Posting to social media (this is read-only)
- Real-time monitoring (sessions expire every ~30 days)
- High-frequency searches (keep it reasonable, 100-200/day max)

---

## How to Use

### Basic Search

```bash
python3 ~/.openclaw/tools/agent-social-search.py "your search query"
```

**Returns JSON:**
```json
{
  "query": "OpenClaw",
  "x_results": [
    {
      "platform": "X",
      "text": "Tweet content...",
      "username": "username",
      "url": "https://x.com/username/status/123...",
      "index": 1
    }
  ],
  "linkedin_results": [
    {
      "platform": "LinkedIn",
      "text": "Post content...",
      "url": "https://www.linkedin.com/in/username",
      "index": 1
    }
  ],
  "total": 13
}
```

---

## Common Use Cases

### 1. Daily Discovery Scan

**When:** Every morning during idle time (no active tasks)

**What to search:**
```bash
# Product mentions
python3 ~/.openclaw/tools/agent-social-search.py "@YourProduct OR YourProduct"

# Use cases
python3 ~/.openclaw/tools/agent-social-search.py "YourProduct use case"

# Pain points
python3 ~/.openclaw/tools/agent-social-search.py "browser automation stuck"

# Trending topics
python3 ~/.openclaw/tools/agent-social-search.py "autonomous agents 2026"
```

**What to do with results:**
1. Log to `memory/YYYY-MM-DD.md` under "Discovery Scan"
2. Add each discovery to `MEMORY.md` Discovery Insights table
3. Track count toward 15+ sources minimum
4. When 15+ sources reached, analyze for patterns (3+ mentions)
5. If patterns found, propose to user

### 2. Pain Point Research

**When:** Before building a new feature

**Example:**
```bash
# Find what people struggle with
python3 ~/.openclaw/tools/agent-social-search.py "browser automation fails"
python3 ~/.openclaw/tools/agent-social-search.py "ai agents broken"

# Filter for pain signals
cat results.json | jq -r '.x_results[] | select(.text | contains("stuck") or contains("fail") or contains("wish")) | .text'
```

### 3. Competitive Analysis

**When:** Researching competitors or alternatives

**Example:**
```bash
# See what people say about competitors
python3 ~/.openclaw/tools/agent-social-search.py "Competitor vs YourProduct"
python3 ~/.openclaw/tools/agent-social-search.py "Competitor problems"
```

### 4. User Discovery

**When:** Looking for potential users, collaborators, or case studies

**Example:**
```bash
# Find power users
python3 ~/.openclaw/tools/agent-social-search.py "built with YourProduct"
python3 ~/.openclaw/tools/agent-social-search.py "YourProduct automation"
```

---

## Integration with Agent Workflow

### In HEARTBEAT.md

Add to your discovery routine:

```markdown
## Discovery Scan (if TODO empty)

### Social Media Intelligence
```bash
# Search X and LinkedIn
python3 ~/.openclaw/tools/agent-social-search.py "@YourProduct OR YourProduct" > /tmp/mentions.json
python3 ~/.openclaw/tools/agent-social-search.py "YourProduct usecase" > /tmp/usecases.json

# Parse and log
cat /tmp/*.json | jq -r '.x_results[] | "[X] @\(.username): \(.text) - \(.url)"' >> /tmp/discoveries.txt
cat /tmp/*.json | jq -r '.linkedin_results[] | "[LI] \(.url)"' >> /tmp/discoveries.txt
```

### Log to memory
1. Append to memory/YYYY-MM-DD.md
2. Update MEMORY.md Discovery Insights table
3. Check if 15+ sources reached
```

### In SOUL.md (Step 3B - Discovery)

```markdown
**Social Media Discovery:**

When TODO is empty, search for opportunities:

```bash
python3 ~/.openclaw/tools/agent-social-search.py "product mentions"
```

**After each scan:**
1. Log findings to memory/YYYY-MM-DD.md
2. Update MEMORY.md Discovery Insights table (add row, increment count)
3. Check count: < 15? Continue. ≥15? Analyze patterns
```

---

## Parsing Results

### Extract All Tweets

```bash
cat results.json | jq -r '.x_results[] | .text'
```

### Extract All URLs

```bash
# X URLs
cat results.json | jq -r '.x_results[] | .url'

# LinkedIn URLs
cat results.json | jq -r '.linkedin_results[] | .url'
```

### Filter by Keywords

```bash
# Pain points
cat results.json | jq -r '.x_results[] | select(.text | contains("stuck") or contains("fail")) | .text'

# Feature requests
cat results.json | jq -r '.x_results[] | select(.text | contains("wish") or contains("need")) | .text'

# Positive mentions
cat results.json | jq -r '.x_results[] | select(.text | contains("love") or contains("amazing")) | .text'
```

### Get Usernames

```bash
cat results.json | jq -r '.x_results[] | @"@\(.username)"'
```

---

## Performance

**Per Search:**
- Time: ~25 seconds
- X/Twitter: 8-10 tweets with URLs
- LinkedIn: 3+ profiles/posts with URLs
- Total: 11-13 results average
- Cost: $0

**Session Lifetime:**
- Typical: 25-35 days
- Refresh: 5 minutes via VNC
- Uptime: 99%+

---

## Error Handling

### Session Expired

**Symptom:** Empty results or login pages

**How to detect:**
```bash
python3 ~/.openclaw/tools/agent-social-search.py "test" | grep "Found 0"
```

**What to do:**
1. Log: "Social media sessions expired, need manual refresh"
2. Alert user: "Please refresh sessions via VNC (5 min)"
3. Don't retry until sessions refreshed

### Chrome Not Running

**Symptom:** Connection refused error

**How to detect:**
```bash
curl -s http://localhost:9222/json || echo "Chrome not running"
```

**What to do:**
1. Log: "Chrome CDP not responding"
2. Try restart: `pkill -9 chrome && DISPLAY=:99 google-chrome --remote-debugging-port=9222 ...`
3. If fails: Alert user

---

## Maintenance Schedule

### Daily
- Use the skill for discovery (no maintenance needed)

### Every 30 Days
- **User action required:** Refresh sessions via VNC (5 minutes)
- Agent should detect when sessions expire and alert user

### Health Check

Run this to verify skill is working:

```bash
python3 ~/.openclaw/tools/agent-social-search.py "test" && echo "✅ Skill working"
```

---

## Cost Savings

| Method | Monthly | Annual | Notes |
|--------|---------|--------|-------|
| **This skill** | **$0** | **$0** | 30-day session refresh |
| Twitter API | $200 | $2,400 | 10K tweets/month limit |
| LinkedIn API | N/A | N/A | No individual access |

**Annual savings: $2,400**

---

## Setup

See [README.md](./README.md) for complete setup instructions.

**Quick check if installed:**
```bash
test -f ~/.openclaw/tools/agent-social-search.py && echo "✅ Installed"
curl -s http://localhost:9222/json > /dev/null && echo "✅ Chrome running"
```

---

## Examples

See `/examples` directory for:
- `discovery.sh` - Daily discovery script
- `agent_integration.py` - Python integration example

---

## Limitations

- **Read-only:** Cannot post to social media
- **Session lifetime:** ~30 days (manual refresh required)
- **Rate limits:** Stay reasonable (100-200 searches/day)
- **Platform changes:** X/LinkedIn may change selectors (update script if needed)
- **VPS only:** Requires server with virtual display (Xvfb)

---

## Support

**Questions?** Open an issue: https://github.com/zuocharles/agent-social-media-skill/issues

**Want to contribute?** PRs welcome!

---

**Created by:** [Charles](https://github.com/zuocharles)
**License:** MIT
**Last Updated:** 2026-02-17
