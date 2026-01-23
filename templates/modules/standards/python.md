## Python Standards

**Code Style (PEP 8 + PEP 484):**
```python
from typing import Optional
from dataclasses import dataclass

@dataclass
class User:
    id: str
    name: str
    email: str
    age: Optional[int] = None

def get_user_by_id(user_id: str) -> Optional[User]:
    """Fetch a user by their unique identifier."""
    if not user_id:
        raise ValueError("user_id cannot be empty")
    # implementation...
```

**Naming Conventions:**
- Variables/Functions: snake_case (`get_user_by_id`, `is_active`)
- Classes: PascalCase (`UserService`, `ApiClient`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)
- Private: Prefix with `_` (`_internal_method`)
- Files/Modules: snake_case (`user_service.py`)

**Best Practices:**
```python
# Type hints everywhere
def process_items(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

# Use dataclasses or Pydantic
from pydantic import BaseModel
class UserCreate(BaseModel):
    name: str
    email: str

# Context managers
with open('file.txt', 'r') as f:
    content = f.read()

# Prefer pathlib over os.path
from pathlib import Path
config_path = Path(__file__).parent / 'config.yaml'
```

**Comments - Less is More:**
```python
# BAD - redundant comment
# Get the user from database
user = repository.get_user(user_id)

# GOOD - self-explanatory code, no comment needed
user = repository.get_user(user_id)

# GOOD - comment explains WHY (not obvious)
# Rate limit: Azure API allows max 1000 requests/min
await rate_limiter.acquire()
```

**Dependencies:**
- Package Manager: `uv` (faster than pip/poetry)
- Linting: `ruff` (replaces flake8, isort, black)
- Type Checking: `mypy` or `pyright`
- Testing: `pytest` with `pytest-cov`, `pytest-asyncio`
