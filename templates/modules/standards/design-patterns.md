## Design Patterns & Architecture

**When to apply patterns - recognize these code smells:**

| Code Smell | Pattern | Example |
|------------|---------|---------|
| Same code in multiple classes | Base Class / Mixin | HTTP session management in services |
| if/elif chain for types/variants | Strategy + Registry | File loaders, exporters, parsers |
| N queries in a loop | Batch Query | `WHERE id = ANY($1)` instead of loop |
| Same transformation in multiple places | Helper Function | Response formatting, data mapping |

**Base Class for Shared Logic:**
```python
# BAD - duplicated in 4 services
class ServiceA:
    async def _get_session(self) -> aiohttp.ClientSession:
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(timeout=...)
        return self._session

# GOOD - extract to base class
class AsyncHttpService(ABC):
    async def _get_session(self) -> aiohttp.ClientSession:
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(timeout=...)
        return self._session

class ServiceA(AsyncHttpService):
    # inherits _get_session()
```

**Strategy Pattern for Extensibility:**
```python
# BAD - if/elif chain, hard to extend
async def load_file(filepath: Path, file_type: str) -> str:
    if file_type == "application/pdf":
        return await _load_pdf(filepath)
    elif file_type == "application/vnd.openxmlformats-officedocument...":
        return await _load_docx(filepath)
    # Adding new type = modify this function

# GOOD - Strategy + Registry
class DocumentLoader(ABC):
    @property
    @abstractmethod
    def supported_mime_types(self) -> list[str]: ...

    @abstractmethod
    async def load(self, filepath: Path) -> str: ...

class LoaderRegistry:
    def register(self, loader: DocumentLoader) -> None: ...
    def get_loader(self, filename: str, content_type: str) -> DocumentLoader: ...

# Adding new type = new class, register it
registry.register(ExcelLoader())
```

**Batch Queries for Performance:**
```python
# BAD - O(N) queries
for file_id in file_ids:
    chunks = await repository.get_chunks_by_file_id(file_id)

# GOOD - O(1) query with ANY()
async def get_chunks_by_file_ids(self, file_ids: list[str]) -> dict[str, list[Chunk]]:
    sql = "SELECT * FROM documents WHERE file_id = ANY($1)"
    rows = await conn.fetch(sql, file_ids)
    # Group by file_id and return
```

**Helper Functions for Repeated Logic:**
```python
# BAD - same transformation in multiple endpoints
@router.post("/query")
async def query(...):
    return [[{"page_content": r.content, "metadata": {...}}, 1.0 - r.score] for r in results]

@router.post("/query_multiple")
async def query_multiple(...):
    return [[{"page_content": r.content, "metadata": {...}}, 1.0 - r.score] for r in results]

# GOOD - extract helper
def _format_query_results(results: list[QueryResult]) -> list[list[dict | float]]:
    return [[{"page_content": r.content, "metadata": {...}}, 1.0 - r.score] for r in results]

@router.post("/query")
async def query(...):
    return _format_query_results(results)
```

**Immutable Data Classes:**
```python
# For DTOs that shouldn't change after creation
@dataclass(frozen=True)
class QueryResult:
    document: Document
    score: float

# Attempting to modify raises FrozenInstanceError
result.score = 0.9  # Error!
```
