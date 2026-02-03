# Record 029: Documentation User Perspective

## Status

Done

## Problem

The documentation is technically complete but structured from a **developer perspective**, not a **user perspective**. Users ask questions like:

- "Will I be notified about updates?" → Hidden under "Hooks"
- "How do I manage API keys?" → Buried in /claude-code-setup page
- "Can I remove modules?" → Under "Install Options"
- "What if something doesn't work?" → No troubleshooting page

Features are documented by their technical implementation rather than by what problem they solve for users.

## Analysis

### Homepage Gap

The homepage covers core workflow well but doesn't mention:

| Feature | User Value | Currently |
|---------|------------|-----------|
| Update Notifications | "It keeps itself current" | Not mentioned |
| Private Notes | "Personal notes stay private" | Not mentioned |
| MCP Servers | "Web search, PDF reading" | Not mentioned |
| External Plugins | "AI code review" | Not mentioned |
| YouTube Transcript | "Analyze video content" | Not mentioned |
| Uninstall/Remove | "Can I remove things?" | Not mentioned |

### Navigation Issues

| User Asks | Where It Is | Problem |
|-----------|-------------|---------|
| "Update notifications?" | Reference → Hooks | Technical term |
| "API key setup?" | Commands → /claude-code-setup | Buried deep |
| "Remove modules?" | Reference → Install Options | Not prominent |
| "Troubleshooting?" | Nowhere | Missing entirely |
| "Works offline?" | Nowhere | Missing entirely |

### What's Good

- Core workflow (catchup/wrapup/clear) is well explained
- Records concept has its own page
- Team setup guide exists
- Individual command pages are thorough

## Proposed Solution

### 1. Add "Features" Section to Homepage

After "Core Features", add:

```markdown
### Extended Capabilities

- **Update Notifications** - Get notified at session start when updates are available
- **MCP Servers** - Web search (Brave/Google), PDF reading
- **External Plugins** - AI-powered code review, document skills
- **Private Notes** - Session notes that stay out of git
```

### 2. Rename/Restructure Reference Pages

| Current | Proposed |
|---------|----------|
| Hooks | Update Notifications (via Hooks) |
| Install Options | Managing Modules |

Or add cross-references at the top of pages explaining the user benefit.

### 3. Add FAQ/Troubleshooting Page

Common questions:

- "Permission prompts are annoying" → Link to opt-in permissions
- "MCP server not working" → Check API key, restart Claude
- "ccstatusline not showing" → Verify settings.json
- "Updates not detected" → Check network, hook configuration

### 4. Add "Offline Usage" Section

Document what works offline:
- Core workflow (catchup/wrapup/clear)
- Coding standards
- Local MCP servers

What requires network:
- Update notifications
- Web search MCP
- External plugin installation

## Implementation

Restructured the website documentation:

### Changes Made

| Before | After |
|--------|-------|
| `reference/` | `features/` |
| `reference/hooks.mdx` | `features/update-notifications.mdx` |
| `reference/install-options.mdx` | `features/module-management.mdx` |
| `reference/file-structure.mdx` | `development/file-structure.mdx` |

### Navigation Structure

```
Features/
├── Skills
├── MCP Servers
├── External Plugins
├── Update Notifications (was: Hooks)
├── Module Management (was: Install Options)

Development/
├── File Structure (moved from Reference)
├── Contributing
├── Testing
├── Security
```

### Future Improvements

- Add "Extended Capabilities" section to homepage
- Create FAQ/Troubleshooting page
- Add "Offline Usage" documentation

## Related

- [Record 019](019-upgrade-permissions.md) - Permission prompts (related FAQ topic)
- [Record 028](028-update-notifications.md) - Update notifications implementation
