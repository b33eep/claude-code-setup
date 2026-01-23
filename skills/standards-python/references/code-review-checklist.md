# Python Code Review Checklist

> **Reference checklist** - Use as a guide when reviewing Python code. Not an interactive form.

## Functionality

- [ ] Does the code work as expected?
- [ ] Are all edge cases handled?
- [ ] Is there sufficient error handling?

## Code Quality

- [ ] Are names descriptive and following snake_case convention?
- [ ] Is the code testable and tested?
- [ ] No hardcoded values (secrets, URLs)?
- [ ] Using `logging` module instead of print statements?
- [ ] Type hints complete (parameters, return types)?

## Python-Specific

- [ ] Using `pathlib.Path` instead of `os.path`?
- [ ] Context managers for resources (`with` statement)?
- [ ] Dataclasses or Pydantic for data structures?
- [ ] f-strings for string formatting?
- [ ] List/dict comprehensions where appropriate?
- [ ] Modern union syntax (`str | None` instead of `Optional[str]`)?

## Async (if applicable)

- [ ] Async/await correctly used?
- [ ] No blocking calls in async functions (`time.sleep`, sync I/O)?
- [ ] Using `asyncio.gather` for concurrent operations?
- [ ] Async context managers for async resources (`async with`)?

## Architecture & Patterns

- [ ] No duplicated code across classes? → Extract Base Class
- [ ] No if/elif chains for types/variants? → Strategy Pattern
- [ ] No N queries in loops? → Batch Query
- [ ] No repeated transformation logic? → Helper Function
- [ ] DTOs immutable where appropriate? → `@dataclass(frozen=True)`

## Testing

- [ ] Unit tests for business logic?
- [ ] Edge cases covered?
- [ ] Mocking external dependencies?
- [ ] Using pytest fixtures appropriately?

## Production Readiness

- [ ] Environment variables for config (not hardcoded)?
- [ ] Graceful shutdown handling (SIGTERM)?
- [ ] Connection pooling for DB/HTTP clients?
- [ ] Structured logging with appropriate levels?

## Project Setup

- [ ] Dependencies declared in `pyproject.toml`?
- [ ] Dev dependencies separated from production?
- [ ] Python version specified?
- [ ] README with setup instructions?
