# My App Development Style

A reusable spec describing how I like my apps built. Paste this into a prompt when asking to build or scaffold a new app so the result matches my preferences by default. It is intentionally **app-agnostic** — no product features, just principles, patterns, and defaults.

---

## How to use this document

When building me an app, treat the sections below as the default rules. If a rule genuinely doesn't fit the app, say so and propose an alternative — don't silently ignore it. Prefer my stated defaults over "the popular way" unless there's a concrete reason.

---

## 1. Guiding principles

- **Focus over features.** One clear purpose, executed well. No account systems, analytics dashboards, or social layers unless I explicitly ask. Scope discipline is a feature.
- **Native and modern.** Use the platform's newest first-party frameworks and lean on the system look. Personality comes from color and motion, not from re-skinning native controls.
- **Legibility is non-negotiable.** Text must always be readable, including on user-chosen or dynamic backgrounds. Compute contrast at runtime rather than assuming.
- **Tactile and physical.** Interactions should feel like real objects — haptics, spring animations, feedback tied to real events. Never decorative motion.
- **Consistency through tokens.** Spacing, radii, borders, sizes, and colors are defined once and referenced everywhere. No magic numbers scattered across views.
- **Structure where complexity earns it.** Don't apply heavy architecture to simple screens. Add a view model / abstraction only when the screen genuinely needs it.
- **Calm by default.** Progressive disclosure — hide advanced controls until they're needed. Keep the default screen quiet.

---

## 2. Platform & stack defaults

- **Platform:** Apple (iOS/iPadOS first), universal for iPhone + iPad from one codebase.
- **UI:** 100% SwiftUI. Target a recent OS version so I can use current APIs (SwiftData, App Intents, symbol effects, numeric content transitions, materials).
- **Persistence:** SwiftData (`@Model`, `@Query`, `ModelContext`) over Core Data. Design models to be CloudKit-ready even if sync isn't wired up yet.
- **Navigation:** `NavigationStack` with a typed route enum (coordinator pattern). No stringly-typed navigation.
- **No unnecessary third-party dependencies.** Reach for a package only when it solves a real problem the platform doesn't (e.g. a color/contrast utility). Justify each one.
- **Voice/automation:** wire up App Intents / Siri shortcuts for the primary action when it makes sense.

> If I ask for a non-Apple platform, keep the *principles* (tokens, adaptive contrast, tactile feedback, focus) and map them onto that stack's idioms.

---

## 3. Architecture

- **Mixed state management, by complexity:**
  - Simple views may read/mutate the model directly — don't wrap a one-line action in a view model.
  - Complex screens (forms with validation, staged edits, save/delete orchestration) get a proper `ObservableObject` view model (MVVM).
- **Design tokens as enums:** define `Spacing`, `CornerRadius`, `BorderWidth`, `IconSize`, and colors as named tokens accessed fluently (e.g. `.spacing.medium`). Single source of truth.
- **Colors in the asset catalog** so they get automatic light/dark variants, surfaced as typed color symbols.
- **Progressive disclosure in the UI:** surface search/sort/advanced options only past a sensible threshold; tuck secondary actions into menus.
- **Native empty & error states** (e.g. `ContentUnavailableView`) — don't hand-build these.

---

## 4. Visual style

- **Typography:** system font throughout. No custom fonts unless I ask. For any prominent numbers/data, use **monospaced digits** so values don't jitter as they change.
- **Color:** a small, curated, warm/muted palette. Offer **tasteful presets** as the primary way to pick colors, with a full picker as an escape hatch. Presets should make a screen look intentional even when filled with many items.
- **Adaptive contrast:** whenever an element sits on a user-chosen or variable background, compute the text/foreground color from the background's contrast ratio at runtime. Legibility must never depend on the user's color choice.
- **Depth:** soft, often color-matched shadows; hairline strokes at low opacity so light elements don't dissolve into the background. Use system materials (`.regularMaterial` / `.ultraThinMaterial`) for chrome so controls recede behind colorful content.
- **Layout:** adaptive grids/stacks driven by size class — one layout that adapts, not a separate iPad codebase. Fixed comfortable sizes per size class.

---

## 5. Motion & feedback

- **Springs, not linear animations** — motion should feel physical.
- **Animate meaningful changes** (numbers rolling, elements appearing) and tie every animation to a real event. No idle/decorative motion.
- **Haptics** on primary interactions (a heavy impact for the main action, lighter for secondary). The app should be fully usable **silently** — carry feedback with haptics, not sound. No sound unless I ask.
- **Press feedback:** interactive elements scale down slightly while pressed (custom button style, spring).

---

## 6. Accessibility (always on)

- Full accessibility identifiers, labels, and values on interactive and dynamic elements — these double as UI-test hooks.
- **Dynamic Type** support via scaled metrics; allow text to scale and shrink gracefully.
- Runtime adaptive contrast (see §4) is part of accessibility, not just aesthetics.
- Respect light/dark mode automatically via asset-catalog color variants.
- Confirm destructive actions with a dialog.

---

## 7. Quality & tooling

- **Unit tests** for core logic (state transitions, guards, validation rules).
- **UI tests** for the real flows, reusing the accessibility identifiers.
- **Seeded showcase/demo data** behind a launch flag (e.g. `-ShowcaseData`) that loads an in-memory store — useful for previews, tests, and screenshots without polluting real data.
- **Automate marketing/App Store assets** with a script so screenshots are reproducible from a command, not hand-made each time the UI changes.
- SwiftUI `#Preview`s backed by an in-memory container.

---

## 8. Defaults checklist (quick reference)

- [ ] SwiftUI, universal, recent-OS target
- [ ] SwiftData persistence, CloudKit-ready model
- [ ] Typed navigation (coordinator enum + `NavigationStack`)
- [ ] Design tokens (spacing / radius / border / color) as a single source of truth
- [ ] Curated color presets + full picker escape hatch
- [ ] Runtime adaptive contrast for text on variable backgrounds
- [ ] Monospaced digits for changing numbers
- [ ] Spring animations tied to real events
- [ ] Haptic feedback; silent-usable; no sound by default
- [ ] MVVM only where complexity earns it
- [ ] Full accessibility identifiers/labels/values + Dynamic Type
- [ ] Progressive disclosure (hide advanced controls until needed)
- [ ] Native empty/error states
- [ ] Unit + UI tests; seeded demo data behind a launch flag
- [ ] Scripted, reproducible App Store assets

---

*Keep this focused and app-agnostic. When a specific app conflicts with a rule here, flag the conflict and propose an alternative rather than dropping the principle.*
