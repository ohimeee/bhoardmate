# BHoardMate splash animation

Splash → login hand-off for the Android app. 1080 × 2400 design canvas, 60 fps, **3.2 s** total
(`AnimationController(duration: Duration(milliseconds: 3200))`).

Only the existing logo shapes are animated (paths copied 1:1 from `../logo/*.svg`), only the three brand colours are used,
and the key frames were checked pixel-for-pixel against the logo files:

| Frame | Matches | Differing pixels (of 2.59 M) |
|---|---|---|
| 0.00 s (first) | `bhoardmate-icon.svg` B, 360 px tall, centred | 0 |
| 2.40 s (hold) | `bhoardmate-wordmark-dark.svg`, centred | 2 (anti-aliasing) |
| 3.18 s (last) | `bhoardmate-wordmark-light.svg` at the login position | 3 (anti-aliasing) |

## Files

| File | What it is |
|---|---|
| `bhoardmate-splash.mp4` | 1080 × 2400, 60 fps, H.264, BT.709 |
| `bhoardmate-splash-preview.gif` | 540 × 1200, 30 fps preview |
| `bhoardmate-splash.json` | Lottie (v5.7, 60 fps, 192 frames, 86 KB). Plays with the `lottie` Flutter package. Markers: `handoff_start` (frame 154), `end` (191) |
| `bhoardmate_splash.dart` | Drop-in Flutter widget (no packages): `BHoardMateSplash(onFinished: …)`. Analyzer-clean on Flutter 3.47; its rendered frames were diffed against the MP4 frames |

## The story (5 + 1 steps)

1. **0 – 300 ms** – cream B alone, centred (same as the app icon). Stillness so it reads as a continuation of the native splash.
2. **300 – 700 ms** – the m piece turns yellow and swells 3.5 % (it "lights up").
3. **700 – 2040 ms** – small wind-up (10 px left, 5° clockwise), then the m slides out to the right on a gentle arc, turns
   95° counter-clockwise to stand upright and shrinks to the size of the wordmark's M. It lands with a 6 % pop.
   With the m gone, the B is briefly just its stem (as in the round-10 storyboard).
4. **920 – 2160 ms** – the B shrinks and moves left (a camera zoom-out of the whole wordmark), its cream bowls draw back on
   along the exact m stroke so the B is whole again, "Hoard" slides in between B and M, "ate" after the M (50 ms stagger, left → right).
5. **2160 – 2560 ms** – full dark wordmark held, centred (0.4 s).
6. **2560 – 3160 ms** – hand-off: green fades to cream, BHoard turns green ("Mate" stays yellow), the wordmark shrinks
   to 90 % and rises to the login position. Last frame = light wordmark at the top of a cream screen. The app fades in the login form afterwards.

## Final position of the wordmark (for the login screen)

Draw `bhoardmate-wordmark-transparent.svg` with its **full viewBox (6758 × 949)** into this rect:

| | 1080 × 2400 px | Relative (use this on other screens) |
|---|---|---|
| left | **140.0** | centred horizontally |
| top | **604.0** | — |
| width | **800.0** | **74.07 %** of screen width |
| height | **112.34** | width × 949 / 6758 |
| centre | (540.0, **660.17**) | (50 %, **27.51 %** of screen height) |

Visible ink inside that rect: x 154.2 → 925.2 (771.0 px wide), cap top 618.2, top of the "d" 614.5, baseline 702.1.

In Flutter: `SplashTimeline.loginWordmarkRect(MediaQuery.sizeOf(context))` returns exactly this rect for any screen size.

Other reference positions (1080 × 2400):

* **Start B** (stem + bowls, 218 × 236 B units): left 373.73, top 1020.0, 332.54 × 360.0. At density 2.625 that is 137 dp tall.
  If you use the Android 12 SplashScreen API, size the native splash icon so its B matches this, then start the animation on the first Flutter frame.
* **Dark wordmark on hold**: viewBox rect left 94.0, top 1137.37, 892.0 × 125.26 (ink 109.8 → 969.5, baseline 1246.8).

## How it is built (to rebuild it in Flutter)

Two layers, both drawn with the original paths:

* **World** = the wordmark's own coordinates (the inner `<g transform="translate(120 120)">` of the wordmark SVG). The B, "Hoard" and "ate"
  never move inside it. A camera maps it to the screen: `screen = anchor + (world − cam) × zoom × k`, where `k = screenWidth / 1080` and
  `anchor = (50 % width, anchorY / 2400 × height)`.
* **The m** flies in screen space (offsets from the anchor, in design px) until it lands at 1700 ms; from then on it is locked into the
  world (`(mEndW − cam) × zoom`), so it rides with the wordmark during the hand-off.

Zoom is interpolated in log space (`z0 · (z1 / z0)^p`) so the shrink feels even instead of slowing down at the end.

### Keyframes

All times in ms on the 3200 ms controller. `Cubic(x1, y1, x2, y2)` = Flutter `Cubic` = CSS `cubic-bezier()`.

