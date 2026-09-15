# GroundingContract — Demo App

**Same sentence. One digit different. Watch the verdict flip.**

A small SwiftUI app that makes the [`grounding-contract-kit`](https://github.com/rajatslakhina/grounding-contract-kit) library visible: pick an answer a model might have produced, pick the contract you want to enforce, and see exactly which claims survive, which get cut, and why.

## Why this matters

iOS 27 shipped `SpotlightSearchTool` — local RAG in two lines of Swift. What those two lines do not decide is what happens when the model's answer is *mostly* right.

The interesting case is not the obviously wrong answer. It's this one:

> **Corpus:** "The image cache evicts entries under a **48 MB** byte budget…"
>
> **Model:** "The image cache evicts entries under a **64 MB** byte budget."

~95% lexically identical. Every embedding cosine, every BM25 overlap, every "is this consistent?" judge prompt scores the fabricated one as supported. The demo lets you flip **Enforce numeric literals** off and watch that exact claim turn green — which is the whole argument for the library in one toggle.

## What you can do in it

Six candidate answers, each hitting a different branch of the contract:

| Answer | What it demonstrates |
|---|---|
| **Mixed** *(default)* | One grounded claim, one invented one → **redacted**, the invented sentence disappears |
| **Wrong number** | 64 MB against a corpus that says 48 MB → `numericMismatch`, uncorroborated figure `64` named |
| **Wrong identifier** | `INC-9115` against `INC-9114` → caught by the same channel; identifiers get no tolerance |
| **Fully grounded** | Two claims, both cited, coverage 1.000 → **answered** |
| **Half invented** | Real subject, invented mechanism → coverage 0.407 → `weaklySupported`, reported but not shippable |
| **Nothing grounded** | Redaction would remove everything → escalates to **refusal** rather than returning a shredded paragraph |

Two contract controls at the top of the report:

- **On unsupported claim** — `annotate` / `redact` / `refuse`
- **Enforce numeric literals** — the load-bearing toggle described above

The default state is already interesting: the app opens on **Mixed** with the default `.redact` policy, so the first thing you see is one claim cited and one claim cut.

## Screenshots

**There are none, and that is a deliberate statement rather than an omission.**

The app was **not** run on a Simulator for this release. This repo was produced by an unattended scheduled task, and computer-use access is not grantable in that mode. The refusal, verbatim:

> Computer-use access to "Simulator" can't be approved during a scheduled run. To grant it, send a message in this conversation (the approval card will appear), or add the app to the scheduled task's settings. (Retrying returns this same result.)

Three attempts were made, one of them narrowed to Simulator alone. No `Demo/Screenshots/` directory exists because no screenshot exists.

## What *was* verified

Two separate claims, stated separately, because conflating them is how "it builds" gets sold as "it works":

1. **The library's logic is verified.** 77 XCTest cases pass on Swift 6.0.3 in Swift 6 language mode, after a wiped `.build`, with `swift build -Xswiftc -warnings-as-errors` clean. Every number in the table above is pinned by an assertion in that suite, not taken from a screenshot and not taken from a description.
2. **Whether this app compiles is answered by CI, not by this sentence.** The `macos-15` job runs `xcodebuild -resolvePackageDependencies` — which resolves `grounding-contract-kit` **from GitHub at tag `v1.0.0`**, not from a local path — and then `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'`, which compiles the whole app target including every SwiftUI view. The authoritative answer is the [Actions tab](../../actions); a result asserted in prose here would go stale on the next commit, and a result asserted *before* the job had ever run would simply be a fabrication.

What is **not** verified: that the app launches, that the UI lays out correctly, or that tapping through the six answers behaves as described at runtime. Those claims need a Simulator run, and a Simulator run did not happen.

## How to run it

```bash
git clone https://github.com/rajatslakhina/grounding-contract-demo-app.git
cd grounding-contract-demo-app
open Demo.xcodeproj
```

Then: select the **Demo** scheme (it's committed as a shared scheme, so it's there on a fresh clone), pick any iOS Simulator, and **Build & Run** (⌘R). Xcode resolves `grounding-contract-kit` from GitHub on first open — no local checkout of the library is needed.

Requires Xcode 16+ and iOS 17+.

## Design decisions

**Two repos, not one.** The library repo contains no app target of any kind, and this repo depends on it the way any consumer would: an `XCRemoteSwiftPackageReference` at the real GitHub URL, pinned `upToNextMajorVersion` from **1.0.0**. Not a local path, not `branch = main`. A branch reference means every clone and every CI run resolves whatever `main` happens to be that day, which is the wrong default for something a stranger will open once.

**The app owns the content; the library owns the decisions.** `DemoCorpus` and `DemoAnswer` live here — they are the app's compiled-in stand-ins for what `CSSearchQuery` and a `LanguageModelSession` would return. Everything about claims, scoring, citations and enforcement lives in the library. That is the same split a real app has, and it is why the library is testable on Linux with no index, no network and no model.

**A new answer gets a new model.** `GroundingReportView` is identified by the selected answer's id, so switching answers is a fresh verification rather than a mutated one — which is also how it would behave against a real streaming response.

## License

MIT — see [LICENSE](LICENSE).
