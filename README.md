# XHS AI Toolkit

<p align="center">
  <b>Make AI understand your Xiaohongshu (RedNote)</b>
</p>

<p align="center">
  <a href="README_CN.md">简体中文</a> | English
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey.svg">
  <img alt="Python" src="https://img.shields.io/badge/python-3.10+-green.svg">
  <img alt="MCP" src="https://img.shields.io/badge/MCP-compatible-purple.svg">
</p>

---

AI-powered toolkit for **Xiaohongshu (小红书 / RedNote)** that turns your favorite posts into AI memory.

- **MCP Integration** — Search, browse, comment via AI assistants
- **Trend Tracking** — Auto-generate topic reports with engagement analytics
- **Memory Export** — Convert your liked/saved posts into AI-searchable knowledge base

Built on [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) and [XHS-Downloader](https://github.com/JoeanAmier/XHS-Downloader).

## Features

| Feature | Description |
|---------|-------------|
| Search | Search posts by keywords |
| Feed | Get homepage recommendations |
| Post Details | Fetch post content, comments, engagement stats |
| Comment | Post comments to notes |
| User Profile | Get user info and their posts |
| Trend Tracking | Auto-generate topic analysis reports |
| Long Image Export | Export posts as annotated JPG long images |
| Memory Export | Export liked/saved posts as Markdown for AI memory |

## Quick Start

### 1. Install xiaohongshu-mcp

Download from [GitHub Releases](https://github.com/xpzouying/xiaohongshu-mcp/releases):

```bash
# Linux x64
wget https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-mcp-linux-amd64.tar.gz
wget https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-login-linux-amd64.tar.gz

# macOS ARM
wget https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-mcp-darwin-arm64.tar.gz
wget https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-login-darwin-arm64.tar.gz
```

Install:

```bash
mkdir -p ~/.local/bin
tar -xzf xiaohongshu-mcp-*.tar.gz -C ~/.local/bin/
tar -xzf xiaohongshu-login-*.tar.gz -C ~/.local/bin/

cd ~/.local/bin
mv xiaohongshu-mcp-* xiaohongshu-mcp
mv xiaohongshu-login-* xiaohongshu-login
chmod +x xiaohongshu-mcp xiaohongshu-login
```

### 2. Install This Toolkit

```bash
# Clone to OpenClaw workspace
git clone https://github.com/zhjiang22/openclaw-xhs.git
cp -r openclaw-xhs ~/.openclaw/workspace/skills/xiaohongshu

# Or use symlink
ln -s /path/to/openclaw-xhs ~/.openclaw/workspace/skills/xiaohongshu

# Verify installation
cd ~/.openclaw/workspace/skills/xiaohongshu/scripts
./install-check.sh
```

### 3. Login (Get Cookies)

**Option A: Desktop Environment**

```bash
./login.sh  # Opens browser, scan QR code with Xiaohongshu app
```

**Option B: Headless Server**

Get cookies on your local machine, then copy to server:

```bash
# On local machine with GUI
./xiaohongshu-login
# Cookies saved to /tmp/cookies.json

# Copy to server
scp /tmp/cookies.json user@server:~/.xiaohongshu/cookies.json
```

### 4. Start Service

```bash
./start-mcp.sh              # Headless mode
./start-mcp.sh --headless=false  # Show browser (debug)
```

Service runs at `http://localhost:18060/mcp`.

## Usage

### Basic Commands

```bash
./status.sh                    # Check login status
./search.sh "coffee"           # Search posts
./recommend.sh                 # Get recommendations
./post-detail.sh <id> <token>  # Get post details
./comment.sh <id> <token> "Great post!"  # Comment
./user-profile.sh <user_id>    # Get user profile
```

### Trend Tracking

Auto-search trending posts and generate analysis reports:

```bash
./track-topic.sh "AI" --limit 10
./track-topic.sh "travel" --limit 5 --output report.md
./track-topic.sh "iPhone" --limit 5 --feishu  # Export to Feishu
```

### MCP Tools

| Tool | Description |
|------|-------------|
| `check_login_status` | Check login status |
| `search_feeds` | Search posts |
| `list_feeds` | Get homepage feed |
| `get_feed_detail` | Get post details & comments |
| `post_comment_to_feed` | Post comment |
| `user_profile` | Get user profile |
| `like_feed` | Like/unlike post |
| `favorite_feed` | Save/unsave post |
| `publish_content` | Publish image post |
| `publish_with_video` | Publish video post |

### Long Image Export

Export posts as annotated JPG long images (white background, black text):

```bash
# Prepare posts.json
cat > posts.json << 'EOF'
[
  {
    "title": "Post title",
    "author": "Author",
    "stats": "13k likes 100 saves",
    "desc": "Post summary",
    "images": ["https://...webp"],
    "per_image_text": {"1": "Caption for 2nd image"}
  }
]
EOF

./export-long-image.sh --posts-file posts.json -o output.jpg
```

Requires: Python 3.10+, Pillow (`pip install Pillow`)

## Memory Export (Turn Likes into AI Memory)

Export your liked/saved posts as a searchable knowledge base for AI assistants.

### 1. Install XHS-Downloader

```bash
git clone https://github.com/JoeanAmier/XHS-Downloader.git
cd XHS-Downloader
pip install -r requirements.txt
```

### 2. Extract Post Links (Tampermonkey Script)

1. Install [Tampermonkey](https://www.tampermonkey.net/)
2. Install [XHS-Downloader UserScript](https://raw.githubusercontent.com/JoeanAmier/XHS-Downloader/refs/heads/master/static/XHS-Downloader.js)
3. Go to Xiaohongshu web → Profile → Liked/Saved
4. Click Tampermonkey menu → "Extract liked posts" or "Extract saved posts"
5. Links auto-copied to clipboard
6. Paste into `links.md`

### 3. Download & Export

```bash
# Copy helper scripts
cp tools/xhs-downloader/*.py /path/to/XHS-Downloader/

# Download posts
cd /path/to/XHS-Downloader
python batch_download.py links.md

# Export to workspace
python export_to_workspace.py
# Output: ~/.openclaw/workspace/xhs-memory/
```

### 4. Configure OpenClaw Memory Search

Edit `~/.openclaw/openclaw.json`:

```json
{
  "memorySearch": {
    "extraPaths": [
      "~/.openclaw/workspace/xhs-memory"
    ]
  }
}
```

Now your AI assistant can search your Xiaohongshu favorites!

## Project Structure

```
openclaw-xhs/
├── README.md             # English docs
├── README_CN.md          # Chinese docs
├── LICENSE
├── SKILL.md              # Skill manifest
├── scripts/              # MCP wrapper scripts
│   ├── install-check.sh
│   ├── start-mcp.sh
│   ├── stop-mcp.sh
│   ├── login.sh
│   ├── mcp-call.sh
│   ├── status.sh
│   ├── search.sh
│   ├── recommend.sh
│   ├── post-detail.sh
│   ├── comment.sh
│   ├── user-profile.sh
│   ├── track-topic.sh
│   ├── track-topic.py
│   ├── export-long-image.sh
│   └── export-long-image.py
└── tools/
    └── xhs-downloader/   # Memory export tools
        ├── README.md
        ├── batch_download.py
        ├── export_memory.py
        └── export_to_workspace.py
```

## Disclaimer

This project is a **wrapper layer** for [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp).

- Does NOT contain xiaohongshu-mcp source code
- Users must download xiaohongshu-mcp binaries separately
- Scripts communicate via HTTP protocol only

## Acknowledgments

- [@xpzouying](https://github.com/xpzouying) — [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp)
- [@JoeanAmier](https://github.com/JoeanAmier) — [XHS-Downloader](https://github.com/JoeanAmier/XHS-Downloader) (GPL-3.0)

## License

MIT License (wrapper scripts only)

**Note:** xiaohongshu-mcp has no declared license. Please respect the author's terms.

---

<p align="center">
  <b>If this project helps you, please give it a ⭐!</b>
</p>