| Step | Element | Property | From → To | Start | End | Flutter interval | Curve |
|---|---|---|---|---|---|---|---|
| 2 | m piece | colour | #FAF6EE → #F2B544 | 300 | 700 | `Interval(0.0937, 0.2187)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 2 | m piece | scale (anticipation) | ×1.000 → ×1.035 | 360 | 700 | `Interval(0.1125, 0.2187)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 3 | m piece | wind-up (anticipation) | x 0, rot 90° → x −10 px, rot 95° | 700 | 840 | `Interval(0.2187, 0.2625)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 3 | m piece | x (centre) | 584.2 − 10 px → 679.4 px | 840 | 1700 | `Interval(0.2625, 0.5312)` | `Cubic(0.45,0.0,0.25,1.0)` |
| 3 | m piece | y (centre), arc | 1200 → 1200 − 56·sin(π·p) (peaks 1144 mid-way) | 840 | 1700 | `Interval(0.2625, 0.5312)` | `Cubic(0.45,0.0,0.25,1.0)` (p = this progress) |
| 3 | m piece | rotation (clockwise +) | 95° → 0° (upright; turns 95° counter-clockwise) | 840 | 1700 | `Interval(0.2625, 0.5312)` | `Cubic(0.5,0.0,0.3,1.18)` — overshoots to ≈ −1.8° |
| 3 | m piece | scale (m-local → px) | 1.5254 × 1.035 → 0.5849 (= M size in wordmark) | 840 | 1700 | `Interval(0.2625, 0.5312)` | `Cubic(0.45,0.0,0.25,1.0)` |
| 3 | M | landing pop | ×1.00 → ×1.06 | 1700 | 1820 | `Interval(0.5312, 0.5687)` | `Cubic(0.0,0.0,0.2,1.0)` |
| 3 | M | landing settle | ×1.06 → ×1.00 | 1820 | 2040 | `Interval(0.5687, 0.6375)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 4 | B + world | zoom (camera) | 0.50776 → 0.13199 (log-space: z0·(z1/z0)^p) | 920 | 1700 | `Interval(0.2875, 0.5312)` | `Cubic(0.65,0.0,0.35,1.0)` |
| 4 | B + world | pan: world point at centre | (327.46, 354.50) → (3259, 354.5) = wordmark centre | 920 | 1700 | `Interval(0.2875, 0.5312)` | `Cubic(0.65,0.0,0.35,1.0)` |
| 4 | B | cream bowls draw-on (trim) | 0 % → 100 % (both bowls grow out of the stem) | 1240 | 1520 | `Interval(0.3875, 0.4750)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 4 | Hoard "H" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1380 | 1720 | `Interval(0.4312, 0.5375)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | Hoard "o" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1430 | 1770 | `Interval(0.4469, 0.5531)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | Hoard "a" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1480 | 1820 | `Interval(0.4625, 0.5687)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | Hoard "r" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1530 | 1870 | `Interval(0.4781, 0.5844)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | Hoard "d" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1580 | 1920 | `Interval(0.4937, 0.6000)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | ate "a" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1720 | 2060 | `Interval(0.5375, 0.6437)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | ate "t" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1770 | 2110 | `Interval(0.5531, 0.6594)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 4 | ate "e" | opacity / x slide | 0 / −120 world units (≈ −16 px) → 1 / 0 | 1820 | 2160 | `Interval(0.5687, 0.6750)` | `Cubic(0.2,0.0,0.0,1.0)` |
| 6 | background | colour | #2E6B4F → #FAF6EE | 2560 | 3160 | `Interval(0.8000, 0.9875)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 6 | B + Hoard | colour | #FAF6EE → #2E6B4F (2-frame flip at the bg midpoint) | 2758 | 2792 | `Interval(0.8620, 0.8724)` | linear |
| 6 | world (wordmark) | zoom | 0.13199 → 0.11838 (log-space) | 2560 | 3160 | `Interval(0.8000, 0.9875)` | `Cubic(0.4,0.0,0.2,1.0)` |
| 6 | world (wordmark) | centre y | 1200 px (50 %) → 660.17 px (27.5 %) | 2560 | 3160 | `Interval(0.8000, 0.9875)` | `Cubic(0.4,0.0,0.2,1.0)` |

Constants: B scale in wordmark 3.0042, M scale 4.4313, m pivot (118, 80) in m-local units, B centre in world (327.46, 354.50),
m start in world (414.58, 354.50), M end in world (4314.89, 354.50), z0 = 0.507764, z1 = 0.131992, z2 = 0.118378.

### Why the BHoard colour flips in two frames

If the background (green → cream) and the BHoard letters (cream → green) faded at the same rate, both would be the same colour at the
midpoint and "BHoard" would vanish for a moment. So the background fades over the full 600 ms, and BHoard swaps colour across two frames
centred on the background's halfway point. The letters never drop below ~26 % of full contrast and the swap reads as smooth.

### Choices worth knowing

* **The B's bowls redraw.** The yellow M *is* the B's m piece, so once it leaves the B is only a stem. The final wordmark needs a complete
  cream B, so its bowls draw back on along the same stroke (1240 – 1520 ms), timed for when the B is already small. Alternative if you prefer:
  keep the cream bowls in the B the whole time and let a yellow copy peel off (a small change; ask and it can be re-rendered).
* **Reduced motion.** The widget checks `MediaQuery.disableAnimations` and jumps straight to the final login layout.
* **Other aspect ratios.** Everything scales with screen width; vertical positions are fractions of the height (50 % → 27.5 %).
