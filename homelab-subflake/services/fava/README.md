# Fava

Web interface for [Beancount](https://beancount.github.io/) plain-text accounting files.

## Overview

Fava provides a browser UI for navigating and editing a beancount ledger. The
ledger is stored in a private Gitea repository; [fava-helper](https://gitea.srv.vtimofeenko.com/spacecadet/fava-helper)
keeps the local checkout in sync via periodic pulls and push webhooks, and also
exports Prometheus metrics derived from BQL queries.

Access: `https://budget.srv.vtimofeenko.com` (port 5001 internally)

## Documentation

- [Fava docs](https://beancount.github.io/fava/usage.html)
- [Beancount language reference](https://beancount.github.io/docs/)
- [fava-helper README](https://gitea.srv.vtimofeenko.com/spacecadet/fava-helper)

## Implementation Notes

- Storage: `/var/lib/fava` — mounted from a `fava`-labelled partition. This is
  fava's own StateDirectory and also where fava-helper writes the beancount
  checkout (`/var/lib/fava/checkout`).
- **User sharing**: fava runs as a static `fava` user/group. fava-helper keeps
  `DynamicUser = true` but uses `Group = "fava"`, `UMask = "0027"`, and
  `ReadWritePaths = ["/var/lib/fava"]`, so all checkout files are group-readable
  by the `fava` user. Storing data in fava's StateDirectory sidesteps the
  `/var/lib/private` traversal restriction that DynamicUser imposes.
- **Webhook**: Gitea should be configured to push to port 9001 on the backbone
  network. Authenticate with `fava-webhook-secret`.
- **BQL metrics queries**: configured via `services.fava.settings.metricsQueries`
  in data-flake. Each query must return a single numeric row.
- `gitRepoUrl`, `beancountFile`, and `gitBranch` can be overridden per-host via
  `data.services.all.fava.settings` in the data-flake.
