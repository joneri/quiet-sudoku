# Epic: Rename to Stillgrid Sudoku

Mode: Auto
Cost profile: Standard
Started: 2026-05-02

## Goal

Rename the app and repository-facing project identity from the prior Quiet/Quite Sudoku naming to Stillgrid Sudoku so the product can use one distinctive name across macOS, future iOS work, App Store metadata, and GitHub.

## Motivation

The intended name, Quiet Sudoku, collides with an existing App Store app. The current App Store listing also contains the typo Quite Sudoku. Stillgrid Sudoku gives the project a unique and calm product identity before the next App Store update.

## Non-goals

- Do not change Sudoku gameplay, UI behavior, persistence format, or board interaction.
- Do not change the App Store bundle identifier unless Apple distribution work explicitly requires a separate migration; the existing app update line must remain usable.
- Do not rewrite historical AIM archive artifacts that describe earlier completed work.

## Acceptance Criteria

- SwiftPM package, executable target, source directory, app entry point, app bundle display name, scripts, distribution examples, privacy text, screenshot-generation copy, and active repo docs use Stillgrid Sudoku naming.
- Existing local build and smoke-test scripts point at the renamed executable/app bundle.
- App Store distribution scripts still preserve the existing bundle identifier by default while exposing Stillgrid Sudoku environment variable names.
- GitHub repository identity is updated from `quiet-sudoku` to `stillgrid-sudoku`, and the local `origin` remote follows it.
- Verification confirms the renamed app builds and launches.
