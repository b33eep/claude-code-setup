---
name: deploy-staging
description: Deploy the current branch to the staging environment. Handles building the Docker image, pushing to the registry, and rolling out to the staging cluster. Use when the user says "deploy to staging", "push to staging", "rollout staging", or "test this in staging".
type: command
metadata:
  version: 1.0.0
  tags: [deployment, ci-cd]
---

# Deploy to Staging

## Overview

Deploys the current git branch to the staging environment. A complete deployment runs: build Docker image → tag with git SHA → push to registry → update staging Kubernetes deployment → verify rollout.

The skill wraps the team's deploy procedure so engineers don't memorize every step.

## Critical rules (always)

- NEVER deploy with uncommitted changes — stash or commit first
- NEVER deploy directly from `main` — staging is for feature branches only
- ALWAYS verify the rollout succeeded before reporting done
- If any step fails, stop and report — do not continue with a broken build

## Prerequisites

Before the first use, verify:

```bash
# Docker daemon running
docker ps > /dev/null 2>&1 || echo "ERROR: Docker not running"

# Kubectl context set to staging
kubectl config current-context | grep -q "staging" || echo "ERROR: kubectl not on staging"

# Registry credentials present
docker login registry.example.com || echo "ERROR: registry login required"
```

If any check fails, tell the user what to fix before proceeding.

## Decision Flow

### Step 1 — Verify clean working state

```bash
git status --porcelain
```

If output is non-empty, stop and ask the user: "You have uncommitted changes. Commit, stash, or discard them first. Which?"

### Step 2 — Capture branch info

```bash
BRANCH=$(git branch --show-current)
SHA=$(git rev-parse --short HEAD)
IMAGE_TAG="registry.example.com/app:staging-${SHA}"
```

If `BRANCH` is `main`, stop: "Staging deploys are for feature branches. Please switch to the branch you want to test."

### Step 3 — Build the image

```bash
docker build -t "$IMAGE_TAG" --target production .
```

If build fails, show the last 50 lines of Docker output and stop.

### Step 4 — Push to registry

```bash
docker push "$IMAGE_TAG"
```

If push fails: check `docker login registry.example.com` and retry once. If still failing, stop.

### Step 5 — Update staging deployment

```bash
kubectl set image deployment/app app="$IMAGE_TAG" -n staging
```

### Step 6 — Wait for rollout

```bash
kubectl rollout status deployment/app -n staging --timeout=5m
```

If rollout times out:
1. Run `kubectl describe pods -n staging | tail -50` to see what's failing
2. Show the output to the user
3. Ask: "Rollout failed. Want me to roll back?"
4. If yes: `kubectl rollout undo deployment/app -n staging`

### Step 7 — Verify

```bash
# Smoke test
curl -sf https://staging.example.com/health | grep -q '"ok":true'
```

Report to the user:

> Deployed `$BRANCH` (commit `$SHA`) to staging.
> Health check: passing.
> URL: https://staging.example.com

## Error handling

### Build fails

Show the last 50 lines of Docker output. Common causes:
- Missing build args (check `Dockerfile` for `ARG` statements)
- Outdated base image (try `docker pull` on the base, retry)
- Out of disk space (`docker system prune -af` if user confirms)

### Image push fails

Common causes:
- Registry credentials expired — run `docker login registry.example.com`
- Network connectivity — retry once after 10s
- Registry quota exceeded — ping #infra

### Rollout stuck

Common causes:
- Image pull error — check the image actually pushed (`docker pull "$IMAGE_TAG"`)
- Crash loop — check logs (`kubectl logs -n staging deployment/app --tail=100`)
- Resource limits — `kubectl describe pods -n staging | grep -A2 "Events"`

In all cases, offer the user a rollback option.

## Examples

### Example 1: Standard feature branch deploy

User says: "Deploy this to staging"

Actions:
1. `git status --porcelain` → clean ✓
2. Branch: `feat/new-onboarding`, SHA: `a1b2c3d`
3. `docker build -t registry.example.com/app:staging-a1b2c3d --target production .`
4. `docker push registry.example.com/app:staging-a1b2c3d`
5. `kubectl set image deployment/app app=registry.example.com/app:staging-a1b2c3d -n staging`
6. `kubectl rollout status deployment/app -n staging --timeout=5m` → success ✓
7. Health check passes ✓

Report: "Deployed `feat/new-onboarding` (a1b2c3d) to staging. Health: passing. URL: https://staging.example.com"

### Example 2: Uncommitted changes

User says: "Push this to staging"

Action 1: `git status --porcelain` → shows `M src/app.py`

Stop. Ask: "You have uncommitted changes in `src/app.py`. Commit them, stash them, or discard them first. Which?"

## Anti-patterns (do not do)

- **Do not deploy with `--no-verify` or any flag that skips checks.** The checks exist because they've caught real problems.
- **Do not deploy directly from `main`.** Staging is for testing; production deploys go through a different workflow.
- **Do not ignore rollout failures.** A stuck rollout often means the build is broken — shipping broken builds to the next stage wastes time.
- **Do not suppress error output.** The user sees the errors and can make informed decisions; silent failure leaves them guessing.

## Resources

- [Internal: Staging deployment runbook](https://wiki.example.com/runbooks/staging-deploy)
- [Internal: Kubernetes cluster layout](https://wiki.example.com/infra/k8s)
- [kubectl rollout docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rollout)
