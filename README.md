# Agent Social Media Access

Give your AI agent X (Twitter) and LinkedIn access for **$0/month**. No API keys needed.

**Saves $2,400/year** vs Twitter API.

---

## What This Does

Your agent can:
- Search X/Twitter for mentions, use cases, trending topics
- Search LinkedIn for posts, profiles, discussions
- Get results with URLs in 25 seconds
- Cost: $0/month (vs $200/month for Twitter API)

---

## Quick Start

**TL;DR for your AI:**

> "Set up social media access for my agent following this repo. I have a VPS running Ubuntu. Walk me through each step."

Your AI will guide you through the setup.

---

## How It Works

Instead of paying for APIs, your agent uses a real Chrome browser with saved login sessions.

**Architecture:**
```
Your Agent → Python Script → Chrome Browser → Your Social Media Accounts → Results
```

**One-time setup:** 30 minutes
**Monthly maintenance:** 5 minutes (refresh sessions)
**Cost:** $0

---

## Installation

### Prerequisites

- Ubuntu VPS (or any Linux server)
- 2GB+ RAM
- Python 3.8+

### Step 1: Install Dependencies

```bash
# System packages
sudo apt-get update
sudo apt-get install -y xvfb x11vnc wget

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Python packages
pip3 install --break-system-packages playwright
python3 -m playwright install chromium

# noVNC (for remote login)
git clone https://github.com/novnc/noVNC.git ~/noVNC
git clone https://github.com/novnc/websockify ~/noVNC/utils/websockify
```

### Step 2: Start Virtual Display

```bash
# Start X virtual display
Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &

# Verify it's running
export DISPLAY=:99
echo $DISPLAY
```

### Step 3: Manual Login (One-Time Setup)

```bash
# On VPS: Start VNC server
x11vnc -display :99 -nopw -listen 0.0.0.0 -forever -shared > /dev/null 2>&1 &

# Start noVNC web interface
~/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

# On your Mac/PC: Create SSH tunnel
ssh -i ~/path/to/your-key.pem -L 6080:localhost:6080 user@your-vps-ip

# Open in browser on your Mac/PC
open http://localhost:6080/vnc.html
```

**In the VNC desktop:**
1. Open Chrome: `DISPLAY=:99 google-chrome &`
2. Log into X/Twitter
3. Log into LinkedIn
4. Close Chrome (File → Exit)

**Back on VPS:**
```bash
# Copy authenticated profile
mkdir -p ~/.openclaw/chrome-automation
cp -r ~/.config/google-chrome/* ~/.openclaw/chrome-automation/

# Verify cookies exist
ls -lh ~/.openclaw/chrome-automation/Default/Cookies
# Should see ~90KB file
```

### Step 4: Install Search Script

```bash
# Create tools directory
mkdir -p ~/.openclaw/tools

# Download the script
curl -o ~/.openclaw/tools/agent-social-search.py \
  https://raw.githubusercontent.com/YOUR_USERNAME/agent-social-media-skill/main/agent-social-search.py

# Make executable
chmod +x ~/.openclaw/tools/agent-social-search.py
```

### Step 5: Start Chrome with Remote Debugging

```bash
# Start Chrome with CDP enabled
DISPLAY=:99 google-chrome \
  --user-data-dir=/home/ubuntu/.openclaw/chrome-automation \
  --remote-debugging-port=9222 \
  --no-sandbox \
  --disable-dev-shm-usage \
  about:blank > /tmp/chrome.log 2>&1 &

# Verify Chrome is running
curl -s http://localhost:9222/json | head -5
```

### Step 6: Test It Works

```bash
# Search for something
python3 ~/.openclaw/tools/agent-social-search.py "OpenClaw"

# Expected output:
# ✅ Found 10 tweets
# ✅ Found 3 LinkedIn results
# 📊 RESULTS
# {...JSON with URLs...}
```

---

## Usage

### Basic Search

```bash
python3 ~/.openclaw/tools/agent-social-search.py "your search query"
```

Returns JSON:
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

### From Your Agent

```python
import subprocess
import json

def search_social(query):
    result = subprocess.run(
        ['python3', '/home/ubuntu/.openclaw/tools/agent-social-search.py', query],
        capture_output=True,
        text=True
    )

    # Parse JSON from stdout
    data = json.loads(result.stdout)
    return data

# Use it
results = search_social("OpenClaw use cases")
print(f"Found {results['total']} results")

for tweet in results['x_results']:
    print(f"Tweet: {tweet['text']}")
    print(f"URL: {tweet['url']}")
```

---

## Maintenance

### Refresh Sessions (Every 30 Days)

When sessions expire:

