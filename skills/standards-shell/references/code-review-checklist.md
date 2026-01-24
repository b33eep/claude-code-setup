# Shell Code Review Checklist

> **Reference checklist** - Use as a guide when reviewing Shell/Bash code. Not an interactive form.

## Functionality

- [ ] Does the script work as expected?
- [ ] Are all edge cases handled?
- [ ] Is there sufficient error handling?

## Defensive Scripting

- [ ] Script starts with `set -euo pipefail`?
- [ ] All variables quoted (`"$var"` not `$var`)?
- [ ] Using `[[ ]]` for conditionals (Bash)?
- [ ] ShellCheck passes with no warnings?

## Code Quality

- [ ] Names follow snake_case convention?
- [ ] Functions use `local` for variables?
- [ ] No hardcoded values (secrets, paths)?
- [ ] Meaningful exit codes (0 = success)?
- [ ] Logs go to stderr, data to stdout?

## Shell-Specific

- [ ] Using `readonly` for constants?
- [ ] Using parameter expansion for defaults (`${var:-default}`)?
- [ ] Using `command -v` to check command existence?
- [ ] Arrays iterated with `"${arr[@]}"`?
- [ ] Files handled with `while read -r`?
- [ ] Temp files cleaned up via trap?

## Error Handling

- [ ] `trap cleanup EXIT` for cleanup?
- [ ] Error messages include context (line number, file)?
- [ ] Functions return meaningful status codes?
- [ ] Using `|| exit 1` or `|| return 1` where appropriate?

## Architecture & Patterns

- [ ] Main logic in a `main()` function?
- [ ] Reusable code extracted to functions?
- [ ] Script directory resolved with `BASH_SOURCE`?
- [ ] Complex logic broken into smaller functions?

## Testing

- [ ] Tests exist (bats-core)?
- [ ] Edge cases covered?
- [ ] Exit codes tested?
- [ ] Error conditions tested?

## Production Readiness

- [ ] `--help` option provided?
- [ ] Dependencies checked at start?
- [ ] SIGTERM/SIGINT handled gracefully?
- [ ] Appropriate logging levels?

## POSIX Compatibility (if required)

- [ ] Using `#!/bin/sh` for portable scripts?
- [ ] Using `[ ]` instead of `[[ ]]`?
- [ ] No Bash-specific features (arrays, `[[ ]]`, `$(())` arithmetic)?
- [ ] No process substitution (`<()`)?

## Project Setup

- [ ] Script has executable permission (`chmod +x`)?
- [ ] Shebang line correct (`#!/bin/bash` or `#!/bin/sh`)?
- [ ] README with usage instructions?
- [ ] CI runs ShellCheck on all scripts?
