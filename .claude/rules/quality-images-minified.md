---
title: Every Image Is as Small as It Can Be Without Showing It
impact: MEDIUM
impactDescription: Every byte of the icon ships in the app, and every byte of a screenshot is downloaded by whoever views it
tags: [quality, images, assets, size, png]
paths: ["screenshots/**", "icon/**", "FitnessExporter/Assets.xcassets/**", "README.md"]
---

## Every Image Is as Small as It Can Be Without Showing It

**Impact: MEDIUM**

The images here are the app icon, its 256 px preview, and `screenshots/`
(1284 × 2778 portrait, 2778 × 1284 landscape, and `icon.png`, an older version
of the app icon at 224 KB against the current 37.7 KB). Each is
minified to the highest degree that introduces no visible artefact. In order:

1. **The right container.** The icon and the screenshots are flat graphics
   with text, so PNG.
2. **Lossless first.** `oxipng -o max --strip safe`. The icon is never edited by
   hand: `icon/makeicon.swift` renders it, and `make icon` runs oxipng with
   Zopfli on both outputs.
3. **Then lossy, to the edge**, where the image allows it: quantize (with
   `pngquant` or ImageAlpha), lowering the colours until an artefact shows,
   then back up one step.
4. **Look.** Side by side with the original at 1:1, on the busiest region.

Report the before and after sizes in the commit. On 6 October 2026 every PNG
here was already at oxipng's lossless optimum: `-o max --strip safe` saved
0 bytes on the 37,715-byte icon and both screenshots (153,746 and 91,797
bytes). None has been tried lossy.

**Incorrect (an image added as exported, with no figures):**

```
Add screenshots
```

**Correct (what was run, the figures, and what is still open):**

```
screenshots/portrait.png   153,746 bytes   oxipng -o max --strip safe saved nothing (already optimal);
                                            not tried lossy, so not yet judged at 1:1
```