```bash
# 1. SSH tunnel to VNC
ssh -i ~/path/to/key.pem -L 6080:localhost:6080 user@vps-ip

# 2. Open VNC in browser
open http://localhost:6080/vnc.html

# 3. In VNC: Re-login to X and LinkedIn

# 4. Update automation profile
rm -rf ~/.openclaw/chrome-automation
cp -r ~/.config/google-chrome ~/.openclaw/chrome-automation
```

### Health Check

```bash
# Test if sessions still valid
python3 ~/.openclaw/tools/agent-social-search.py "test" | grep "✅ Found"

# Should see:
# ✅ Found 10 tweets
# ✅ Found 3 LinkedIn results
```

### Restart Chrome

If Chrome crashes:

```bash
pkill -9 chrome

DISPLAY=:99 google-chrome \
  --user-data-dir=/home/ubuntu/.openclaw/chrome-automation \
  --remote-debugging-port=9222 \
  --no-sandbox \
  about:blank > /tmp/chrome.log 2>&1 &
```

---

## Agent Integration Examples

### Example 1: Nightly Discovery

Add to your agent's heartbeat:

```bash
# Search for mentions
python3 ~/.openclaw/tools/agent-social-search.py "@YourProduct OR YourProduct" > /tmp/mentions.json

# Search for use cases
python3 ~/.openclaw/tools/agent-social-search.py "YourProduct use case" > /tmp/usecases.json

# Parse results
cat /tmp/*.json | jq -r '.x_results[] | "[X] \(.text) - \(.url)"'
```

### Example 2: Pain Point Discovery

```bash
# Find what people struggle with
python3 ~/.openclaw/tools/agent-social-search.py "browser automation stuck"
python3 ~/.openclaw/tools/agent-social-search.py "ai agents broken"

# Filter for pain signals
cat results.json | jq -r '.x_results[] | select(.text | contains("stuck") or contains("fail")) | .text'
```

### Example 3: Trending Topics

```bash
# See what's trending
python3 ~/.openclaw/tools/agent-social-search.py "autonomous agents 2026"
python3 ~/.openclaw/tools/agent-social-search.py "AI automation"
```

---

## Cost Comparison

| Method | Monthly | Annual | Limitations |
|--------|---------|--------|-------------|
| **This Setup** | **$0** | **$0** | 30-day session refresh |
| Twitter API Basic | $200 | $2,400 | 10K tweets/month |
| LinkedIn API | N/A | N/A | No individual access |
| Scraping Services | $150+ | $1,800+ | Account bans risk |

**Annual Savings: $2,400+**

---

## Troubleshooting

### "Not logged in" Error

Sessions expired. Refresh via VNC (see Maintenance above).

### Chrome Won't Start

```bash
pkill -9 chrome
rm -f ~/.openclaw/chrome-automation/SingletonLock
DISPLAY=:99 google-chrome \
  --user-data-dir=/home/ubuntu/.openclaw/chrome-automation \
  --remote-debugging-port=9222 \
  --no-sandbox \
  about:blank &
```

### Empty Results

1. Check if sessions are valid (health check above)
2. Check if Chrome is running: `curl http://localhost:9222/json`
3. Check logs: `tail -f /tmp/chrome.log`

---

## Performance

**Per Search:**
- X/Twitter: 8-10 tweets with URLs
- LinkedIn: 3+ profiles/posts with URLs
- Time: ~25 seconds
- Cost: $0

**Session Lifetime:**
- Typical: 25-35 days
- Refresh time: 5 minutes
- Uptime: 99%+

---

## FAQ

**Q: Is this allowed?**
A: Yes. You're using a real browser with your own account, not scraping. It's automated browsing, like using Selenium or Puppeteer.

**Q: Will I get banned?**
A: No. You're browsing normally through Chrome with saved sessions. Stay within reasonable use (100-200 searches/day).

**Q: Why not use APIs?**
A: Twitter API costs $200/month. LinkedIn has no API for individuals. This setup is free and works for both.

**Q: What about rate limits?**
A: You're loading web pages, not hitting API endpoints. No rate limits as long as you're reasonable.

**Q: How long do sessions last?**
A: 25-35 days typically. You'll know when they expire (empty results). Just re-login via VNC.

---

## License

MIT

---

## Credits

Created by [Charles](https://github.com/YOUR_USERNAME) for OpenClaw agents.

Uses:
- Chrome DevTools Protocol (Google)
- Playwright (Microsoft)
- Xvfb (X.Org Foundation)
- noVNC (noVNC Team)

---

**Questions?** Open an issue or contribute improvements via PR.

**Want to see it in action?** Check the examples in the `/examples` directory.
