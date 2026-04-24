---
name: standards-python-example
description: Team Python coding standards for backend services — naming, structure, testing, error handling. Auto-loads for any Python project. Covers FastAPI, SQLAlchemy, and pytest conventions specific to this team.
type: context
applies_to: [python, fastapi, sqlalchemy]
file_extensions: [".py", ".pyi"]
metadata:
  version: 1.0.0
  tags: [coding-standards, python]
---

# Python Coding Standards (Example)

> This is a worked example of a context skill. It auto-loads whenever the project's Tech Stack includes Python, FastAPI, or SQLAlchemy, or when the user edits a `.py` file.

## Overview

Team conventions for Python backend services. Apply these whenever writing or reviewing Python code. Not a style guide — it's the minimum bar for code to be considered production-ready.

## Critical rules (always)

- Type hints on every function signature (`def foo(x: int) -> str:`)
- `from __future__ import annotations` at the top of every file (enables lazy annotation evaluation)
- No `print()` in production code — use the `logging` module
- No bare `except:` — always catch specific exception types
- No mutable default arguments (`def foo(items=[])` ← wrong)

## Naming conventions

| Kind | Convention | Example |
|---|---|---|
| Module | snake_case | `user_service.py` |
| Class | PascalCase | `UserService` |
| Function / method | snake_case | `get_active_users()` |
| Constant | UPPER_SNAKE | `MAX_RETRIES` |
| Private | leading underscore | `_internal_helper` |
| Test module | `test_*.py` | `test_user_service.py` |
| Test function | `test_*` | `test_get_active_users_excludes_inactive` |

Test function names should describe the scenario, not the code being tested: `test_order_total_applies_discount_when_coupon_valid` is better than `test_calc_total`.

## File structure

Each module follows this order:

```python
"""One-line module docstring."""
from __future__ import annotations

# Standard library imports
import logging
from datetime import datetime

# Third-party imports
import sqlalchemy as sa
from fastapi import HTTPException

# Local imports
from app.models import User
from app.services.auth import get_current_user

logger = logging.getLogger(__name__)

# Constants
MAX_USERS_PER_PAGE = 50

# Classes / functions
class UserService:
    ...
```

Imports in three groups separated by blank lines: stdlib, third-party, local. Each group alphabetically sorted.

## Error handling

### Catch specific exceptions

```python
# Good
try:
    user = db.query(User).filter_by(id=user_id).one()
except NoResultFound:
    raise HTTPException(status_code=404, detail="User not found")
except SQLAlchemyError as e:
    logger.exception("Database error in get_user")
    raise HTTPException(status_code=500, detail="Internal error")

# Bad
try:
    ...
except:  # ← too broad, hides bugs
    pass
```

### Log before re-raising

```python
# Good
try:
    result = risky_operation()
except SomeError:
    logger.exception("risky_operation failed with context: %s", context)
    raise
```

`logger.exception` captures the stack trace automatically. Don't manually format tracebacks.

### Return early on error

```python
# Good
def get_user(user_id: int) -> User:
    if user_id <= 0:
        raise ValueError("user_id must be positive")
    return db.query(User).filter_by(id=user_id).one()

# Bad — nested conditions
def get_user(user_id: int) -> User | None:
    if user_id > 0:
        try:
            return db.query(User).filter_by(id=user_id).one()
        except NoResultFound:
            return None
    return None
```

## FastAPI conventions

### Route structure

```python
from fastapi import APIRouter, Depends, HTTPException
from app.schemas import UserCreate, UserOut

router = APIRouter(prefix="/users", tags=["users"])

@router.post("", response_model=UserOut, status_code=201)
async def create_user(
    payload: UserCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    """Create a new user."""
    ...
```

- Response model explicit (`response_model=UserOut`)
- Status code explicit when not the default 200
- Dependencies injected via `Depends`, not fetched inside the function
- One-line docstring describes the endpoint's purpose

### Pydantic schemas

Separate input and output schemas. Inputs validate user data; outputs shape the response.

```python
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    name: str
    password: str

class UserOut(BaseModel):
    id: int
    email: EmailStr
    name: str

    class Config:
        from_attributes = True
```

Never expose the password or internal fields in `UserOut`.

## SQLAlchemy conventions

### Queries

Always use scoped sessions from `Depends(get_db)`. Never create sessions ad-hoc inside business logic.

```python
# Good
def list_users(db: Session, limit: int = 50) -> list[User]:
    return db.query(User).limit(limit).all()

# Bad
def list_users(limit: int = 50) -> list[User]:
    with SessionLocal() as db:  # ← creates new session outside the request scope
        return db.query(User).limit(limit).all()
```

### Transactions

Wrap write operations in transactions:

```python
def transfer_funds(db: Session, from_id: int, to_id: int, amount: Decimal) -> None:
    with db.begin():
        from_account = db.query(Account).with_for_update().get(from_id)
        to_account = db.query(Account).with_for_update().get(to_id)
        from_account.balance -= amount
        to_account.balance += amount
```

## Testing conventions

### pytest structure

```python
"""Tests for UserService."""
from __future__ import annotations

import pytest

from app.services.users import UserService

@pytest.fixture
def service(db_session):
    return UserService(db=db_session)

class TestGetActiveUsers:
    def test_returns_only_active_users(self, service, user_factory):
        active = user_factory(is_active=True)
        _inactive = user_factory(is_active=False)

        result = service.get_active_users()

        assert result == [active]

    def test_excludes_deleted_users(self, service, user_factory):
        user_factory(is_active=True, deleted_at=datetime.now())

        result = service.get_active_users()

        assert result == []
```

- One `TestXxx` class per method or logical unit under test
- Test names describe scenario: `test_<action>_<condition>_<expected>`
- Three-phase structure: arrange → act → assert, separated by blank lines
- Use fixtures for common setup; don't repeat `db.add()` chains

### Coverage expectations

- New code: 90%+ coverage
- Core business logic: 100% for happy path + named error cases
- Trivial helpers: test once, don't obsess

## Anti-patterns (do not do)

- **No wildcard imports.** `from app.models import *` breaks tooling and hides dependencies.
- **No global mutable state.** Singletons, module-level dicts that get mutated — all fragile. Use dependency injection.
- **No `# type: ignore` without a reason.** If you must silence mypy, add a comment explaining why.
- **No business logic in route handlers.** Routes validate input, call services, shape output. The service layer does the work.
- **No catching `Exception` broadly.** At most, `except Exception:` at a boundary (e.g. top-level request handler) where the exception is logged and re-raised as a user-facing error.

## Tooling

Required in every Python project:

```toml
# pyproject.toml (essentials)
[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "A", "SIM", "RUF"]

[tool.mypy]
strict = true
python_version = "3.12"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra --strict-markers --cov=app --cov-report=term-missing"
```

Run before committing:

```bash
ruff check .
ruff format .
mypy .
pytest
```

## When standards conflict

If upstream library conventions differ from these standards (e.g. a third-party requires snake_case where PascalCase would be expected), follow the library. Note the exception in a `# noqa: N802 — library requires this name` comment.
