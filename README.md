# GroundingContract — Demo App

**Same sentence. One digit different. Watch the verdict flip.**

A small SwiftUI app that makes the [`grounding-contract-kit`](https://github.com/rajatslakhina/grounding-contract-kit) library visible: pick an answer a model might have produced, pick the contract you want to enforce, and see exactly which claims survive, which get cut, and why.

## Why this matters

iOS 27 shipped `SpotlightSearchTool` — local RAG in two lines of Swift. What those two lines do not decide is what happens when the model's answer is *mostly* right.

The interesting case is not the obviously wrong answer. It's this one:

> **Corpus:** "The image cache evicts entries under a **48 MB** byte budget…"
>
> **Model:** "The image cache evicts entries under a **64 MB** byte budget."

~95% lexically identical. Every embedding cosine, every BM25 overlap, every "is this consistent?" judge prompt scores the fabricated one as supported. The switch ships **on**, so that answer opens red. Flip **Enforce numeric literals** off and watch the exact same claim turn green — the whole argument for the library, in one switch.

## What you can do in it

Six candidate answers. The **Outcome** column is what the app actually shows on the default contract (`redact`, support threshold 0.6, redaction budget 0.5) — and the interesting part is that four of them refuse for the *same* structural reason, which is itself the lesson:

| Answer | Per-claim verdict | Outcome on the default contract |
|---|---|---|
| **Mixed** *(default)* | 1 × `supported`, 1 × `unsupported` · `insufficientCoverage` | **Redacted** — the invented sentence disappears, the cited one stays |
| **Wrong number** | `unsupported` · `numericMismatch` · uncorroborated `64` | **Refused** — it is the only claim, so cutting it removes 100% of the answer, over the 50% budget |
| **Wrong identifier** | `unsupported` · `numericMismatch` · uncorroborated `inc-9115` | **Refused** — same reason |
| **Fully grounded** | 2 × `supported`, coverage 1.000 | **Answered** — nothing removed |
| **Half invented** | `weaklySupported`, coverage 0.407 | **Refused** — weak is below the bar, and it is the only claim |
| **Nothing grounded** | 2 × `unsupported` · `insufficientCoverage` | **Refused** — both claims cut, 100% of the answer |

That "100% of a one-sentence answer" collapse is not a bug in the demo, it is what the redaction budget *means*: `.redact` degrades gracefully only when there is something left to degrade to. Switch **On unsupported claim** to `annotate` to see every per-claim verdict with enforcement turned off, or to `refuse` to see the strict reading.

Two contract controls sit at the top of the report:

- **On unsupported claim** — a segmented picker: `annotate` / `redact` / `refuse`
- **Enforce numeric literals** — a switch, and the load-bearing one described above

The default state is already interesting: the app opens on **Mixed** under `.redact`, so the first thing you see is one claim cited and one claim cut.

## Screenshots

**There are none, and that is a deliberate statement rather than an omission.**

The app was **not** run on a Simulator for this release. This repo was produced by an unattended scheduled task, and computer-use access is not grantable in that mode. The refusal, verbatim:

> Computer-use access to "Simulator" can't be approved during a scheduled run. To grant it, send a message in this conversation (the approval card will appear), or add the app to the scheduled task's settings. (Retrying returns this same result.)

Three attempts were made, one of them narrowed to Simulator alone. No `Demo/Screenshots/` directory exists because no screenshot exists.

## What *was* verified

Two separate claims, stated separately, because conflating them is how "it builds" gets sold as "it works":

1. **The library's logic is verified, and so is this README's table.** 95 XCTest cases pass on Swift 6.0.3 in Swift 6 language mode, after a wiped `.build`, with `swift build -Xswiftc -warnings-as-errors` clean. This app has no test target — it is an app, and CI compiles it rather than running it — so the six rows above are asserted in the library's test suite — `DemoScenarioTests` for the outcomes and per-claim statuses, against a byte-identical copy of this app's corpus and answers, and `GroundingContractEngineTests.testPublishedCoverageFiguresAreGuardedByAnAssertion` for the coverage figures. A row that stopped being true would fail the library's build, not sit here as unchecked prose.
2. **Whether this app compiles is answered by CI, not by this sentence.** The `macos-15` job runs `xcodebuild -resolvePackageDependencies` — which resolves `grounding-contract-kit` **from GitHub over the version range the project declares** (`upToNextMajorVersion` from 1.1.0), not from a local path and not from a branch — and then `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'`, which compiles the whole app target including every SwiftUI view. The authoritative answer is the [Actions tab](../../actions); a result asserted in prose here would go stale on the next commit, and a result asserted *before* the job had ever run would simply be a fabrication.

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

**Two repos, not one.** The library repo contains no app target of any kind, and this repo depends on it the way any consumer would: an `XCRemoteSwiftPackageReference` at the real GitHub URL over `upToNextMajorVersion` from **1.1.0**. Not a local path, not `branch = main`. A branch reference means every clone and every CI run resolves whatever `main` happens to be that day, which is the wrong default for something a stranger will open once. Stated precisely, because it is the kind of thing READMEs round up: this is a semantic-version *range*, and no `Package.resolved` is committed, so a clone resolves the newest 1.x rather than one frozen commit. That is the intended trade-off for a sample — you get the library's patch fixes — and it is not the same thing as a pin.

**The app owns the content; the library owns the decisions.** `DemoCorpus` and `DemoAnswer` live here — they are the app's compiled-in stand-ins for what `CSSearchQuery` and a `LanguageModelSession` would return. Everything about claims, scoring, citations and enforcement lives in the library. That is the same split a real app has, and it is why the library is testable on Linux with no index, no network and no model.

**A new answer gets a new model.** `GroundingReportView` is identified by the selected answer's id, so switching answers is a fresh verification rather than a mutated one — which is also how it would behave against a real streaming response.

## License

MIT — see [LICENSE](LICENSE).
