# Parallel Agents Orchestrator

A Python CLI that runs N Claude Code agents on the same task in parallel, then uses tournament-style judging to pick the best implementation.

## Input / Output

**Input:**

- A prompt (string or file path)
- N (number of agents)
- Repository path (defaults to cwd)

**Output:**

- Winning branch name
- Tournament results summary
- All branches preserved for inspection

## Workflow

```
prompt + N
    │
    ▼
┌─────────────────────────────────────┐
│  Create N git worktrees             │
│  Spawn N claude processes parallel  │
│  Wait for completion/timeout        │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Extract diff from each branch      │
│  Run tournament bracket             │
│  Each match: judge sees 2 diffs     │
└─────────────────────────────────────┘
    │
    ▼
Winner branch name + summary
```

______________________________________________________________________

## CLI

Single command:

```bash
parallel-agents "implement feature X" --agents 4
parallel-agents --prompt-file spec.md --agents 8 --timeout 60
```

**Arguments:**

| Flag | Default | Description |
|------|---------|-------------|
| `PROMPT` | required | Prompt string (positional) or via `--prompt-file` |
| `--agents, -n` | 4 | Number of parallel agents |
| `--timeout, -t` | 30 | Minutes per agent |
| `--repo, -r` | `.` | Repository path |
| `--base-branch` | `main` | Branch to fork from |

That's it. No resume, no cleanup flags, no model selection for v1.

______________________________________________________________________

## File Structure

```
parallel_agents/
├── __init__.py
├── cli.py          # Entry point, argument parsing
├── spawner.py      # Worktree creation + parallel execution
├── judge.py        # Diff extraction + tournament
└── prompts.py      # Prompt templates as strings
```

Four files. No utils/, no models.py, no config.py.

______________________________________________________________________

## Data Structures

Keep it simple—dataclasses, not Pydantic:

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Agent:
    id: int
    branch: str
    worktree: Path
    diff: str | None = None
    failed: bool = False

@dataclass 
class Match:
    agent_a: Agent
    agent_b: Agent
    winner: Agent | None = None
    reasoning: str = ""
```

No Run, no Tournament, no Spec objects. State lives in memory for the duration of the run.

______________________________________________________________________

## Module Specs

### `cli.py`

```python
import click
from pathlib import Path

@click.command()
@click.argument("prompt", required=False)
@click.option("--prompt-file", type=click.Path(exists=True))
@click.option("--agents", "-n", default=4)
@click.option("--timeout", "-t", default=30)
@click.option("--repo", "-r", default=".", type=click.Path(exists=True))
@click.option("--base-branch", default="main")
def main(prompt, prompt_file, agents, timeout, repo, base_branch):
    """Run N agents in parallel, tournament-judge the results."""
    
    if prompt_file:
        prompt = Path(prompt_file).read_text()
    if not prompt:
        raise click.UsageError("Provide PROMPT or --prompt-file")
    
    # 1. Spawn agents
    completed_agents = spawner.run(
        prompt=prompt,
        n=agents,
        timeout=timeout,
        repo=Path(repo),
        base_branch=base_branch
    )
    
    # 2. Run tournament
    winner = judge.tournament(completed_agents, prompt)
    
    # 3. Print result
    click.echo(f"\n✓ Winner: {winner.branch}")
    click.echo(f"  Merge with: git merge {winner.branch}")
```

### `spawner.py`

```python
import asyncio
import subprocess
from pathlib import Path

def run(prompt: str, n: int, timeout: int, repo: Path, base_branch: str) -> list[Agent]:
    """Create worktrees and run agents in parallel."""
    
    agents = []
    for i in range(n):
        branch = f"agent-{i}"
        worktree = repo.parent / f".worktree-{i}"
        
        # Create worktree
        subprocess.run(
            ["git", "worktree", "add", str(worktree), "-b", branch, base_branch],
            cwd=repo, check=True
        )
        agents.append(Agent(id=i, branch=branch, worktree=worktree))
    
    # Run all agents in parallel
    asyncio.run(_run_all(agents, prompt, timeout))
    
    # Extract diffs for successful agents
    for agent in agents:
        if not agent.failed:
            agent.diff = _get_diff(repo, base_branch, agent.branch)
            if not agent.diff.strip():
                agent.failed = True  # No changes = failed
    
    return [a for a in agents if not a.failed]

