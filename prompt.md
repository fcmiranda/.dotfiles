Act as an expert CLI tooling engineer. I need you to build a complete, OpenCode-style hook plugin system for Google's Antigravity CLI (`agy`).

I want you to write the configuration and the Node.js scripts to replicate OpenCode's advanced hook capabilities—specifically a safety/review blocker and a post-edit auto-formatter.

Here are the strict technical constraints for Antigravity CLI hooks:
1. Configuration Path: Hooks must be defined in `~/.gemini/config/hooks.json`.
2. JSON Schema: The schema maps events to a command array. Example: `"PreToolUse": { "command": ["node", "/path/to/script.mjs"] }`.
3. Supported Events: `SessionStart`, `PreToolUse` (blocking), `PostToolUse` (non-blocking), `Stop`.
4. I/O: The CLI passes context (like `tool_name` and `tool_input`) to the script via standard input (STDIN) as a JSON string.
5. Exit Codes for PreToolUse: 
   - To ALLOW the tool: `console.log(JSON.stringify({}))` and `process.exit(0)`.
   - To DENY/BLOCK the tool: `console.log(JSON.stringify({ error: "Reason here" }))` and `process.exit(2)`. 
   - If the script fails to parse or exits with an unknown code, `agy` crashes the tool call.

Based on these rules, please generate the following:

1. The `hooks.json` file to register these scripts.
2. A `pre-tool.mjs` script (OpenCode-style Security Blocker): It should intercept `Bash` tools, block dangerous commands (like `rm -rf`, `mkfs`, dropping databases), and allow safe ones.
3. A `post-tool.mjs` script (OpenCode-style Auto-Formatter): It should intercept `FileEdit` or `WriteFile` tools, read the file extension, and automatically run `prettier` or `eslint --fix` on the modified file before returning control to the agent.
4. A brief set of instructions on how to install and test this setup.

Write the Node.js scripts using modern ES modules and ensure the STDIN parsing is robust against stream chunking.