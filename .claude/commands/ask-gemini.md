# Query Google Workspace content via Gemini CLI

Invoke Gemini CLI to query Google Docs, Sheets, Gmail, Calendar, or other Google Workspace content that the user has authorized.

## Usage

```
/ask-gemini [prompt]
```

The `$ARGUMENTS` variable contains the user's prompt/question.

## Instructions

Run the following command to query Gemini with the Google Workspace extension:

```bash
gemini -y -p "$ARGUMENTS"
```

Flags:
- `-y` (yolo mode): Auto-approves all tool calls including the Google Workspace extension
- `-p`: Runs in headless/non-interactive mode with the provided prompt

## Examples

- `/ask-gemini Summarize this Google Doc: https://docs.google.com/document/d/...`
- `/ask-gemini What meetings do I have today?`
- `/ask-gemini Search my Gmail for emails from Alice about the project`
- `/ask-gemini What's in my Google Sheet about Q4 metrics?`

## Notes

- The user must have previously authorized the Google Workspace extension in Gemini CLI
- Results are returned directly from Gemini's response
- If the command fails, check that `gemini` is installed and the workspace extension is configured
