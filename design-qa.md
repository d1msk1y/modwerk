# Post-download module overview — design QA

final result: passed

**Comparison target**

The selected “Inside your .bin” reference, refined for the repository’s real module content and the requested larger window. This is a production UI adaptation, with existing catalogue artwork, real version-matched captures and source-authored instructions.

- Source visual truth: `/var/folders/pq/8kctb9dj5yzfncd2xl2wkw1w0000gn/T/TemporaryItems/NSIRD_screencaptureui_tr9270/Bildschirmfoto 2026-10-09 um 07.40.01.png` (1684 × 1378 pixels; the generated mockup does not declare a CSS viewport or device scale).
- Implementation: `http://127.0.0.1:5173/?preview=firmware-feedback`.
- Implementation screenshot: `/Users/jannikassfalg/coding/modwerk/artifacts/module-feedback/post-download/desktop-final.png` (1440 × 1024 pixels, 1440 × 1024 CSS viewport, devicePixelRatio 1).
- State: dark theme, Mini Verb selected, four downloaded modules with the same versions as the reference, controls capture, quick test, no saved feedback. The development fixture uses production components with disposable local report actions.
- Full comparison: `/Users/jannikassfalg/coding/modwerk/artifacts/module-feedback/post-download/comparison-final.png`. Both modal regions cropped and normalized to 800 pixels wide without changing their aspect ratios. Source crop: 1572 × 1290; implementation crop: 1392 × 976. The source is an enlarged mockup; typography was also checked at native browser size, avoiding a claim of pixel identity.
- Focused readable comparison: `/Users/jannikassfalg/coding/modwerk/artifacts/module-feedback/post-download/detail-comparison-final.png`, quick-test instructions and feedback controls from both artifacts in the same image.
- Additional evidence: `/Users/jannikassfalg/coding/modwerk/artifacts/module-feedback/post-download/mobile.png` (390 × 844 CSS/pixels, DPR 1), `/Users/jannikassfalg/coding/modwerk/artifacts/module-feedback/post-download/laptop-scrolled.png` (1280 × 720 CSS/pixels, DPR 1).

**Findings and comparison history**

1. Initial browser inspection found catalogue artwork constrained by the existing 62 × 47 compact-preview rule, plus excessive caption height on a short screen. Fixed the scoped artwork dimensions, moved detailed captions to an accessible disclosure, and added height-sensitive spacing. Captures confirm correct image proportions, independent scrolling and a persistent footer.
2. First combined comparison (`comparison.png`, `detail-comparison.png` in the same evidence directory): [P2] instruction and module text was too small relative to the reference’s hierarchy. Increased instruction titles to 16px, body to 15px, names to 16px and summaries to 14–16px; adjusted the normal capture height so the quick test and feedback remain visible at 1440 × 1024. Increased signal visibility while retaining existing artwork.
3. Post-fix combined comparison (`comparison-final.png`, `detail-comparison-final.png`): no remaining actionable P0/P1/P2 findings. The three-step quick test and both feedback actions fit above the fixed footer. A native DOM measurement places the feedback controls at y=813–859, inside the guide pane ending at y=922. Longer instructions remain available by scrolling inside the modal.
4. Mobile inspection found the selected card could sit partly outside the horizontal module list. Added selection scrolling and reset guide/body scroll on module changes. Verified the selected Tape Echo card is fully visible, with body scroll reset to zero and no document overflow at 390px.

**Required fidelity surfaces**

- Fonts/typography: existing system font stack (`-apple-system, system-ui, Segoe UI, sans-serif`), weight 600 headings and step titles, 1.5–1.6 body line height. Clear display/body hierarchy; exact versions wrap safely. The mockup’s enlarged display scale is intentionally adapted to readable native CSS text rather than reproduced as screenshot pixels. Focused comparison verifies spacing and readable wrapping.
- Spacing/layout: enlarged desktop modal up to 1440px wide and 1000px tall, viewport-bounded with fixed header/footer. The guide has more horizontal room than the mockup to support real captures and longer copy. Independent desktop panes and a horizontal mobile module list prevent content loss. Dividers, padding, rounded selection state and lavender rail preserve the chosen composition.
- Colors/tokens: dark charcoal surface and borders, muted secondary copy, existing lavender primary/selected token, neutral working action and amber issue action. Feedback states use existing green/amber semantics. Visible focus ring verified.
- Image quality/assets: real module control/location captures, aspect ratios preserved, pixel rendering for LCD captures, paging and enlargement inside the same modal. Reused the repository’s approved catalogue artwork and icon components; no new imitation captures or generated placeholder media. Artwork differs from the conceptual mockup intentionally because the user requested the design work with actual content. Captures are labelled with their actual provenance in credits.
- Copy/content: “Inside your .bin” describes the download without claiming it has already been flashed. Machine, OS, all downloaded versions and actual summaries stay visible. Quick tests are bound to exact versions; other modules use their authored usage steps. Historical versions explicitly explain unavailable guidance instead of silently showing newer controls. Flashing help stays in the overlay.

**Interaction and responsive checks**

- Delayed opening: simulated download initially has no dialog, then opens via the production eight-second scheduler; scheduler tests cover deadline and cross-tab claims.
- All four module choices and Next navigation; selected card visibility and scroll reset.
- Control/location screenshot paging and successful actual asset loading.
- Enlarging, returning, and Escape returning to the quick test with focus restored to the screenshot control.
- Full setup steps and flashing help open in the same overlay.
- Local per-module working confirmation and issue submission; issue dialog returns to the overview with both statuses preserved and other modules available.
- Dismiss and reopen via the development fixture; production panels retain Open module guide for the same build.
- 1440 × 1024 desktop, 1280 × 720 laptop scrolling, and 390 × 844 mobile: no horizontal document overflow, footer remains accessible, long content scrolls inside the overlay.
- Browser console error/warning check returned an empty list. A transient asset load failure during catalogue regeneration was retried after generation and the actual location screenshot loaded successfully; the user-facing missing-image fallback was also exercised.

**Implementation checklist**

- [x] Larger responsive modal with persistent downloaded module overview.
- [x] Real version-matched screenshots, inline enlargement and usage documentation.
- [x] Per-module feedback with exact build context.
- [x] Short-delay scheduler and guide reopen action.
- [x] Native browser comparison, keyboard and responsive verification.

Residual limits: real firmware flashing and hardware sound behavior were not exercised; this change concerns the website’s guide and reporting UI. Backend report delivery is covered by existing automated tests; the browser preview deliberately submits locally.

Automated validation on the current-main base passed: `VITEST_MAX_WORKERS=1 npm run check -- --base origin/main`, 198 test files / 1,382 tests, licence/catalogue/SDK checks, lint, type checks and production bundle. The default parallel runs hit variable five-second timeouts in existing module-doctor/backend tests under local CPU load; the supported single-worker override preserved all assertions and timeouts. Full log: `artifacts/module-feedback/post-download/check-single-worker.log`. No native firmware build was required.

CI follow-up: two runs of the original parallel check passed 1,381 tests but exceeded Vitest’s default five seconds in the catalogue-wide module-doctor integration test. That test now allows the complete catalogue check to finish, with a 30-second child-process deadline and a 35-second test deadline. Every result and catalogue assertion remains intact; a hung CLI is now bounded. The final unmodified-parallelism `npm run check -- --base origin/main` passed all 1,382 tests and all other required stages. Log: `artifacts/module-feedback/post-download/check-final.log`.
