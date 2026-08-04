# App Store listing

Source of truth for the App Store Connect listing. Screenshot captions live
separately in [`Marketing/copy.json`](../Marketing/copy.json) and are quoted
here so the two stay aligned — if you change one, change the other.

## Naming

Three names, deliberately different — do not "fix" them to match:

| Name | Where | Value |
| --- | --- | --- |
| App Store name | App Store Connect listing, privacy policy | **Tapper Counters** |
| Display name | Home screen, `CFBundleName` | **Tapper** |
| Repository / folder | GitHub, local checkout | **Tapper** |

Long-form copy (listing, policy) uses *Tapper Counters* on first mention and
may shorten to *Tapper* thereafter. The home screen stays *Tapper* because
that is what fits under the icon.

> **Unresolved before submission**
>
> - **Support URL.** App Store Connect requires an `https://` URL, not a
>   `mailto:`. The public repository at <https://github.com/JCTec/Tapper> is the
>   obvious candidate — confirm before submitting.
> - **Privacy policy URL.** [PRIVACY.md](PRIVACY.md) needs publishing somewhere
>   Apple can fetch it.
> - **CloudKit.** The entitlements declare an iCloud container, but no sync is
>   wired up. Do not claim sync in the listing until it ships.

## Metadata

| Field | Value | Limit |
| --- | --- | --- |
| Name | `Tapper Counters` | 30 |
| Subtitle | `Tally anything with one tap` | 30 |
| Category (primary) | Utilities (`public.app-category.utilities`) | — |
| Category (secondary) | Productivity | — |
| Age rating | 4+ | — |
| Price | Free | — |
| Bundle ID | `com.jctec.Tapper` | — |
| Version | 1.0 | — |
| Copyright | © JCTec | — |
| Support email | `juancarlos_tec@proton.me` | — |
| Support URL | _Confirm — likely <https://github.com/JCTec/Tapper>_ | — |
| Marketing URL | _Optional_ | — |
| Privacy policy URL | _Publish [PRIVACY.md](PRIVACY.md)_ | — |

## Promotional text

Updatable without a new build; keep it to 170 characters.

```
Create as many counters as you like, each with its own color and step size. Tap
to count reps, laps, or inventory. No account, no ads, no tracking.
```

## Description

```
Tapper Counters is a tap-to-count app that stays out of your way.

Make a counter, give it a name and a color, and tap. That's the whole app —
no account, no setup, no sign-in wall.

COUNT ANYTHING
Reps and sets. Laps in the pool. Stock on a shelf. Birds on a walk. Cars in a
traffic survey. Anything you'd otherwise track on paper or in your head.

BUILT FOR SPEED
Full-screen controls sized for repeated tapping, so you can keep counting
without looking closely. Numbers animate cleanly and stay aligned as they grow.

MADE YOURS
- Pick a color for every counter, from curated presets or the full color picker
- Set a custom increment — count by 1, 5, 25, or whatever suits the task
- Allow negative values per counter when you need to count down
- Search and sort as your list grows

READABLE ON ANY COLOR
Tapper measures the contrast of the color you choose and adjusts label color
automatically, so counters stay legible whatever palette you pick.

SIRI AND SHORTCUTS
Say "Open Tapper" or "Start counting with Tapper" to jump straight in.

PRIVATE BY DESIGN
Your counters are stored on your device. Tapper has no account system, no
analytics, no advertising SDKs, and no tracking. Nothing is collected, so
there's nothing to share.

IPHONE AND IPAD
One universal app, laid out for both.
```

## Keywords

Comma-separated, 100 characters maximum, no spaces after commas. Apple already
indexes the name and subtitle, so `counters`, `tally`, and `tap` are omitted
here — repeating them wastes characters.

```
clicker,reps,workout,laps,inventory,score,tracker,manual,increment,knitting,steps,tasks
```

87 of 100 characters.

## What's New (version 1.0)

```
First release.

- Create unlimited counters, each with its own name, color, and increment
- Full-screen counting view with large, repeat-friendly controls
- Optional negative values per counter
- Search and sort your counters
- Automatic label contrast against any background color
- Siri and Shortcuts support
- Universal iPhone and iPad app
```

## App privacy answers

Matches [PRIVACY.md](PRIVACY.md). All three are "no":

| Question | Answer |
| --- | --- |
| Data collected | None |
| Data used to track you | No |
| Third-party advertising | No |
| Account required | No |

## Screenshots

Upload from `AppStoreAssets/`. The captioned `-showcase` sets are the intended
uploads; the `-plain` sets are bare screenshots kept as a fallback.

| Display | Directory | Size | Count |
| --- | --- | --- | --- |
| 6.9-inch iPhone | `iPhone-6.9-showcase/` | 1320 × 2868 | 4 |
| 6.5-inch iPhone | `iPhone-6.5-showcase/` | 1242 × 2688 | 4 |
| 13-inch iPad | `iPad-13-previews/` | 2064 × 2752 | 3 |

Captions, in order — these are generated from `Marketing/copy.json`:

| # | Title | Subtitle |
| --- | --- | --- |
| 1 | All Your Counters | Colorful tappers, sorted and ready. |
| 2 | Tap To Count | Big controls for quick sessions. |
| 3 | Stay In Flow | Reset or edit without losing focus. |
| 4 | Color Code It | Spot every counter at a glance. |

Regenerate with `bundle exec fastlane screenshots`. See
[SCREENSHOTS.md](SCREENSHOTS.md).
