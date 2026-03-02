# Ralph-Codex

This repository is a Codex-focused port of [snarktank/ralph](https://github.com/snarktank/ralph).

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that repeatedly runs Codex until all PRD items are complete. Each iteration starts with fresh context, and memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Prerequisites

- Codex CLI installed and authenticated
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

Copy the Ralph files into your project:

```bash
# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/
cp /path/to/ralph/AGENTS.md scripts/ralph/AGENTS.md

chmod +x scripts/ralph/ralph.sh
```

## Workflow

### 1. Create a PRD

Create `prd.json` with small, verifiable user stories (see `prd.json.example`).

### 2. Run Ralph

```bash
./scripts/ralph/ralph.sh --tool codex [max_iterations]
```

Default is 10 iterations when `max_iterations` is omitted.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh Codex instances |
| `AGENTS.md` | Agent instructions for each Codex iteration |
| `prd.json` | User stories with `passes` status (task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `tests/smoke-codex.sh` | Codex harness smoke tests |
| `flowchart/` | Interactive visualization of how Ralph works |

## Smoke Tests

Run Codex harness smoke tests:

```bash
./tests/smoke-codex.sh
```

## Debugging

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [snarktank/ralph](https://github.com/snarktank/ralph)
- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
