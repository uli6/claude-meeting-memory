# Google OAuth Setup Guide

Complete guide to obtaining Google OAuth credentials for Claude Meeting Memory.

## Why You Need This

The setup uses Google OAuth to securely access:
- **Google Drive** - Read Google Docs you have access to
- **Google Calendar** - Read your calendar events for meeting briefings

No password is stored. Instead, we use OAuth tokens that you can revoke anytime.

## Prerequisites

- Google account (personal or workspace)
- Access to Google Cloud Console
- Ability to create OAuth applications

## Step-by-Step Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown at the top
3. Click "NEW PROJECT"
4. Enter project name: `Claude Code` (or your choice)
5. Click "CREATE"

Wait for the project to be created (1-2 minutes).

### Step 2: Enable Required APIs

Still in Google Cloud Console:

1. Go to **APIs & Services** > **Library**
2. Search for and enable these APIs:

#### API 1: Google Drive API
1. Search "Google Drive API"
2. Click the result
3. Click "ENABLE"
4. Wait for enablement confirmation

#### API 2: Google Calendar API
1. Search "Google Calendar API"
2. Click the result
3. Click "ENABLE"
4. Wait for enablement confirmation

### Step 3: Create OAuth Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click "Create Credentials" > "OAuth client ID"
3. If prompted: "First, set up your OAuth consent screen"
   - Click "Configure Consent Screen"
   - Choose **External** user type
   - Click "CREATE"
   - Fill in:
     - App name: `Claude Code`
     - User support email: (your email)
     - Developer contact email: (your email)
   - Click "SAVE AND CONTINUE" (skip optional scopes)
   - Click "SAVE AND CONTINUE" again
   - Click "BACK TO DASHBOARD"

4. Back in Credentials, click "Create Credentials" > "OAuth client ID"
5. Choose **Desktop application**
6. Click "CREATE"
7. Click "DOWNLOAD JSON" or view the credentials

### Step 4: Prepare Credentials

You should now see your OAuth credentials:

```
Client ID:     1234567890-abcdefghijk...apps.googleusercontent.com
Client Secret: GOCSPX-1234567890abc...
```

Keep this window open - you'll paste these into the setup script.

### Step 5: Run Claude Meeting Memory Setup

During setup, you'll be prompted:

```
Google OAuth Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Client ID (xxxxxxxxxxxxxapps.googleusercontent.com):
   [Paste your Client ID from Step 4]

2. Client Secret (GOCSPX-...):
   [Paste your Client Secret from Step 4]

3. Starting browser for authorization...
   [Browser will open automatically]
```

**In the browser:**
- You'll see "Claude Code wants to access your account"
- Click "Allow" to authorize
- You'll see "Authorization successful"
- Return to terminal (setup continues automatically)

### Step 6: Automatic Token Refresh

After authorization, the setup script automatically:
1. Obtains a **refresh token** from Google
2. Stores it securely in your OS Keychain
3. Tests that it works

You won't need to re-authorize unless you revoke access.

## Troubleshooting

### "I accidentally closed the browser"

No problem! The setup will provide a link you can click manually:

```
Authorization URL (click if browser didn't open):
https://accounts.google.com/o/oauth2/v2/auth?...
```

Copy the URL and paste in browser, then return to terminal.

### "Got a 403 error - access denied"

**Possible causes:**
1. You're using a Google account that doesn't own the project
   - Solution: Use the same Google account that created the project

2. APIs weren't enabled
   - Solution: Go back to Step 2 and enable Google Drive + Calendar APIs

3. OAuth consent screen incomplete
   - Solution: Go to **APIs & Services** > **OAuth consent screen** and complete all required fields

### "Credentials already exist - can I reuse them?"

Yes! During setup, you can enter existing credentials.

If you already have a `GOOGLE_CAL_CLIENT_ID` and `GOOGLE_CAL_CLIENT_SECRET`:
- Enter them when prompted
- Setup will use the same project

### "I want to use a different Google account"

1. Don't enter your existing credentials
2. Create a new Google Cloud Project (Step 1)
3. Create new OAuth credentials (Step 3)
4. Enter the new credentials during setup

### "Browser is taking a long time to load"

1. Wait a few seconds (first-time load can be slow)
2. If it still doesn't open:
   - Check your internet connection
   - Try using a different browser
   - Copy the authorization URL and open manually

### "I get 'Invalid client' error"

- Verify Client ID and Client Secret are correct (no typos, no extra spaces)
- Ensure they're from the same Google Cloud Project
- Both values should be copy-pasted, not typed

## Revoking Access

If you want to revoke Google access at any time:

### Option 1: Via Google Settings (Recommended)

1. Go to [Google Account Security](https://myaccount.google.com/permissions)
2. Find "Claude Code"
3. Click it
4. Click "REMOVE ACCESS"

Your refresh token becomes invalid. You'll need to re-authorize next time.

### Option 2: Delete Local Token

Remove the token stored on your machine:

**macOS:**
```bash
security delete-generic-password -a $USER -s "claude-code-google-refresh-token"
```

**Linux (GNOME/KDE):**
```bash
secret-tool delete google-refresh-token
```

**Fallback (OpenSSL):**
```bash
rm ~/.claude/.secrets.enc
```

## Google Cloud Project Cleanup

If you created a test project and want to delete it:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown
3. Right-click the project
4. Click "SETTINGS"
5. Click "Shut down project"
6. Enter the project ID to confirm
7. Click "SHUT DOWN"

**Warning:** This is permanent and cannot be undone.

## Frequently Asked Questions

### Q: Is my password stored?

**No.** OAuth uses tokens, not passwords. Your Google password is never shared with Claude Code.

### Q: What if Google revokes my token?

Google occasionally revokes old tokens for security. You'll get an error, and setup can re-authorize with a simple browser flow.

### Q: Can I share my credentials with others?

Not recommended. Each person should:
1. Create their own Google Cloud Project
2. Generate their own OAuth credentials
3. Run setup independently

### Q: What permissions do I grant?

Only:
- Read-only access to Google Drive (documents you own/have access to)
- Read-only access to Google Calendar (your events only)

No write permissions. No access to email or contacts.

### Q: How long does the token last?

Refresh tokens last indefinitely until:
- You revoke them (Google Account Security)
- You delete the local token
- Google revokes them (rare, for security)

### Q: What if I delete Google Cloud Project?

The OAuth tokens become invalid. You'll need to:
1. Create a new Google Cloud Project
2. Create new OAuth credentials
3. Re-authorize in Claude Code setup

## Next Steps

Once you have your Google OAuth credentials:

1. Run Claude Meeting Memory setup
2. Paste credentials when prompted
3. Authorize in browser
4. Setup stores token securely

See [SETUP_GUIDE.md](../SETUP_GUIDE.md) for complete setup instructions.

---

**Need help?**
- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Google Cloud Console](https://console.cloud.google.com/)
- [GitHub Issues](https://github.com/uli6/claude-meeting-memory/issues)
