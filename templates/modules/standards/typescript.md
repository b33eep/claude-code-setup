## TypeScript Standards

**Code Style:**
```typescript
// Prefer const over let
const items = ['a', 'b', 'c'];

// Use explicit types for function parameters and returns
function processUser(user: User): ProcessedUser { ... }

// Prefer interfaces over types for objects
interface User {
  id: string;
  name: string;
}

// Use type for unions/intersections
type Status = 'pending' | 'active' | 'inactive';
```

**Naming Conventions:**
- Variables/Functions: camelCase (`getUserById`, `isActive`)
- Classes/Interfaces/Types: PascalCase (`UserService`, `ApiResponse`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)
- Files: kebab-case (`user-service.ts`)
- Event Handlers: Prefix with `handle` (`handleClick`, `handleSubmit`)

**Best Practices:**
```typescript
// Nullish coalescing + optional chaining
const name = user.name ?? 'Anonymous';
const city = user.address?.city;

// Array methods over loops
const activeUsers = users.filter(u => u.isActive);

// async/await over .then()
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// Destructure when appropriate
function greet({ name, age }: User): string {
  return `Hello ${name}, you are ${age} years old`;
}
```

**Error Handling:**
```typescript
class ApiError extends Error {
  constructor(message: string, public statusCode: number, public code: string) {
    super(message);
    this.name = 'ApiError';
  }
}
```
