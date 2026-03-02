#!/usr/bin/env python3

################################################################################
# email_memory_gemini_notes.py - Special Handler for Gemini Notes Emails
#
# Specialized script to fetch emails from gemini-notes@google.com and
# automatically save them as memory notes with intelligent organization
#
# These are typically Google Gemini-generated notes/summaries that should be
# integrated into your memory system
#
# Usage:
#   python3 ~/.claude/scripts/email_memory_gemini_notes.py
################################################################################

import os
import json
import sys
import base64
import re
from datetime import datetime
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
except ImportError:
    print("ERROR: Missing Google libraries", file=sys.stderr)
    print("Install: pip3 install google-auth google-api-client", file=sys.stderr)
    sys.exit(1)


class GeminiNotesProcessor:
    """Process Gemini Notes emails and save to memory"""

    def __init__(self):
        self.claude_home = Path.home() / ".claude"
        self.config_path = self.claude_home / "config" / "email_config.json"
        self.memory_path = self.claude_home / "memory" / "memoria_agente"
        self.action_points_path = self.claude_home / "memory" / "action_points.md"
        self.logs_dir = self.claude_home / "logs"

        self.config = {}
        self.gmail_service = None

        self.load_config()
        self.setup_gmail()

    def load_config(self) -> None:
        """Load configuration from JSON file"""
        try:
            with open(self.config_path, 'r') as f:
                self.config = json.load(f)
            print(f"✓ Config loaded")
        except FileNotFoundError:
            # Use default config if not exists
            self.config = {
                "gmail": {"enabled": True},
                "gemini": {"enabled": False},
                "memory": {"save_location": str(self.memory_path)}
            }
            print("⚠ Using default config (no email_config.json found)")
        except json.JSONDecodeError:
            print("ERROR: Invalid JSON in config", file=sys.stderr)
            sys.exit(1)

    def setup_gmail(self) -> None:
        """Setup Gmail API client"""
        try:
            service_account_file = os.path.expanduser(
                self.config.get("gmail", {}).get("service_account_json", "~/.claude/secrets/gmail-service-account.json")
            )

            if not os.path.exists(service_account_file):
                print(f"ERROR: Service account file not found: {service_account_file}", file=sys.stderr)
                print("To use email automation, set up Gmail API credentials", file=sys.stderr)
                sys.exit(1)

            credentials = Credentials.from_service_account_file(
                service_account_file,
                scopes=['https://www.googleapis.com/auth/gmail.readonly']
            )

            self.gmail_service = build('gmail', 'v1', credentials=credentials)
            print("✓ Gmail API connected")
        except Exception as e:
            print(f"ERROR: Gmail setup failed: {e}", file=sys.stderr)
            sys.exit(1)

    def fetch_gemini_notes_emails(self) -> List[Dict]:
        """Fetch emails from gemini-notes@google.com"""
        try:
            # Query for emails from Gemini Notes
            query = 'from:gemini-notes@google.com is:unread newer_than:1d'

            results = self.gmail_service.users().messages().list(
                userId='me',
                q=query,
                maxResults=10
            ).execute()

            messages = results.get('messages', [])
            print(f"✓ Found {len(messages)} Gemini Notes emails")
            return messages
        except Exception as e:
            print(f"ERROR: Failed to fetch Gemini Notes emails: {e}", file=sys.stderr)
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

            subject = get_header('Subject')
            date = get_header('Date')

            # Get body
            body = self.extract_body(message['payload'])

            return {
                'id': message_id,
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
                for part in payload['parts']:
                    if part['mimeType'] == 'text/plain':
                        if 'data' in part['body']:
                            data = part['body']['data']
                            return base64.urlsafe_b64decode(data).decode('utf-8')
            else:
                if 'data' in payload['body']:
                    data = payload['body']['data']
                    return base64.urlsafe_b64decode(data).decode('utf-8')

            return ""
        except Exception as e:
            print(f"ERROR: Failed to extract body: {e}", file=sys.stderr)
            return ""

    def parse_gemini_note(self, content: str) -> Dict:
        """Parse Gemini-generated note structure"""
        # Gemini notes typically have a structured format
        # Extract key sections

        parsed = {
            'title': '',
            'summary': '',
            'key_points': [],
            'action_items': [],
            'dates': [],
            'topics': []
        }

        lines = content.split('\n')

        # Extract title (usually first line or after initial whitespace)
        for line in lines:
            if line.strip() and not line.startswith('#'):
                parsed['title'] = line.strip()[:100]
                break

        # Extract action items (look for common patterns)
        in_actions = False
        for line in lines:
            if 'action' in line.lower() or 'todo' in line.lower() or 'task' in line.lower():
                in_actions = True
            elif in_actions:
                if line.strip().startswith('-') or line.strip().startswith('•'):
                    item = line.strip().lstrip('-•').strip()
                    if item:
                        parsed['action_items'].append(item)
                elif line.startswith('#') or (line and not line[0].isspace()):
                    in_actions = False

        # Look for dates/deadlines
        date_pattern = r'\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}'
        for match in re.finditer(date_pattern, content):
            parsed['dates'].append(match.group())

        return parsed

    def save_to_memory(self, email_content: Dict, parsed_data: Dict) -> Optional[Path]:
        """Save Gemini note to memory with intelligent organization"""
        try:
            # Create directory if needed
            self.memory_path.mkdir(parents=True, exist_ok=True)

            # Determine filename and directory
            date_str = datetime.now().strftime("%Y-%m-%d")

            # Create organized subdirectory for Gemini notes
            gemini_notes_dir = self.memory_path / "gemini_notes"
            gemini_notes_dir.mkdir(exist_ok=True)

            # Extract topic from title or subject
            title = parsed_data.get('title', email_content['subject'])
            safe_title = title.lower()[:40].replace(' ', '_').replace('/', '_')

            filename = f"{date_str}_{safe_title}.md"
            filepath = gemini_notes_dir / filename

            # Create content
            content = f"""# {title}

**Source:** Gemini Notes Email
**Date:** {email_content['date']}
**Saved:** {datetime.now().isoformat()}

---

## Content

{email_content['body']}

---

## Extracted Information

### Key Points
"""

            if parsed_data['key_points']:
                for point in parsed_data['key_points']:
                    content += f"- {point}\n"
            else:
                content += "- (Auto-extracted from email)\n"

            if parsed_data['action_items']:
                content += "\n### Action Items\n"
                for item in parsed_data['action_items']:
                    content += f"- [ ] {item}\n"

            if parsed_data['dates']:
                content += "\n### Important Dates\n"
                for date in parsed_data['dates']:
                    content += f"- {date}\n"

            content += f"\n### Topics\n"
            for topic in parsed_data['topics']:
                content += f"- {topic}\n"

            content += f"\n---\n\n**Email ID:** {email_content['id']}\n"

            # Save file
            with open(filepath, 'w') as f:
                f.write(content)

            print(f"  ✓ Saved to gemini_notes/{filename}")
            return filepath
        except Exception as e:
            print(f"  ERROR: Failed to save: {e}", file=sys.stderr)
            return None

    def extract_action_items(self, parsed_data: Dict) -> None:
        """Extract action items from parsed Gemini note"""
        try:
            if not parsed_data['action_items']:
                return

            with open(self.action_points_path, 'a') as f:
                f.write("\n# From Gemini Notes\n\n")
                for item in parsed_data['action_items']:
                    f.write(f"- [ ] {item}\n")
                    f.write(f"  - Source: Gemini Notes\n")
                    f.write(f"  - Date: {datetime.now().strftime('%Y-%m-%d')}\n\n")

            print(f"  ✓ Added {len(parsed_data['action_items'])} action items")
        except Exception as e:
            print(f"  Warning: Failed to extract action items: {e}", file=sys.stderr)

    def run(self) -> None:
        """Main processing loop"""
        try:
            print("\n" + "="*60)
            print("Gemini Notes Email Processor")
            print("="*60 + "\n")

            # Fetch Gemini notes emails
            messages = self.fetch_gemini_notes_emails()
            if not messages:
                print("No Gemini Notes emails to process\n")
                return

            # Process each email
            processed_count = 0
            for i, message in enumerate(messages, 1):
                print(f"\n[{i}/{len(messages)}] Processing Gemini note...")

                # Get content
                email_content = self.get_email_content(message['id'])
                if not email_content:
                    continue

                # Show info
                print(f"  Subject: {email_content['subject'][:50]}...")

                # Parse note structure
                parsed = self.parse_gemini_note(email_content['body'])
                parsed['topics'].append('gemini-generated')

                # Save to memory
                self.save_to_memory(email_content, parsed)

                # Extract action items
                self.extract_action_items(parsed)

                processed_count += 1

            print(f"\n✓ Processing completed ({processed_count} notes processed)\n")
        except Exception as e:
            print(f"ERROR: Processing failed: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    """Main entry point"""
    try:
        processor = GeminiNotesProcessor()
        processor.run()
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"FATAL ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
