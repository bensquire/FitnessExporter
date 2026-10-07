---
name: apple-docs
description: Look up Apple's developer documentation, WWDC transcripts and sample code offline with `scrapple`, before using a system API, choosing a system feature, or claiming what iOS or HealthKit does. Use whenever a change touches HealthKit, SwiftUI, URLSession, the Keychain (Security), FileManager and the Files app, Info.plist keys, entitlements, or a Human Interface Guideline.
---

# Apple's documentation, locally

`scrapple` (Homebrew, `/opt/homebrew/bin/scrapple`) keeps Apple's developer
documentation, WWDC transcripts, sample projects and their source files in a
local SQLite index at `~/.local/share/scrapple/`, about 300,000 pages in all.
Nothing leaves the machine. It backs the `native-check-apples-documentation`
rule.

The app targets iOS 18 on iPhone, so check a symbol's availability too. The
frameworks it uses are HealthKit, SwiftUI, Foundation (`URLSession`,
`JSONEncoder`, `FileManager`) and Security (the Keychain).

## When to ask it

- **Before calling an API** whose signature, default, availability or
  behaviour you aren't certain of. HealthKit especially: what a query returns
  for a day with no samples, what an authorization call does and doesn't tell
  you, which unit a type is read in.
- **Before building anything the system might already provide**, such as a
  form control, a store for a secret, or a way for the user to reach a file.
- **Before stating a platform fact**, in a comment, `PRIVACY.md`, or a usage
  string. The Human Interface Guidelines themselves aren't in the index (it
  covers `/documentation`, not `/design`); their conventions are in the WWDC
  design talks (search `--type talk`) and the framework docs.
- **When a doc says one thing and the app does another:** read the doc, then
  decide.

## Commands

```sh
scrapple search "<query>" --type doc  --limit 5 --human    # API reference and articles
scrapple search "<query>" --type talk --limit 5 --human    # WWDC transcripts, with timestamps
scrapple search "<query>" --type sample --limit 3 --human  # sample projects
scrapple search "<query>" --type code_file --limit 3 --human   # a file inside a sample
scrapple -h show "/documentation/healthkit/hkhealthstore/authorizationstatus(for:)"   # the full page
scrapple -h show <id>         # a talk or sample, by the id a JSON search returns
scrapple status               # how much is indexed (JSON)
```

- **Output format:** without `--human` (`-h`, before the subcommand for `show`)
  the output is JSON. A search gives `id`, `title`, `type`, `url`, `snippet`
  and `score`. Use JSON when a script reads it, and `-h` when you do. Quote a
  path that has parentheses in it.
- **Queries:** a symbol name is the best query (`HKStatisticsCollectionQuery`,
  `SecItemAdd`, `UIFileSharingEnabled`). A question in words works too,
  because the search is keyword and semantic together.
  - `--keyword-only` is exact and fast for a known name.
  - `--semantic-only` is for a concept you can't name.
  - A dot in a `--keyword-only` query (`HKStatistics.mostRecentQuantity`)
    fails with `fts5: syntax error near "."`. Use the separate words instead.
- **Samples:** `Creating A Mobility Health App` shows `HKStatisticsCollectionQuery`
  in a whole app (`--type sample`).
- **Long pages:** `show` prints the whole page. Pipe it through
  `sed -n '/^# /,/^## See Also/p'` for just the body, or `grep -n` for the part
  you want.
- **`scrapple sync`** refreshes the index. It takes hours from empty, so the
  user runs it, not you.

## When the index says nothing

The index has every page, but some pages are only a declaration. Look further,
in this order:

1. **The iOS SDK headers.** They often carry the detail the page leaves out.
   Grep `$(xcrun --sdk iphoneos --show-sdk-path)/System/Library/Frameworks/HealthKit.framework/Headers/`.
   That's where this one is: when a day has no samples, the statistics object
   for that day has nil quantities (`HKStatisticsCollectionQuery.h`,
   `enumerateStatisticsFromDate:toDate:withBlock:`) — which is why
   `fetchDailyStatistics` skips a day whose quantity is nil.
2. **The running app.** Build it for the simulator and try it
   (`workflow-hand-over-for-trial`). The simulator's runtime ships the Health
   app, so samples can be entered by hand; what HealthKit does with them on a
   real iPhone is the user's to try.
3. **If neither settles it,** say so, and say what the decision rests on.

## What to do with the answer

- **Use the documented API** at its documented signature.
- **Cite the page** where a decision rests on it: one short comment with the
  page's path, e.g.
  `// A denied read type reads as no data. /documentation/healthkit/hkhealthstore/authorizationstatus(for:)`.
  Cite a header as `HKStatisticsCollectionQuery.h, enumerateStatisticsFromDate:toDate:withBlock:`.
  A quote and a path are fine; a paragraph is not.
- **When a doc contradicts a rule in `.claude/rules/`,** raise it with the
  user. The doc is the platform's word, the rule is the project's, and only the
  user can change the rule.