async def _run_all(agents: list[Agent], prompt: str, timeout: int):
    """Run claude in each worktree concurrently."""
    tasks = [_run_agent(a, prompt, timeout) for a in agents]
    await asyncio.gather(*tasks, return_exceptions=True)

async def _run_agent(agent: Agent, prompt: str, timeout: int):
    """Run single agent."""
    proc = await asyncio.create_subprocess_exec(
        "claude", "--print", "--dangerously-skip-permissions",
        "-p", prompt,
        cwd=agent.worktree,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    try:
        async with asyncio.timeout(timeout * 60):
            await proc.communicate()
            if proc.returncode != 0:
                agent.failed = True
    except asyncio.TimeoutError:
        proc.kill()
        agent.failed = True

def _get_diff(repo: Path, base: str, branch: str) -> str:
    """Get diff between base and branch."""
    result = subprocess.run(
        ["git", "diff", f"{base}...{branch}"],
        cwd=repo, capture_output=True, text=True
    )
    return result.stdout
```

### `judge.py`

```python
import subprocess
import random

def tournament(agents: list[Agent], spec: str) -> Agent:
    """Run tournament bracket, return winner."""
    
    if len(agents) == 0:
        raise RuntimeError("No agents completed successfully")
    if len(agents) == 1:
        return agents[0]
    
    # Shuffle for fairness
    random.shuffle(agents)
    
    # Run rounds until one remains
    remaining = agents
    round_num = 1
    
    while len(remaining) > 1:
        print(f"\n=== Round {round_num} ({len(remaining)} agents) ===")
        winners = []
        
        for i in range(0, len(remaining), 2):
            if i + 1 >= len(remaining):
                # Bye
                winners.append(remaining[i])
                print(f"  Agent {remaining[i].id} gets bye")
            else:
                match = judge_match(remaining[i], remaining[i+1], spec)
                winners.append(match.winner)
                print(f"  Agent {match.agent_a.id} vs {match.agent_b.id} → Agent {match.winner.id}")
        
        remaining = winners
        round_num += 1
    
    return remaining[0]

def judge_match(a: Agent, b: Agent, spec: str) -> Match:
    """Judge single match between two agents."""
    
    prompt = JUDGE_PROMPT.format(spec=spec, diff_a=a.diff, diff_b=b.diff)
    
    result = subprocess.run(
        ["claude", "--print", "-p", prompt],
        capture_output=True, text=True
    )
    
    output = result.stdout
    match = Match(agent_a=a, agent_b=b)
    
    # Parse winner
    if "WINNER: A" in output or "WINNER:A" in output:
        match.winner = a
    elif "WINNER: B" in output or "WINNER:B" in output:
        match.winner = b
    else:
        # Couldn't parse, pick randomly
        match.winner = random.choice([a, b])
    
    match.reasoning = output
    return match
```

### `prompts.py`

````python
JUDGE_PROMPT = """You are judging two implementations of the same task.

## Task

{spec}

## Implementation A

```diff
{diff_a}
````

## Implementation B

```diff
{diff_b}
```

## Criteria

1. Correctness: Does it fulfill the requirements?
1. Code quality: Is it clean and maintainable?
1. Minimalism: Does it avoid unnecessary changes?

Compare the implementations and pick the better one.

End your response with exactly one of:
WINNER: A
WINNER: B
"""

```

---

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| All agents fail/timeout | Exit with error |
| Only 1 agent succeeds | Auto-wins, no tournament |
| Odd number of agents | One gets bye to next round |
| Judge output unparseable | Random selection, log warning |
| Agent produces no diff | Marked as failed |

---

## Dependencies

```

click

````

That's it. No pydantic, no rich, no gitpython. Shell out to git and claude.

---

## Usage

```bash
# Install
pip install -e .

# Run with inline prompt
parallel-agents "Add input validation to the create_user function" -n 4

# Run with spec file
parallel-agents --prompt-file task.md -n 8 -t 60

# In different repo
parallel-agents "Fix the bug" -n 4 --repo ~/projects/myapp --base-branch develop
````

______________________________________________________________________

## What's NOT in v1

- Planning phase (caller's responsibility)
- Resume support
- Cleanup commands
- Model selection
- Cost tracking
- Web UI
- Synthesis mode (combining implementations)
- Progress bars / fancy output
- State persistence

Can add later if needed.
