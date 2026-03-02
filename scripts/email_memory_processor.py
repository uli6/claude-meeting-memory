#!/usr/bin/env python3

################################################################################
# email_memory_processor.py - Email Processing with Gemini AI
#
# Processes emails via Gmail API and extracts information using Gemini AI
# Saves summaries to memory system and updates action points
#
# Usage:
#   python3 ~/.claude/scripts/email_memory_processor.py
#
# Requires:
#   - google-auth-oauthlib
#   - google-api-client
#   - google-generativeai
################################################################################

import os
import json
import sys
import base64
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, List

# Add scripts to path
sys.path.insert(0, os.path.expanduser("~/.claude/scripts"))

try:
    from secrets_helper import get_secret
except ImportError:
    print("ERROR: secrets_helper.py not found", file=sys.stderr)
    sys.exit(1)

try:
    from google.oauth2.service_account import Credentials
    from googleapiclient.discovery import build
    import google.generativeai as genai
except ImportError:
    print("ERROR: Missing required libraries", file=sys.stderr)
    print("Install: pip3 install google-auth google-api-client google-generativeai", file=sys.stderr)
    sys.exit(1)


class EmailMemoryProcessor:
    """Process emails with Gemini and save to memory"""

    def __init__(self):
        self.claude_home = Path.home() / ".claude"
        self.config_path = self.claude_home / "config" / "email_config.json"
        self.memory_path = self.claude_home / "memory" / "memoria_agente"
        self.action_points_path = self.claude_home / "memory" / "action_points.md"
        self.logs_dir = self.claude_home / "logs"

        self.config = {}
        self.gmail_service = None
        self.gemini_model = None

        self.load_config()
        self.setup_clients()

    def load_config(self) -> None:
        """Load configuration from JSON file"""
        try:
            with open(self.config_path, 'r') as f:
                self.config = json.load(f)
            print(f"✓ Config loaded from {self.config_path}")
        except FileNotFoundError:
            raise FileNotFoundError(f"Config file not found: {self.config_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in config: {e}")

    def setup_clients(self) -> None:
        """Initialize Gmail and Gemini clients"""
        if self.config.get("gmail", {}).get("enabled"):
            self.setup_gmail()

        if self.config.get("gemini", {}).get("enabled"):
            self.setup_gemini()

    def setup_gmail(self) -> None:
        """Setup Gmail API client"""
        try:
            service_account_file = os.path.expanduser(
                self.config["gmail"]["service_account_json"]
            )

            if not os.path.exists(service_account_file):
                raise FileNotFoundError(f"Service account file not found: {service_account_file}")

            credentials = Credentials.from_service_account_file(
                service_account_file,
                scopes=['https://www.googleapis.com/auth/gmail.readonly']
            )

            self.gmail_service = build('gmail', 'v1', credentials=credentials)
            print("✓ Gmail API connected")
        except Exception as e:
            print(f"ERROR: Gmail setup failed: {e}", file=sys.stderr)
            raise

    def setup_gemini(self) -> None:
        """Setup Gemini API client"""
        try:
            # Try to get from Keychain first
            api_key = get_secret("gemini-api-key")

            # Fallback to environment
            if not api_key:
                api_key = os.getenv("GEMINI_API_KEY")

            if not api_key:
                raise ValueError("Gemini API key not found in Keychain or environment")

            genai.configure(api_key=api_key)
            model_name = self.config.get("gemini", {}).get("model", "gemini-1.5-flash")
            self.gemini_model = genai.GenerativeModel(model_name)
            print(f"✓ Gemini API configured ({model_name})")
        except Exception as e:
            print(f"ERROR: Gemini setup failed: {e}", file=sys.stderr)
            raise

    def fetch_emails(self) -> List[Dict]:
        """Fetch recent emails from Gmail"""
        try:
            gmail_config = self.config.get("gmail", {})
            max_age = self.config.get("filtering", {}).get("max_age_days", 1)

            # Build query
            query_parts = [f"newer_than:{max_age}d", "is:unread"]

            labels = gmail_config.get("labels_to_check", ["INBOX"])
            if labels:
                query_parts.append(f"label:({' OR '.join(labels)})")

            query = " ".join(query_parts)

            results = self.gmail_service.users().messages().list(
                userId='me',
                q=query,
                maxResults=gmail_config.get("max_results", 5)
            ).execute()

            messages = results.get('messages', [])
            print(f"✓ Fetched {len(messages)} emails")
            return messages
        except Exception as e:
            print(f"ERROR: Failed to fetch emails: {e}", file=sys.stderr)
            return []

    def get_email_content(self, message_id: str) -> Optional[Dict]:
        """Get full email content"""
        try:
            message = self.gmail_service.users().messages().get(
                userId='me',
                id=message_id,
                format='full'
            ).execute()

            headers = message['payload']['headers']

            # Extract headers
            def get_header(name: str) -> str:
                return next((h['value'] for h in headers if h['name'] == name), "Unknown")

            from_header = get_header('From')
            subject = get_header('Subject')
            date = get_header('Date')

            # Get body
            body = self.extract_body(message['payload'])

            return {
                'id': message_id,
                'from': from_header,
                'subject': subject,
                'date': date,
                'body': body
            }
        except Exception as e:
            print(f"ERROR: Failed to get email {message_id}: {e}", file=sys.stderr)
            return None

    def extract_body(self, payload: Dict) -> str:
        """Extract email body from payload"""
        try:
            if 'parts' in payload:
                # Multi-part message, find text/plain
                for part in payload['parts']:
                    if part['mimeType'] == 'text/plain':
                        if 'data' in part['body']:
                            data = part['body']['data']
                            return base64.urlsafe_b64decode(data).decode('utf-8')
            else:
                # Simple message
                if 'data' in payload['body']:
                    data = payload['body']['data']
                    return base64.urlsafe_b64decode(data).decode('utf-8')

            return ""
        except Exception as e:
            print(f"ERROR: Failed to extract body: {e}", file=sys.stderr)
            return ""

    def process_with_gemini(self, email_content: Dict) -> Optional[str]:
        """Use Gemini to extract and summarize email"""
        prompt = f"""Analyze this email and extract key information:

From: {email_content['from']}
Subject: {email_content['subject']}
Date: {email_content['date']}

Content:
{email_content['body'][:2000]}  # Limit to first 2000 chars to avoid token limit

Please provide a structured summary with:

## Main Topic
[What is this email about?]

## Key Decisions
[Any decisions made or approved?]

## Action Items
[List any action items with owners if mentioned]
- Item 1
- Item 2

## Important Dates/Deadlines
[Any dates, deadlines, or timeline changes?]

## People Mentioned
[Who is involved in this email?]

## Project/Context
[What project or context does this relate to?]

## Follow-up Needed
[Is any follow-up required?]

Keep the summary concise and well-structured for memory storage."""

        try:
            response = self.gemini_model.generate_content(prompt)
            return response.text
        except Exception as e:
            print(f"ERROR: Gemini processing failed: {e}", file=sys.stderr)
            return None

    def save_to_memory(self, email_content: Dict, processed_content: str) -> Optional[Path]:
        """Save processed email to memory"""
        try:
            # Create directory if needed
            self.memory_path.mkdir(parents=True, exist_ok=True)

            # Determine filename
            date_str = datetime.now().strftime("%Y-%m-%d")

            # Extract sender name
            from_email = email_content['from']
            if '<' in from_email:
                sender_email = from_email.split('<')[-1].rstrip('>')
                sender_name = from_email.split('<')[0].strip()
            else:
                sender_email = from_email
                sender_name = from_email.split('@')[0]

            # Create safe filename
            safe_sender = sender_name.lower().replace(' ', '_').replace('@', '_')

            if self.config.get("memory", {}).get("include_sender_files", True):
                filename = f"{date_str}_from_{safe_sender}.md"
            else:
                filename = f"{date_str}_email_summary.md"

            filepath = self.memory_path / filename

            # Create content
            content = f"""# Email: {email_content['subject']}

**From:** {email_content['from']}
**Date:** {email_content['date']}
**Saved:** {datetime.now().isoformat()}

---

## Summary

{processed_content}

---

## Original Email Preview

{email_content['body'][:300]}...

**Source:** {sender_name}
**Email:** {sender_email}

---

"""

            # Append to file (in case multiple emails in one file)
            with open(filepath, 'a') as f:
                f.write(content + "\n")

            print(f"  ✓ Saved to {filepath.name}")
            return filepath
        except Exception as e:
            print(f"  ERROR: Failed to save memory: {e}", file=sys.stderr)
            return None

    def extract_action_items(self, processed_content: str, email_content: Dict) -> None:
        """Extract action items from processed content"""
        try:
            action_items = []

            # Parse for action items section
            lines = processed_content.split('\n')
            in_actions = False

            for line in lines:
                if 'action' in line.lower() and 'item' in line.lower():
                    in_actions = True
                elif in_actions:
                    if line.strip().startswith('-') or line.strip().startswith('•'):
                        # Extract action item
                        item = line.strip().lstrip('-•').strip()
                        if item and len(item) > 3:  # Ignore very short items
                            action_items.append(item)
                    elif line.startswith('#') or not line.strip():
                        in_actions = False

            # Add to action_points.md
            if action_items and self.config.get("memory", {}).get("update_action_points", True):
                sender = email_content['from'].split('<')[0].strip() if '<' in email_content['from'] else email_content['from']

                with open(self.action_points_path, 'a') as f:
                    for item in action_items:
                        f.write(f"- [ ] {item}\n")
                        f.write(f"  - Source: Email from {sender}\n")
                        f.write(f"  - Date: {email_content['date']}\n")
                        f.write(f"  - Subject: {email_content['subject']}\n\n")

                print(f"  ✓ Added {len(action_items)} action items")
        except Exception as e:
            print(f"  Warning: Failed to extract action items: {e}", file=sys.stderr)

    def extract_people(self, email_content: Dict) -> None:
        """Extract sender info and add to people.md"""
        try:
            from_email = email_content['from']
            if '<' in from_email:
                sender_email = from_email.split('<')[-1].rstrip('>')
                sender_name = from_email.split('<')[0].strip()
            else:
                sender_email = from_email
                sender_name = from_email.split('@')[0]

            people_path = self.memory_path / "people.md"

            # Read existing people to avoid duplicates
            existing_people = set()
            if people_path.exists():
                with open(people_path, 'r') as f:
                    content = f.read()
                    # Simple check: if person already mentioned, skip
                    if sender_email in content or sender_name in content:
                        return

            # Append to people.md
            with open(people_path, 'a') as f:
                f.write(f"\n## {sender_name}\n")
                f.write(f"- **Email:** {sender_email}\n")
                f.write(f"- **Last contact:** {email_content['date']}\n")
                f.write(f"- **Subject:** {email_content['subject']}\n\n")

            print(f"  ✓ Added person: {sender_name}")
        except Exception as e:
            print(f"  Warning: Failed to extract people: {e}", file=sys.stderr)

    def extract_projects(self, processed_content: str, email_content: Dict) -> None:
        """Extract project keywords and add to projects.md"""
        try:
            import re

            projects_path = self.memory_path / "projects.md"

            # Look for project-related keywords in email and content
            project_keywords = ['project', 'initiative', 'program', 'campaign', 'product', 'release', 'milestone']

            found_projects = []
            combined_text = (email_content['subject'] + ' ' + processed_content).lower()

            for keyword in project_keywords:
                if keyword in combined_text:
                    found_projects.append(keyword.capitalize())

            if found_projects:
                # Read existing projects
                existing_content = ""
                if projects_path.exists():
                    with open(projects_path, 'r') as f:
                        existing_content = f.read()

                # Append new projects (with simple deduplication)
                with open(projects_path, 'a') as f:
                    sender = email_content['from'].split('<')[0].strip() if '<' in email_content['from'] else email_content['from']
                    f.write(f"\n### {email_content['subject']}\n")
                    f.write(f"- **From:** {sender}\n")
                    f.write(f"- **Date:** {email_content['date']}\n")
                    f.write(f"- **Status:** Active\n")
                    f.write(f"- **Keywords:** {', '.join(found_projects)}\n\n")

                print(f"  ✓ Updated projects with: {', '.join(found_projects)}")
        except Exception as e:
            print(f"  Warning: Failed to extract projects: {e}", file=sys.stderr)

    def update_memory_summary(self, email_content: Dict, processed_content: str) -> None:
        """Update MEMORY.md with email context"""
        try:
            memory_md_path = self.memory_path / "MEMORY.md"

            # Read existing content
            existing_content = ""
            if memory_md_path.exists():
                with open(memory_md_path, 'r') as f:
                    existing_content = f.read()

            # Ensure file has structure
            if "## Recent Communications" not in existing_content:
                if not existing_content.strip():
                    existing_content = "# Executive Memory\n\n## Recent Communications\n\n"
                else:
                    # Add section before summary if it doesn't exist
                    if "## Recent Communications" not in existing_content:
                        existing_content += "\n## Recent Communications\n\n"

            # Append email summary
            sender = email_content['from'].split('<')[0].strip() if '<' in email_content['from'] else email_content['from']

            with open(memory_md_path, 'a') as f:
                f.write(f"### {email_content['subject']}\n")
                f.write(f"**From:** {sender} | **Date:** {email_content['date']}\n\n")
                f.write(f"{processed_content[:500]}...\n\n")  # First 500 chars of summary

            print(f"  ✓ Updated MEMORY.md")
        except Exception as e:
            print(f"  Warning: Failed to update MEMORY.md: {e}", file=sys.stderr)

    def check_and_close_action_items(self, processed_content: str, email_subject: str) -> None:
        """Check if email content resolves any open action items"""
        try:
            # Read open action items
            if not self.action_points_path.exists():
                return

            with open(self.action_points_path, 'r') as f:
                content = f.read()

            lines = content.split('\n')
            updated_lines = []
            closed_items = []

            # Combine email subject and processed content for analysis
            email_full_text = f"{email_subject}\n{processed_content}".lower()

            # Process each line
            for i, line in enumerate(lines):
                # Check if this is an unclosed action item
                if line.strip().startswith('- [ ]'):
                    # Extract the action item text
                    action_text = line.split('- [ ]')[1].strip()

                    # Simple keyword matching: check if key words from action appear in email
                    action_words = action_text.lower().split()
                    # Filter out common words
                    action_keywords = [w for w in action_words if len(w) > 3 and w not in ['with', 'from', 'about', 'this']]

                    # Check if multiple keywords match in email content
                    matches = sum(1 for keyword in action_keywords if keyword in email_full_text)

                    # If at least 2 keywords match (or 50%+ of keywords), consider it closed
                    if action_keywords and (matches >= 2 or matches >= len(action_keywords) * 0.5):
                        # Mark as completed
                        completed_line = line.replace('- [ ]', '- [x]')
                        updated_lines.append(completed_line)
                        closed_items.append(action_text)
                        # Add note about when it was closed
                        updated_lines.append(f"  - Closed: {datetime.now().strftime('%Y-%m-%d')}")
                    else:
                        updated_lines.append(line)
                else:
                    updated_lines.append(line)

            # Write back if items were closed
            if closed_items:
                with open(self.action_points_path, 'w') as f:
                    f.write('\n'.join(updated_lines))

                print(f"  ✓ Closed {len(closed_items)} action item(s):")
                for item in closed_items:
                    print(f"    - {item[:60]}...")
            else:
                # No items closed, but write back to ensure consistency
                with open(self.action_points_path, 'w') as f:
                    f.write('\n'.join(updated_lines))

        except Exception as e:
            print(f"  Warning: Failed to check action items: {e}", file=sys.stderr)

    def run(self) -> None:
        """Main automation loop"""
        try:
            print("\n" + "="*60)
            print("Email Memory Processor")
            print("="*60 + "\n")

            # Fetch emails
            messages = self.fetch_emails()
            if not messages:
                print("No new emails to process\n")
                return

            # Process each email
            processed_count = 0
            for i, message in enumerate(messages, 1):
                print(f"\n[{i}/{len(messages)}] Processing email...")

                # Get content
                email_content = self.get_email_content(message['id'])
                if not email_content:
                    continue

                # Skip if too short
                min_length = self.config.get("filtering", {}).get("min_content_length", 50)
                if len(email_content['body']) < min_length:
                    print("  Skipped (content too short)")
                    continue

                # Show info
                print(f"  From: {email_content['from'].split('<')[0].strip() if '<' in email_content['from'] else email_content['from']}")
                print(f"  Subject: {email_content['subject'][:50]}...")

                # Process with Gemini
                print("  Processing with Gemini...")
                processed = self.process_with_gemini(email_content)
                if not processed:
                    continue

                # Save to memory
                self.save_to_memory(email_content, processed)

                # Extract action items
                self.extract_action_items(processed, email_content)

                # Extract people
                self.extract_people(email_content)

                # Extract projects
                self.extract_projects(processed, email_content)

                # Update executive memory
                self.update_memory_summary(email_content, processed)

                # Check if this email closes any open action items
                self.check_and_close_action_items(processed, email_content['subject'])

                processed_count += 1

            print(f"\n✓ Processing completed ({processed_count} emails processed)\n")
        except Exception as e:
            print(f"ERROR: Automation failed: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    """Main entry point"""
    try:
        processor = EmailMemoryProcessor()
        processor.run()
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"FATAL ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
