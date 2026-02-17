#!/bin/bash
# One-line setup for agent social media access
# Works with any agent structure

set -e

echo "🚀 Setting up social media access for your agent..."
echo ""

# Check if running on VPS
if [ ! -f /etc/os-release ]; then
    echo "❌ This script must run on your VPS, not your local machine"
    exit 1
fi

# 1. Install system dependencies
echo "📦 Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y xvfb x11vnc wget curl jq > /dev/null 2>&1

# 2. Install Chrome if not present
if ! command -v google-chrome &> /dev/null; then
    echo "📦 Installing Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb > /dev/null 2>&1
    rm google-chrome-stable_current_amd64.deb
else
    echo "✅ Chrome already installed"
fi

# 3. Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install --break-system-packages --quiet playwright 2>/dev/null || pip3 install --quiet playwright
python3 -m playwright install chromium > /dev/null 2>&1

# 4. Install noVNC if not present
if [ ! -d ~/noVNC ]; then
    echo "📦 Installing noVNC..."
    git clone -q https://github.com/novnc/noVNC.git ~/noVNC
    git clone -q https://github.com/novnc/websockify ~/noVNC/utils/websockify
else
    echo "✅ noVNC already installed"
fi

# 5. Create tools directory (works anywhere)
mkdir -p ~/.openclaw/tools

# 6. Download the social search script
echo "📥 Downloading social media search script..."
curl -sL https://raw.githubusercontent.com/zuocharles/openclaw-social-media-skill/main/agent-social-search.py \
    -o ~/.openclaw/tools/agent-social-search.py
chmod +x ~/.openclaw/tools/agent-social-search.py

# 7. Start Xvfb (virtual display)
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "🖥️  Starting virtual display..."
    Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &
    export DISPLAY=:99
else
    echo "✅ Virtual display already running"
fi

# 8. Start VNC server
if ! pgrep -x "x11vnc" > /dev/null; then
    echo "🔐 Starting VNC server..."
    x11vnc -display :99 -nopw -listen 0.0.0.0 -forever -shared > /tmp/x11vnc.log 2>&1 &
else
    echo "✅ VNC server already running"
fi

# 9. Start noVNC web interface
if ! pgrep -f "novnc_proxy" > /dev/null; then
    echo "🌐 Starting noVNC web interface..."
    ~/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /tmp/novnc.log 2>&1 &
else
    echo "✅ noVNC already running"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 NEXT STEP: Login to Social Media Accounts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANT: Create SEPARATE accounts for your agent"
echo "   Do NOT use your personal X/LinkedIn accounts"
echo ""
echo "1. On your Mac/PC, create SSH tunnel:"
echo "   ssh -i ~/path/to/key.pem -L 6080:localhost:6080 user@$(hostname -I | awk '{print $1}')"
echo ""
echo "2. Open in browser:"
echo "   http://localhost:6080/vnc.html"
echo ""
echo "3. In the VNC desktop that opens:"
echo "   - Click to open Chrome"
echo "   - Create NEW X account for your agent (e.g., YourAgentName_Bot)"
echo "   - Create NEW LinkedIn account for your agent"
echo "   - Close Chrome when done"
echo ""
echo "4. Then run this command to finalize:"
echo "   bash <(curl -s https://raw.githubusercontent.com/zuocharles/openclaw-social-media-skill/main/finalize-setup.sh)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
