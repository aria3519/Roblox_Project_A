# CLAUDE.md — AI Assistant Guide for Roblox_Project_A

This file provides context and conventions for AI assistants (Claude Code and others) working in this repository. Keep it updated as the project evolves.

---

## Project Overview

**Roblox_Project_A** is a Roblox game project developed using Luau (the Roblox dialect of Lua). The project targets the Roblox platform and follows standard Roblox Studio development practices.

> **Status:** Early-stage / initial setup. No source files exist yet. Conventions below reflect intended standards for the project.

---

## Repository Structure (Intended)

```
Roblox_Project_A/
├── src/
│   ├── client/          # LocalScript files (run on player's machine)
│   ├── server/          # Script files (run on server only)
│   └── shared/          # ModuleScript files shared between client and server
├── assets/              # Static assets (models, images, sounds) if tracked in git
├── tests/               # Unit tests (e.g., using TestEZ or jest-lua)
├── default.project.json # Rojo project configuration (if using Rojo)
├── .gitignore
├── README.md
└── CLAUDE.md            # This file
```

Files in `src/client/` become `LocalScript`s under `StarterPlayerScripts` (or similar). Files in `src/server/` become `Script`s under `ServerScriptService`. Files in `src/shared/` become `ModuleScript`s under `ReplicatedStorage`.

---

## Language & Runtime

- **Language:** Luau (strict-typed superset of Lua 5.1)
- **Runtime:** Roblox engine
- **Tooling (recommended):**
  - [Rojo](https://rojo.space/) — syncs filesystem code into Roblox Studio
  - [Selene](https://kampfkarren.github.io/selene/) — Luau linter
  - [StyLua](https://github.com/JohnnyMorganz/StyLua) — Luau code formatter
  - [TestEZ](https://github.com/Roblox/testez) or [jest-lua](https://github.com/nicolo-ribaudo/jest-roblox) — unit testing

---

## Coding Conventions

### Luau Style

- Use **strict mode** at the top of every ModuleScript and Script:
  ```lua
  --!strict
  ```
- Prefer explicit type annotations for function parameters and return values:
  ```lua
  local function add(a: number, b: number): number
      return a + b
  end
  ```
- Use `PascalCase` for class/type names and constructor functions.
- Use `camelCase` for local variables and regular functions.
- Use `UPPER_SNAKE_CASE` for constants.
- Use `_` prefix for private module members (e.g., `_privateHelper`).

### Module Pattern

Use the standard Roblox module return pattern:

```lua
--!strict
local MyModule = {}
MyModule.__index = MyModule

export type MyModule = typeof(setmetatable({} :: {
    value: number,
}, MyModule))

function MyModule.new(value: number): MyModule
    return setmetatable({ value = value }, MyModule)
end

function MyModule:getValue(): number
    return self.value
end

return MyModule
```

### Services

Always fetch Roblox services via `game:GetService()` at the top of the file, never index `game` directly:

```lua
-- Good
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Bad
local Players = game.Players
```

### RemoteEvents & RemoteFunctions

- Define all `RemoteEvent` and `RemoteFunction` instances in a shared location (e.g., `ReplicatedStorage.Remotes`).
- Never trust client-sent data — always validate on the server.
- Use typed wrappers around remotes when possible.

### Error Handling

- Use `pcall` / `xpcall` around operations that may fail (especially network calls, DataStore).
- Log errors with context: `warn("[ModuleName]", message)`.
- Never silently swallow errors.

---

## Client / Server Boundary Rules

| Rule | Reason |
|------|--------|
| Never put sensitive logic in `LocalScript`s | Clients can read and modify local scripts |
| Always validate RemoteEvent arguments on server | Exploiters can fire remotes with arbitrary data |
| Use `RunService:IsServer()` / `IsClient()` guards in shared modules | Prevents accidental cross-boundary calls |
| Keep game state authoritative on the server | Prevents client-side cheating |

---

## Git Workflow

- **Default branch:** `master`
- **Feature branches:** `feature/<short-description>` or `fix/<short-description>`
- **AI assistant branches:** `claude/<session-id>` (auto-created by Claude Code)

### Commit Message Format

Use short, imperative-mood commit messages:

```
Add player health module
Fix DataStore retry logic
Refactor combat system to use shared module
```

For larger changes, include a body:

```
Add inventory system

- Implements persistent inventory via DataStore
- Adds RemoteEvents for client-server sync
- Includes unit tests for slot management
```

### Branch Naming

- Never push directly to `master` without review.
- AI assistants must push to their designated `claude/` branch and open a PR.

---

## Testing

- Place test files alongside source files or under `tests/` with a `.spec.lua` suffix.
- Run tests inside Roblox Studio using the TestEZ runner, or via `roblox-ts` / jest-lua CLI if configured.
- All new modules should have accompanying tests for core logic.

---

## Rojo Configuration

If using Rojo, `default.project.json` maps filesystem paths to Roblox's DataModel:

```json
{
  "name": "Roblox_Project_A",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": {
          "$path": "src/client"
        }
      }
    },
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": {
        "$path": "src/shared"
      }
    }
  }
}
```

---

## Key Roblox APIs to Know

| API | Notes |
|-----|-------|
| `game:GetService("DataStoreService")` | Persistent storage — always retry on failure |
| `game:GetService("Players")` | Player management |
| `game:GetService("RunService")` | Heartbeat, Stepped, RenderStepped loops |
| `game:GetService("TweenService")` | Animations/transitions |
| `game:GetService("HttpService")` | HTTP requests (server-side only) |
| `Instance.new(className)` | Create new instances |
| `workspace` | The 3D world |

---

## What AI Assistants Should Do

1. **Read this file first** before making changes to understand conventions.
2. **Maintain `--!strict`** in all Luau files — do not remove type annotations.
3. **Keep client/server boundary rules** — never put authoritative logic client-side.
4. **Write small, focused modules** — prefer composition over large monolithic scripts.
5. **Add type annotations** to all new functions and variables.
6. **Update this file** when new patterns, tools, or conventions are established.
7. **Commit on the designated `claude/` branch** and never push to `master` directly.
8. **Do not add unused services or requires** — only import what is needed.

---

## What AI Assistants Should Avoid

- Removing `--!strict` or type annotations without a strong reason.
- Writing game logic in `LocalScript`s that should be server-authoritative.
- Trusting client data on the server without validation.
- Creating large, multi-responsibility modules — keep modules focused.
- Using deprecated Roblox APIs (e.g., `wait()` — use `task.wait()` instead).
- Using `game.Players` instead of `game:GetService("Players")`.

---

## Deprecated APIs (Do Not Use)

| Deprecated | Use Instead |
|-----------|-------------|
| `wait(n)` | `task.wait(n)` |
| `spawn(fn)` | `task.spawn(fn)` |
| `delay(n, fn)` | `task.delay(n, fn)` |
| `Instance:WaitForChild()` without timeout | `Instance:WaitForChild(name, timeout)` |
| `game.Players` (direct index) | `game:GetService("Players")` |

---

*Last updated: 2026-03-05. Update this file when the project structure or conventions change.*
