# TypeScript Code Review Checklist

## Functionality

- [ ] Does the code work as expected?
- [ ] Are all edge cases handled?
- [ ] Is there sufficient error handling?

## Code Quality

- [ ] Are names descriptive and following camelCase/PascalCase conventions?
- [ ] Is the code testable and tested?
- [ ] No hardcoded values (secrets, URLs)?
- [ ] Using proper logging instead of console.log?
- [ ] Types complete (parameters, return types)?

## TypeScript-Specific

- [ ] Strict mode enabled (`strict: true`)?
- [ ] Using `unknown` instead of `any`?
- [ ] Type guards for type narrowing?
- [ ] No type assertions (`as`) without validation?
- [ ] Interfaces for object shapes, types for unions/aliases?
- [ ] Using `readonly` for immutable data?
- [ ] Using `as const` for literal types?
- [ ] Optional chaining (`?.`) and nullish coalescing (`??`)?

## Async (if applicable)

- [ ] Async/await correctly used?
- [ ] Proper error handling in async functions?
- [ ] Using `Promise.all` for concurrent operations?
- [ ] No floating promises (unhandled promise rejections)?
- [ ] Correct Promise return types?

## Architecture & Patterns

- [ ] No duplicated code across classes? → Extract Base Class
- [ ] No if/elif chains for types/variants? → Discriminated Union
- [ ] No N queries in loops? → Batch Query
- [ ] No repeated transformation logic? → Helper Function
- [ ] DTOs immutable where appropriate? → `readonly` properties

## Testing

- [ ] Unit tests for business logic?
- [ ] Edge cases covered?
- [ ] Mocking external dependencies?
- [ ] Using test fixtures appropriately?
- [ ] Type-safe mocks?

## Production Readiness

- [ ] Environment variables validated at startup?
- [ ] Graceful shutdown handling?
- [ ] Error boundaries for async operations?
- [ ] Structured logging with appropriate levels?

## Project Setup

- [ ] Dependencies in `package.json` with locked versions?
- [ ] Dev dependencies separated from production?
- [ ] Node/TypeScript version specified?
- [ ] `tsconfig.json` with strict settings?
- [ ] README with setup instructions?
