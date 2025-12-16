# Proposal: Add Login Subtitle

## Summary

Add a subtitle beneath "Gather Now" with professional, work-themed text to reinforce the virtual office collaboration concept.

## Goals

- Add a `Label` node below the Title.
- Use engaging, work-environment themed text.
- Simple styling (no animation).

## Non-Goals

- Modifying the main title.

## Current Behavior

- Only "Gather Now" title exists.

## Proposed Behavior

- **New Node**: `Subtitle` (Label).
- **Text**: _"Your Virtual Office. Reimagined."_
- **Style**: 18px font, light grey color, centered.

## Spec Deltas

- `features/changes/add-login-subtitle/specs/ui/login-subtitle-spec.md`

## Risks / Edge Cases

- None.

## Test Strategy

- Manual verification.

---

## Antigravity Implementation Plan (verbatim)

# Add Login Subtitle

## Goal Description

Add a static subtitle label beneath the game title on the Login Screen.

## Proposed Changes

### UI

#### [MODIFY] [LoginScreen.tscn](file:///home/rzr/Dev/games/gather-now/ui/LoginScreen.tscn)

- Add `Label` node named `Subtitle` after the `Title` node.
- Text: "Your Virtual Office. Reimagined."
- Font size: 18px.
- Font color: Light grey `Color(0.7, 0.7, 0.7, 1)`.
- Centered horizontally.

## Verification Plan

### Manual Verification

1. Launch game.
2. Observe subtitle beneath the title.
