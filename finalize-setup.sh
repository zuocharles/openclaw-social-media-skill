#!/bin/bash
# Finalize social media access setup (run after manual login)

set -e

echo "🔧 Finalizing setup..."
echo ""

# 1. Copy Chrome profile to automation directory
echo "📋 Copying authenticated Chrome profile..."
mkdir -p ~/.openclaw/chrome-automation
cp -r ~/.config/google-chrome/* ~/.openclaw/chrome-automation/ 2>/dev/null || \
    cp -r ~/.config/chromium/* ~/.openclaw/chrome-automation/ 2>/dev/null

# Verify cookies exist
if [ -f ~/.openclaw/chrome-automation/Default/Cookies ]; then
    COOKIE_SIZE=$(stat -f%z ~/.openclaw/chrome-automation/Default/Cookies 2>/dev/null || stat -c%s ~/.openclaw/chrome-automation/Default/Cookies)
    echo "✅ Found cookies file (${COOKIE_SIZE} bytes)"
else
    echo "❌ No cookies found - did you log into X and LinkedIn in VNC?"
    exit 1
fi

# 2. Start Chrome with remote debugging
echo "🌐 Starting Chrome with remote debugging..."

# Kill existing Chrome
pkill -9 chrome 2>/dev/null || true
sleep 2

# Start Chrome
export DISPLAY=:99
google-chrome \
    --user-data-dir=$HOME/.openclaw/chrome-automation \
    --remote-debugging-port=9222 \
    --no-sandbox \
    --disable-dev-shm-usage \
    about:blank > /tmp/chrome.log 2>&1 &

# Wait for Chrome to start
sleep 3

# Verify Chrome is running
if curl -s http://localhost:9222/json > /dev/null; then
    echo "✅ Chrome running with remote debugging"
else
    echo "❌ Chrome failed to start"
    exit 1
fi

# 3. Test the skill
echo "🧪 Testing social media search..."
TEST_RESULT=$(python3 ~/.openclaw/tools/agent-social-search.py "test" 2>&1 || true)

if echo "$TEST_RESULT" | grep -q "Found.*tweets"; then
    echo "✅ X/Twitter search working!"
else
    echo "⚠️  X/Twitter search may need login refresh"
fi

if echo "$TEST_RESULT" | grep -q "Found.*LinkedIn"; then
    echo "✅ LinkedIn search working!"
else
    echo "⚠️  LinkedIn search may need login refresh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Test the skill:"
echo "   python3 ~/.openclaw/tools/agent-social-search.py \"OpenClaw\""
echo ""
echo "📖 Read skill.md for integration with your agent:"
echo "   curl -s https://raw.githubusercontent.com/zuocharles/openclaw-social-media-skill/main/skill.md"
echo ""
echo "💡 Your agent can now search X and LinkedIn for \$0/month!"
echo ""
