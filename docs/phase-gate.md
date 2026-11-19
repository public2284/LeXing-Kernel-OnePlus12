# Phase gate

`.phase-state` at the repository root holds the current project phase
(`phase0` … `phase5`). `build/checks/build_prereqs.sh` reads it at the start of
every kernel-build run and fails the run unless it says `phase3` or later.

Why this exists: GitHub Actions workflows are files in this repository, and any
collaborator with write access could dispatch them. The phase gate makes
'compilation cannot start early' a code-enforced rule rather than a promise.

Advancing the phase is a maintainer decision, made with the same review weight
as a release: it follows the Phase 0–5 plan in the project specification
(Chapter 10).

Current state: `phase1` — technical plan (Phase 0 reviewed and approved).
