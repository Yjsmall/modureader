# AI notes for sentence-context cards

This describes working source added on 2026-10-12, not an already published
installer. Sentence-context cards now have persistent `notes`.

## Behavior

Configure and select an enabled AI provider with a model, endpoint and active
API key in Settings. While reading, select a word or phrase and tap **Context**.
The app saves the word and its original sentence immediately, then requests:

1. The word's specific meaning, part of speech and role in that sentence.
2. The sentence's meaning, main structure, clauses and important expressions.

The answer appears under **Notes** on the card in **Sentences**. It uses the
app's response language and remains available after reopening the app. Without
a usable AI configuration, collection continues normally with empty notes.
Existing cards with empty notes offer **Generate analysis** once AI is
configured. Collecting an already analyzed sentence does not generate it again.

While the request runs, the card shows a text status. On request or storage
failure, the original sentence remains saved and **Retry analysis** is available.
Leaving the popup or cards page does not cancel the background save. Deleting
the card prevents a late response from recreating it. A late response also
cannot overwrite notes changed after the request started.

## Implementation boundaries

`SentenceContextNotesService` coordinates collection, one in-flight request per
card, failure state and persistence. It uses the shared AI transport, protocol
selection, key rotation and request throttling. Requests contain only the
selected word and sentence; they do not fetch chapters or use agent/search
tools. The response is plain text with word-meaning and sentence-analysis
sections. Reasoning envelopes are removed before saving, and empty answers
are rejected. Requests have a two-minute overall timeout.

The transport's optional `throwOnError` mode lets background tasks receive
failures instead of storing chat error messages as successful notes. Existing
chat callers keep the default error-display behavior.

Database version 10 adds a non-null `notes` column with an empty-string default
to `tb_sentence_contexts`. Version 9 migration preserves all collected words,
sentences and source positions. Notes belong to the existing local collection;
this change does not add a new sync transport for sentence cards.

## Verification

Regressions cover configuration checks, request scope, automatic collection and
generation, duplicate-request coalescing, network/empty-answer/storage failure,
retry, stale responses, and durable notes across the version 9 migration.
Loopback HTTP tests exercise real streaming answers and HTTP authentication
failures without using a paid or external AI service.

Widget checks cover loading, failure, retry and reopening, leaving a pending
request, and notes at 375 × 812, 844 × 390 and 1024 × 768 in light/dark themes
with doubled text size and reduced motion. Native-device AI acceptance was not
performed; these checks establish host-side behavior.

Verified with Flutter 3.47.2 / Dart 3.13.2 on Linux x64:

- Static analysis: no issues.
- Notes service, database migration and cards tests: 31 passed.
- Reader sentence-context/selection/input/image JavaScript tests: 81 passed.
- Project identity/documentation checks: 8 passed.
- Full Flutter suite: 2,655 passed, 13 skipped and 14 failed. The failing test
  names match the earlier [cleanup review](code-review-2026-10-12.md); no new
  failing tests were introduced. This is not a fully passing suite.

Database tests used the temporary SQLite library path documented in that
review. No system libraries or runtime dependencies were changed.
