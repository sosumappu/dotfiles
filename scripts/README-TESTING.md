# GitHub Actions Testing with Act

This document explains how to test GitHub Actions workflows locally using the `act` tool.

## Prerequisites

1. **Install act**: `brew install act`
2. **Install Docker**: Docker Desktop or Colima
3. **Configure secrets**: Ensure `.envrc` contains required secrets

## Required Secrets in `.envrc`

```bash
GITHUB_TOKEN=<your-github-token>
DOCKERHUB_USERNAME=<your-dockerhub-username>
DOCKERHUB_TOKEN=<your-dockerhub-token>
```

## Test Script

Use the provided script to test workflows:

```bash
./scripts/test-github-actions.sh
```

### Usage Examples

```bash
# Interactive menu
./scripts/test-github-actions.sh

# List available workflows
./scripts/test-github-actions.sh list

# Test a specific workflow
./scripts/test-github-actions.sh ci-docker

# Test all workflows
./scripts/test-github-actions.sh all

# Show help
./scripts/test-github-actions.sh help
```

## Available Workflows

- **ci-docker**: Docker-based CI workflow (builds container images)
- **ci-host**: Host-based CI workflow  
- **security-scan**: Security scanning workflow
- **cleanup-containers**: Container cleanup workflow

## Act Configuration

The script uses the following act configuration:

- **Platform**: `-P ubuntu-24.04=-self-hosted` (runs directly on host)
- **Offline Mode**: `--action-offline-mode` (uses cached actions)
- **Secrets**: `--secret-file .envrc` (loads secrets from .envrc)

### Why Self-Hosted Runner?

Running with `-self-hosted` mode allows the workflow to access the Docker daemon directly, which is required for Docker-in-Docker operations in the ci-docker workflow.

## Testing Results

### ✅ Verified Working

All workflow infrastructure has been tested and verified working:

1. **Changes job** - Path filtering and matrix generation
2. **Docker access** - Docker daemon connectivity
3. **QEMU setup** - Multi-platform emulation
4. **Docker Buildx** - Advanced build features
5. **Cache management** - Docker layer caching
6. **Registry authentication** - DockerHub and GHCR login
7. **Docker builds** - Container image building

### Known Limitations

1. **Application dependencies**: Some builds may fail due to external dependencies (e.g., GitHub API rate limits, package availability)
2. **Secrets required**: Workflows requiring authentication need valid secrets in `.envrc`
3. **macOS compatibility**: Some Linux-specific features may not work on macOS
4. **Docker on GitHub Actions macOS runners**: Docker Desktop is not available on GitHub Actions macOS runners (including macOS-15). Docker runtime tests are automatically disabled in ephemeral macOS environments to prevent CI failures. See: https://github.com/sosumappu/dotfiles/actions/runs/20580139909/job/59105700534 and [GitHub Actions macOS runners documentation](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners#preinstalled-software)

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Solution**: Ensure Docker is running and accessible:
```bash
docker ps
```

### Issue: "authentication required"

**Solution**: Check that `.envrc` contains valid tokens:
```bash
source .envrc
echo $GITHUB_TOKEN
```

### Issue: "action not found"

**Solution**: Run with offline mode disabled to download actions:
```bash
act --pull
```

Then re-enable offline mode in the script or use `--action-offline-mode=false`.

## Manual Act Usage

If you prefer to run act directly without the script:

```bash
# Test ci-docker workflow
act push -W .github/workflows/ci-docker.yaml \
  -P ubuntu-24.04=-self-hosted \
  --action-offline-mode \
  --secret-file .envrc \
  --matrix os:ubuntu

# Test security-scan workflow  
act workflow_dispatch -W .github/workflows/security-scan.yaml \
  -P ubuntu-24.04=-self-hosted \
  --action-offline-mode \
  --secret-file .envrc
```

## References

- [Act Documentation](https://nektosact.com/)
- [Act Runners Guide](https://nektosact.com/usage/runners.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
