# Code review and cleanup — 2026-10-12

Source baseline: `187281a8dc1ea3f9e19618693506b0015804de9d`, Modu
`1.2.7+10117`. Verification used Linux x64, Flutter 3.47.2 and Dart 3.13.2.
Changes are in the working tree; this record does not describe a release.

## Scope

Screened application Dart imports, exports, parts and symbol references,
including tests and source-reading JavaScript regressions. Reviewed document
metadata persistence, configuration transfer, sync connection testing and
unused implementations. Generated asset/font catalogs remain generator-owned.
This is a focused code cleanup, not an exhaustive review of every platform,
vendored dependency or runtime path. The pre-existing `.gitignore` modification
was preserved.

## Findings addressed

1. **Document-type writes did not restore failed changes.** SharedPreferences
   updates its local cache before platform I/O. Manual type corrections could
   therefore appear saved after a failed write, while detected-type writes
   ignored a `false` result. Both now report failure and attempt cache rollback;
   subsequent writes wait for recovery and can succeed.
2. **Four stores duplicated serialization and rollback.**
   [JsonPreferenceStore](../../lib/service/local_data/json_preference_store.dart)
   now handles JSON-object updates for layouts, reading modes, PDF state,
   document types and OCR styles. Queues are shared by preferences instance and
   storage key, so independent store wrappers cannot overtake a rollback.
   Unrelated keys and preferences instances can proceed independently. Failed
   operations do not poison the queue, and completed queue entries are removed.
3. **Sync connection checks duplicated the same workflow and accessed a nullable
   UI context after network work.** Both checks now share validation, error
   handling and logging. Localized messages are resolved before the request,
   with a Chinese fallback when no navigator context exists. The unused
   alternative string-based error classifier was removed; the existing
   sanitized sync error formatter remains authoritative.
4. **TTS preference mapping was duplicated between direct imports and legacy
   global imports.** `TtsConfigTransfer.preferenceValues` validates and produces
   the common mapping used by both paths. Existing provider, voice, buffer and
   playback settings round-trip tests cover the migration.
5. **Reflow text was normalized twice for every page.** The page factory now
   normalizes once and hashes that same text. Cache formats and revision hashes
   retain their existing meaning. TTS service lookup also uses enum names and
   an explicit fallback instead of string splitting and exception control flow.
6. **Unused implementations obscured the active paths.** Removed 13 tracked Dart
   source files: the old AI cache and its provider, statistics singleton, old AI
   page, three settings helpers, two obsolete route wrappers, old sync button,
   empty PDF conversion placeholder, native preferences-path helper and legacy
   WebView initializer. The unused provider's local generated companion was
   also removed. Disabled callers and documentation links were cleaned up.
   Existing cache files, preferences and chat histories are not deleted.
7. **Reader regression fixtures covered removed code and omitted a dependency.**
   Wiring assertions now cover the active EPUB player and initial URL builder.
   The selection VM fixture imports/injects the actual `rangeSentence` module
   and checks the published sentence. Its missing dependency failure reproduced
   using the HEAD version of that test before the fixture repair.

Application Dart source was reduced by a net 721 lines, including the new
70-line JSON store and excluding tests, documentation and generated files.

## Persistence boundaries

Domain validation remains in the existing stores/models. Layout and PDF state
writes reject malformed collections without overwriting them. Classification,
type and OCR-style caches retain their existing ability to recover malformed
collections. Reads remain tolerant. No keys or persisted schemas were renamed,
and per-document state remains excluded from global settings transfer.

Rollback is best effort: if the platform also rejects restoration, the original
write exception remains the result. This helper coordinates writes within one
preferences instance/isolate; it is not a cross-process transaction system.

## Verification

- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --no-pub test/service/book_player test/service/document_reflow_store_test.dart test/widgets/document_text_style_test.dart test/service/local_data/json_preference_store_test.dart test/service/sync/sync_connection_tester_test.dart test/service/config_transfer`:
  **184 passed**. New regressions cover queued rollback, absent/existing values,
  false/throwing writes, rollback exceptions, encoding failures, strict/recovery
  policies, independent queues and missing navigator context.
- `MODU_JSDOM_ROOT=/tmp/modureader-review-js-deps node --test test/reader_smart_selection.test.mjs test/reader_desktop_input.test.mjs test/reader_mobile_image.test.mjs`:
  **79 passed**. jsdom 26.1.0 was installed only in that temporary directory.
- `python3 -m unittest discover -s test -p 'project_identity_test.py' -v`:
  **8 passed**. `git diff --check` also passed.
- Full Flutter suite with the temporary SQLite library path: **2,635 passed,
  13 skipped, 14 failed**. This is not a fully passing suite.

The initial full run failed 249 tests, mostly because this host exposes
`libsqlite3.so.0` but the FFI loader requests `libsqlite3.so`. A temporary symlink
at `/tmp/modureader-review-native/libsqlite3.so` points to the system library.
The second run used
`LD_LIBRARY_PATH=/tmp/modureader-review-native flutter test --no-pub` without
changing system libraries or project dependencies. Network-dependent tests
retained their existing explicit opt-in/skip behavior.

## Remaining full-suite findings

The following tests and the implicated product files were not changed by this
cleanup. They prevent a claim that the whole project passes its tests:

| Area | Failures | Observed result |
| --- | ---: | --- |
| Android haptics source guard | 1 | Expects `enableFeedback: false` in `home_page.dart`; that text is absent. |
| Home content geometry | 6 | At text scale 2, an exact boundary comparison rejects differences such as `628.4000000000001` versus `628.4`. |
| Narrow history dashboard | 1 | `MiniMetric` overflows vertically by 36 pixels. |
| Book-cover long press | 6 | Batch-selection expectations fail across the six target-platform variants. |

The haptics and home geometry failures also reproduce in a separate targeted
run with the corrected SQLite path. No native-device acceptance, package build
or live cloud-provider verification was performed.

For later structural work, the large preferences provider and EPUB player still
combine many responsibilities. Split them by settings domain and reader session
behavior with existing regression coverage, rather than moving methods solely
to shorten files. The initial URL builder and live reader-style script also
remain two active integration paths; a future shared snapshot must preserve
their different initialization/update timing.
