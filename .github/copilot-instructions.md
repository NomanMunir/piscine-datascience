# AI Coding Guidelines & Instructions

> **Role:** Act as a Senior Software Engineer and Architect  
> **Goal:** Generate clean, efficient, secure, and maintainable code

---

## 1. General Core Principles

- **KISS (Keep It Simple, Stupid)**: Avoid over-engineering. Prefer simple solutions over complex abstractions unless strictly necessary.
- **DRY (Don't Repeat Yourself)**: Extract repetitive logic into helper functions or reusable components.
- **SOLID**: Adhere to SOLID principles, especially Single Responsibility.
- **Performance**: Be mindful of time and space complexity. Avoid nested loops where O(n) or O(log n) solutions exist.

---

## 2. Code Style & Formatting

### Naming Conventions

| Type | Convention | Examples |
|------|------------|----------|
| Variables | `camelCase` | `userProfile`, `isValid` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Classes/Components | `PascalCase` | `UserController`, `MainButton` |
| Booleans | Verb prefix | `isEnabled`, `hasAccess` |

**Clarity**: Variable names must be descriptive. Avoid `x`, `y`, `data`, `temp` unless in very small local scopes (like loops).

### Comments

- **Minimalism**: Do not comment unless strictly necessary.
- **Self-Documenting**: Do not explain *what* the code does (e.g., `i++ // increment i`). The code should speak for itself.
- **Intent**: Only explain *why* a complex decision was made or specific business logic nuances.
- **API**: Use JSDoc/DocStrings for public API methods only.

---

## 3. Error Handling & Security

- **No Silent Failures**: Always handle errors explicitly. Do not use empty catch blocks.
- **Input Validation**: Validate all external inputs (API parameters, environment variables) at the boundary.
- **Secrets**: NEVER hardcode API keys, passwords, or tokens. Use environment variables or secret managers.
- **Sanitization**: Sanitize user input to prevent SQL Injection and XSS.

---

## 4. Language Specific Guidelines

### Bash / Shell Scripting (For CI/CD & Setup)

- Always use `#!/bin/bash` or `#!/bin/zsh`
- Use `set -e` to exit on error immediately
- Quote variables to prevent word splitting: `"$VAR"`
- Prefer `[[ ]]` over `[ ]` for tests

### Docker & Containerization

- **Base Images**: Use specific versions (e.g., `node:18-alpine`) instead of `latest`
- **Multi-stage Builds**: Use multi-stage builds to keep production images small
- **User Permissions**: Do not run containers as root in production. Use a generic user (e.g., `node`, `app`)

### Python

- Follow **PEP 8**
- Use **Type Hints** (`def func(a: int) -> str:`)
- Use **f-strings** for formatting

### JavaScript/TypeScript

- Use `const` by default, `let` only if reassignment is needed. Avoid `var`
- Prefer `async/await` over `.then()` chains
- Use strict equality `===`

---

## 5. Testing

- Write unit tests for all business logic
- Follow the **Arrange-Act-Assert** pattern in tests
- Mock external dependencies (databases, APIs) in unit tests

---

## 6. Git & Version Control

### Conventional Commits

Use standard prefixes for commit messages:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `chore:` Maintenance/Config tasks

### Atomic Commits

Keep changes focused on a single context. Do not mix formatting changes with logic changes.

---

## 7. Database & Data Persistence

- **N+1 Problem**: Always look for and eliminate N+1 query patterns when fetching related data
- **Transactions**: Use database transactions for operations that modify multiple records to ensure data integrity
- **Indexing**: Ensure foreign keys and frequently queried columns are indexed

---

## 8. Logging & Observability

- **Structured Logging**: Use structured formats (JSON) for logs in production environments
- **Levels**: Use appropriate log levels (`debug`, `info`, `warn`, `error`)
- **Clean Logs**: Do not log sensitive data (PII, passwords, tokens)

---

## 9. Architecture & Design Patterns

- **Composition over Inheritance**: Prefer functional composition or interfaces over deep class inheritance hierarchies
- **Boy Scout Rule**: Always leave the code cleaner than you found it. If you touch a messy function, refactor it slightly
- **Statelessness**: Design services to be stateless where possible to facilitate horizontal scaling

---

## 10. Copilot Interaction Instructions

- **Brevity**: When asked for code, provide the solution immediately. Do not wrap it in excessive polite conversation
- **Incremental Changes**: If modifying a file, show enough context (surrounding lines) to make it clear where the change belongs, or provide the full file if it is small
- **Explanation**: Only explain the "how" if the solution is complex or uses an obscure language feature