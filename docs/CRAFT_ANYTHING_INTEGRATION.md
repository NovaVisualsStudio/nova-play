# Craft Anything integration workflow

This document describes how to use [Craft Anything](https://github.com/storytold/craft-anything) as an optional inspection and quality-review assistant for **nova-play**. It does not add a runtime dependency to the published website and does not change the site's HTML, CSS, JavaScript, or deployment configuration.

## What it can contribute

Craft Anything's inspect → build → check workflow can help:
- inspect the public website as a visitor sees it (screenshots, visible text, layout, colours, fonts, spacing, and opened menus);
- compare a separate local rebuild or prototype against the current site;
- record evidence, unknowns, and remaining visual/functional gaps;
- ask a local coding agent to implement changes in a separate working copy, then review the result.

The upstream project is early alpha. Treat its similarity checks and agent output as review evidence, not as proof of correctness or accessibility.

## Safe review procedure

1. Install Craft Anything on a supported desktop host using the official upstream instructions.
2. Sign in to your chosen local coding agent independently, if you want agent-assisted edits. Never paste API keys, access tokens, or account credentials into this repository.
3. Start a new website inspection and use the deployed nova-play URL as the target.
4. Keep **Clean room** mode for the initial visual/behavioural inspection. This studies only what a visitor can see.
5. If asking an agent to build a revised version, use a separate copy/worktree and keep all generated edits there.
6. Review screenshots, check results, accessibility, responsive layouts, console/network errors, and actual browser behaviour.
7. Only after review, selectively port accepted changes to the normal development branch and run the project's own checks.

## Non-destructive rules

- Never edit or publish directly from an inspection session.
- Do not give an agent permission to delete files, change repository settings, publish, or push automatically.
- Keep secrets in local environment variables or the hosting provider's secret store; never commit them.
- Preserve the current deployed version until a reviewed replacement is ready.
- Do not claim the site is fully tested based only on a screenshot or similarity score.

## Host/device note

Craft Anything's desktop application and CLI require a supported desktop environment. This guide does not claim that the full app runs natively on Android. If working from an Android phone only, a supported remote desktop/computer is required to run the Craft Anything engine and local coding agent.

## Upstream references

- [Craft Anything source](https://github.com/storytold/craft-anything)
- [Generated tool reference](https://github.com/storytold/craft-anything/blob/main/docs/tools.md)
- [Upstream status and verification notes](https://github.com/storytold/craft-anything/blob/main/docs/STATUS.md)
- [Using Claude Code as the builder](https://github.com/storytold/craft-anything/blob/main/docs/claude-code.md)
