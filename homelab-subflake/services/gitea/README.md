# Gitea

Self-hosted Git service with web interface, issue tracking, and CI/CD integration.

## Overview

Gitea provides a lightweight alternative to GitHub for hosting Git repositories. Includes web UI, issue tracker, wiki, pull requests, and standard Git protocol support.

Access:
- **Web**: `https://gitea.srv.<publicDomain>`
- **SSH**: `ssh://git@gitea.srv.<publicDomain>:22`

## Documentation

- [Official Gitea Docs](https://docs.gitea.io/)
- [API Documentation](https://docs.gitea.io/en-us/api-usage/)
- [Git Command Reference](https://git-scm.com/docs)

## Quick Start

```bash
# Clone repository
git clone https://gitea.srv.<publicDomain>/username/repo.git

# Clone via SSH
git clone ssh://git@gitea.srv.<publicDomain>:22/username/repo.git

# Add auto-created remote
git remote add gitea gitea@gitea.<publicDomain>:<username><repo>

```

## Implementation Notes

- Database: PostgreSQL (via database service)
- Storage: `/var/lib/gitea`
- Backups: Daily (excludes dumps and temp files)
- Metrics: Available at `/metrics` endpoint
