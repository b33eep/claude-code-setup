# Record 026: External Plugins Integration

## Status

Done

## Context

Users want to install external plugins (from Anthropic or community) alongside our skills. Examples:
- `document-skills` from `anthropics/skills` (Word, PowerPoint, Excel, PDF)
- Community plugins from other marketplaces

Initially considered directly manipulating Claude's config files (`~/.claude/plugins/`), but discovered an official CLI.

## Decision

Use the official `claude plugin` CLI and integrate into existing install wizard.

### Official CLI Commands

```bash
# Add a marketplace
claude plugin marketplace add anthropics/skills

# Install a plugin
claude plugin install document-skills@anthropic-agent-skills

# List installed plugins
claude plugin list

# Enable/disable
claude plugin enable <plugin>
claude plugin disable <plugin>
```

### Integration Approach

1. **Add to existing wizard** - External plugins become a new selection step after skills
2. **Same `--add` behavior** - `./install.sh --add` shows external plugins too
3. **Custom compatible** - Users can define their own plugins in custom repo
4. **Use official CLI** - No config file manipulation

### Why Official CLI?

- Supported and stable API
- Config format may change between versions
- CLI handles validation, caching, marketplace management
- No need to understand internal file structures

## Implementation

### File Structure

```
claude-code-setup/
├── external-plugins.json           # Base external plugins config
└── lib/external-plugins.sh         # Functions for plugin management

~/.claude/custom/
└── external-plugins.json           # User's custom plugins (optional)
```

### external-plugins.json Format

```json
{
  "marketplaces": {
    "anthropic-agent-skills": {
      "repo": "anthropics/skills",
      "description": "Official Anthropic Agent Skills"
    }
  },
  "plugins": [
    {
      "id": "document-skills",
      "marketplace": "anthropic-agent-skills",
      "description": "Excel, Word, PowerPoint, PDF creation/editing",
      "category": "documents",
      "default": false
    }
  ]
}
```

### lib/external-plugins.sh Functions

```bash
# Load and merge base + custom plugin configs
load_external_plugins_config()

# Check if marketplace already registered
check_marketplace_exists()

# Interactive selection (reuse toggle UI)
select_external_plugins()

# Install selected plugins via CLI
install_external_plugins()
```

### install.sh Integration

```bash
do_install() {
    # ... existing code ...

    select_mcp "$mode"
    select_skills "$mode"
    select_external_plugins "$mode"    # NEW

    # ... install MCP ...
    # ... install skills ...
    install_external_plugins           # NEW
}
```

### Wizard Flow

```
Skills:
  [x] standards-python
  [x] standards-typescript

MCP Servers:
  [x] google-search
  [ ] brave-search

External Plugins (via Claude CLI):
  [ ] document-skills - Excel, Word, PowerPoint, PDF
```

### Custom Plugins

Users can add their own plugins in `~/.claude/custom/external-plugins.json`:

```json
{
  "marketplaces": {
    "my-company": {
      "repo": "mycompany/claude-plugins",
      "description": "Internal company plugins"
    }
  },
  "plugins": [
    {
      "id": "company-standards",
      "marketplace": "my-company",
      "description": "Company coding standards"
    }
  ]
}
```

These get merged with base plugins during selection.

### Error Handling

- Check if `claude` CLI is available before showing external plugins
- Skip external plugins silently if CLI not found (don't break install)
- Show clear error if marketplace add or plugin install fails
- Continue with other plugins if one fails

## Consequences

**Positive:**
- Clean integration with official plugin system
- No fragile config manipulation
- Users get curated list of useful external plugins
- Custom-compatible for private/company plugins
- Follows existing wizard pattern

**Negative:**
- Dependency on `claude` CLI being available
- External plugins require network during install
- Plugin versions managed by Claude, not us

## Testing

1. Fresh install with external plugins selected
2. `--add` mode to add plugins later
3. Custom plugins from user's custom repo
4. Missing `claude` CLI (should skip gracefully)
5. Marketplace already registered (should skip add)
6. Plugin already installed (should skip or update)

## Notes

- Anthropic's document-skills are "source-available" (proprietary license)
- We reference/install them, not copy them
- User's existing plugins are preserved
- Track installed external plugins in `installed.json` for `--list`
