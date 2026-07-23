# Multi-Repository Architecture Guide with AI-Memory

This guide describes how to leverage **`ai-memory`** to connect multiple repositories within a project ecosystem (e.g., `frontend`, `backend`, `microservices`) to a centralized documentation and architecture repository.

---

## 🚀 The Problem Solved

In multi-repository setups, engineering teams frequently face:
1. **Lack of Cross-Repository Context:** An AI agent modifying the frontend has no visibility into API contract changes made in the backend repository.
2. **Outdated Documentation:** Code and business rules evolve quickly, leaving the dedicated documentation repository stale.

With `ai-memory`, a single shared **Workspace** exposes architectural context and rules to every AI agent across all repositories.

---

## 🛠️ Step-by-Step Configuration

### 1. Set a Shared Workspace Environment Variable
Set `AI_MEMORY_WORKSPACE` in your shell configuration (`~/.zshrc` or project environment) so all repositories share the same memory store:

```bash
export AI_MEMORY_WORKSPACE="my-macro-project"
```

---

### 2. Import Existing Documentation (`bootstrap`)
Navigate to your dedicated documentation repository and run the bootstrap command:

```bash
cd /path/to/docs-repository
ai-memory bootstrap
```
This command scans existing `.md` files (architecture diagrams, API specs, business logic) and populates durable wiki pages in `ai-memory`.

---

### 3. Update `AGENTS.md` in Code Repositories
Add cross-repository memory guidelines to the `AGENTS.md` file in each code repository (`frontend`, `backend`, etc.):

```markdown
## Cross-Repository & Memory Guidelines
- Before implementing a new feature or refactoring, search the architecture context in `ai-memory` using `memory_search`.
- Whenever you alter an API contract, data schema, or business rule, update or create the relevant wiki page in `ai-memory` using `memory_write_page`.
```

---

## 🔄 Daily Workflow

### Step A: Developing in Code Repositories (`backend` / `frontend`)
When working in a code repository:
```bash
cd /path/to/backend-repository
ai-jail opencode --yolo
```
1. The agent queries `ai-memory` via MCP to understand existing architecture rules.
2. The agent implements code changes.
3. Before finishing, the agent updates or writes a new page in `ai-memory` describing contract changes.

### Step B: Syncing the Dedicated Documentation Repository
To sync updated knowledge back into physical Markdown files in your docs repo:
```bash
cd /path/to/docs-repository
ai-jail opencode --yolo
```
Prompt the agent:
> *"Check ai-memory for recent architecture and contract updates saved by other services, and update the Markdown files in this documentation repository."*

The agent will read the shared memories and update your documentation repo's `.md` files accordingly.

---

## 🎯 Key Benefits

* **Holistic System Context:** All AI agents share unified architecture and contract knowledge.
* **Living Documentation:** Keeps your dedicated documentation repository in sync with active code changes.
* **Cross-Project Decision History:** Architectural decisions made in one service are instantly accessible across the entire project ecosystem.
