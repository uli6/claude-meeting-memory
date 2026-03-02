# Slack Setup Guide

Complete guide to obtaining Slack credentials for Claude Meeting Memory.

## Why You Need This

The setup uses Slack tokens to:
- **Read messages** - Process Slack messages to create action points
- **Send messages** - Deliver meeting briefings and reminders
- **Direct messaging** - Send you private DMs with briefings

## Prerequisites

- Slack workspace access (you must be a member)
- Workspace admin or ability to create/manage Slack apps
- Slack user token (not bot token)

## Important: User Token vs Bot Token

**User Token (what you need):**
- Format: starts with `xoxp-`
- Has same permissions as your Slack user
- Can read your messages, channels, DMs
- Can send messages as you
- **This is what you need for Claude Meeting Memory**

**Bot Token (not what you need):**
- Format: starts with `xoxb-`
- Has only permissions explicitly granted to bot
- Used for Slack apps/automations
- Won't work with Claude Meeting Memory

## Step-by-Step Setup

### Step 1: Create or Use an Existing Slack App

#### Option A: Create a New Slack App (Recommended)

1. Go to [Slack API Dashboard](https://api.slack.com/apps)
2. Click "Create an App"
3. Choose "From scratch"
4. App name: `Claude Code` (or your choice)
5. Workspace: Select your workspace
6. Click "Create App"

#### Option B: Use an Existing App

If you already have a Slack app:
1. Go to [Slack API Dashboard](https://api.slack.com/apps)
2. Click your existing app
3. Skip to Step 2

### Step 2: Get Your User Token

1. In your Slack app, go to **OAuth & Permissions** (left menu)
2. Scroll to **User Token Scopes**
3. Ensure these scopes are enabled:
   - `channels:read` - Read channel information
   - `messages:read` - Read message content
   - `users:read` - Read user information
   - `chat:write` - Send messages
   - `im:write` - Send direct messages

4. At the top of the page, find "User OAuth Token"
5. If it says "Install to Workspace", click it
6. Authorize the app (click "Allow")
7. After authorization, copy the "User OAuth Token"
   - Should look like: `xoxp-1234567890-...`

**Save this token - you'll need it in setup.**

### Step 3: Verify You Have the Right Token

**In terminal, verify the token:**

```bash
# Test your token (requires curl)
curl -X POST https://slack.com/api/auth.test \
  -H "Authorization: Bearer xoxp-YOUR_TOKEN_HERE" \
  -H 'Content-Type: application/x-www-form-urlencoded'
```

Expected response:
```json
{
  "ok": true,
  "url": "https://yourworkspace.slack.com/",
  "team": "Your Team Name",
  "user": "your.username",
  "team_id": "T01ABC123",
  "user_id": "U01ABC123"
}
```

**Important:** If `"ok": false`, the token is invalid. Check:
- Token format (should start with `xoxp-`)
- No extra spaces at beginning/end
- Correct workspace

### Step 4: Get Your Slack Member ID

Your Member ID is your unique identifier in Slack (format: `U01ABC123`).

#### Method 1: From auth.test Response (Easiest)

The response above shows:
```json
"user_id": "U01ABC123"
```

This is your Member ID!

#### Method 2: Copy from Slack UI

1. Open Slack (web or app)
2. Click your profile picture (bottom-left corner)
3. Click "Copy user ID"
4. You'll see something like: `U01ABC123`

#### Method 3: View Profile

1. Open Slack
2. Right-click your profile picture
3. Click "View profile"
4. Member ID appears at top

**Save this ID - you'll need it in setup.**

### Step 5: Run Claude Meeting Memory Setup

During setup, you'll be prompted:

```
Slack Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. User Token (xoxp-...):
   [Paste your token from Step 2]

2. Member ID (U01ABC123):
   [Paste your ID from Step 4]

3. Validating credentials...
   ✓ Token is valid
   ✓ Member ID confirmed
```

Setup will:
1. Verify the token is valid
2. Test sending a message
3. Store both securely in Keychain

### Step 6: Test the Integration

After setup, test Slack integration:

```bash
# Manual test - send a message to yourself
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer xoxp-YOUR_TOKEN" \
  -d "channel=U01ABC123" \
  -d "text=Hello from Claude Code!"
```

Or use the `/remind-me` skill:
```
/remind-me Test action point via Slack
```

## How Slack Integration Works

### Reading Messages (for /remind-me)

When you use `/remind-me` with a Slack message link:

```
/remind-me Check https://slack.com/archives/C01ABC/p1234567890123
```

Claude Code:
1. Extracts message from the link
2. Creates action point in `~/.claude/memory/action_points.md`
3. Stores context (thread, participants, etc.)

### Sending Messages (for /pre-meeting)

When you use `/pre-meeting` or enable automatic briefings:

Claude Code:
1. Generates meeting briefing
2. Sends as direct message (DM) to you
3. Uses your Member ID (`U01ABC123`)

### Message Permissions

Your token can:
- ✓ Read messages in channels you're in
- ✓ Read your direct messages
- ✓ Send messages to any channel you're in
- ✓ Send yourself direct messages
- ✗ Access messages in channels you're not in
- ✗ Modify or delete messages
- ✗ Access private information (emails, phone)

## Troubleshooting

### "Invalid token" Error

**Possible causes:**

1. Wrong token format
   - Must start with `xoxp-`
   - If starts with `xoxb-`, it's a bot token (not user token)
   - Solution: Get a user token from OAuth & Permissions

2. Extra spaces or typos
   - Copy again carefully, no leading/trailing spaces
   - Solution: Re-paste token from Slack app

3. Token revoked
   - You or someone else revoked the token
   - Solution: Create new token (regenerate in Slack app)

4. Wrong workspace
   - Token is from different Slack workspace
   - Solution: Get token from correct workspace

### "Invalid Member ID" Error

1. Wrong format
   - Must be `U` followed by characters (e.g., `U01ABC123`)
   - If starts with `C`, it's a channel ID (not user ID)
   - Solution: Verify Member ID from Step 4

2. Typo in Member ID
   - Copy again carefully, no spaces
   - Solution: Get Member ID using "Copy user ID" option

3. Account deleted
   - The user account was removed from workspace
   - Solution: Create/join new workspace, get new Member ID

### "Permission denied" Error

The token doesn't have required scopes. Re-check Step 2:

Required scopes:
- ✓ `channels:read`
- ✓ `messages:read`
- ✓ `users:read`
- ✓ `chat:write`
- ✓ `im:write`

If missing, add them and reinstall the app to your workspace.

### "Can I use a Bot Token instead?"

Not recommended. Bot tokens:
- Have more limited permissions
- Can't send you direct messages reliably
- Require more complex setup
- User tokens are simpler and work better

**Recommendation:** Use a user token (xoxp-).

### "I want to revoke access"

#### Option 1: Via Slack UI (Recommended)

1. Open Slack
2. Click your profile (bottom-left)
3. Click "Settings & administration" > "Manage apps"
4. Find "Claude Code"
5. Click it
6. Click "Revoke"

#### Option 2: Delete Local Token

Remove the token from your machine:

**macOS:**
```bash
security delete-generic-password -a $USER -s "claude-code-slack-user-token"
```

**Linux:**
```bash
secret-tool delete slack-user-token
```

**Fallback (OpenSSL):**
```bash
rm ~/.claude/.secrets.enc
```

### "Workspace admin won't let me create apps"

If your workspace has app restrictions:

1. Ask workspace admin to approve "Claude Code" app
2. Or ask them to create the app for you
3. They can add you as an authorized user
4. Then generate your user token

## Frequently Asked Questions

### Q: Is my password stored?

**No.** Only your user token is stored. Your Slack password is never shared.

### Q: What if someone gets my token?

They could read your Slack messages and send messages in your name. To revoke:
1. Go to Slack settings
2. Find "Claude Code" app
3. Click "Revoke"
4. Token becomes invalid immediately

### Q: Can I share my token with others?

Not recommended. Each person should:
1. Create their own token
2. Get their own Member ID
3. Run setup independently

Sharing tokens means others can access your Slack as you.

### Q: Will this create a Slack bot?

No. This uses your user token, not a bot. You'll see messages coming from you, not a bot account.

### Q: What if I leave the workspace?

Your user token becomes invalid. If you rejoin:
1. Create a new user token
2. Get your new Member ID
3. Update Claude Code setup

### Q: Can I use this with multiple workspaces?

Currently, setup supports one workspace at a time. To use another:
1. Run setup again
2. Enter the new workspace's token
3. Previous workspace is replaced

### Q: How often do tokens expire?

User tokens:
- Refresh tokens last indefinitely
- Access tokens auto-refresh
- Can be revoked anytime
- May be revoked by Slack for security (rare)

## Next Steps

Once you have your Slack user token and Member ID:

1. Run Claude Meeting Memory setup
2. Paste credentials when prompted
3. Setup validates and stores them securely
4. Test with `/remind-me` or manual message

See [SETUP_GUIDE.md](../SETUP_GUIDE.md) for complete setup instructions.

---

**Need help?**
- [Slack API Documentation](https://api.slack.com/)
- [Slack App Directory](https://api.slack.com/apps)
- [GitHub Issues](https://github.com/uli6/claude-meeting-memory/issues)
