# ScreenShotMaker

A macOS app for creating, managing, and exporting App Store Connect screenshots with ease.

[日本語版はこちら](README.ja.md)

## Problem

Creating screenshots for App Store Connect is painful:

- Multiple device types require different screenshot sizes
- Supporting multiple languages multiplies the work
- Manual image editing for each combination is time-consuming and error-prone
- Re-creating screenshots for every app update is tedious

## Solution

ScreenShotMaker is a native macOS app that lets you visually design and export App Store screenshots. Save your work as a reusable project file, so updating screenshots for new releases takes minutes instead of hours.

## Features

### Device Support

Full support for all Apple platforms:

- iPhone (all display sizes from 3.5" to 6.9")
- iPad (all display sizes from 9.7" to 13")
- Mac (16:10 aspect ratio)
- Apple Watch (Series 3 through Ultra 3)
- Apple TV (1080p and 4K)
- Apple Vision Pro

### Multi-Language Support

- Manage screenshot sets for multiple languages
- Built-in translation feature for text using Apple Translation framework
- Per-language text customization

### Background Customization

- Solid color
- Gradient (linear, radial)
- Background image

### Screenshot Layout

Upload one screenshot image per screen and optionally add a text caption. Choose from layout presets:

| Preset | Description |
|---|---|
| Text Top | Text on top, screenshot on bottom |
| Text Overlay | Screenshot centered, text overlaid |
| Text Bottom | Screenshot on top, text on bottom |
| Text Only | Text only, no screenshot |
| Screenshot Only | Screenshot only, no text |

### Device Frame Mockups

Optionally wrap screenshots in realistic device frames (iPhone, iPad, Mac, Apple Watch, etc.) for a professional presentation.

### Batch Export

Export all screenshots for all device sizes and all languages at once in JPEG or PNG format, organized into folders by device and language.

### Auto Scaling

Design your screenshot layout once at the largest required size. ScreenShotMaker automatically generates properly scaled versions for all other device sizes.

### Template Gallery

Built-in layout templates for common screenshot styles to get started quickly.

### Project Files

Save your work as `.ssmaker` project files. Share projects with your team or reuse them across app updates.

## Screenshot Specifications

All sizes follow [Apple's official specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Format: JPEG or PNG, 1-10 screenshots per set.

### iPhone

| Display | Devices | Portrait | Landscape |
|---|---|---|---|
| 6.9" | iPhone Air, 17 Pro Max, 16 Pro Max, 16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max | 1260 x 2736 | 2736 x 1260 |
| 6.5" | iPhone 14 Plus, 13 Pro Max, 12 Pro Max, 11 Pro Max, 11, XS Max, XR | 1284 x 2778 | 2778 x 1284 |
| 6.3" | iPhone 17 Pro, 17, 16 Pro, 16, 15 Pro, 15, 14 Pro | 1179 x 2556 | 2556 x 1179 |
| 6.1" | iPhone 16e, 14, 13 Pro, 13, 12 Pro, 12, 11 Pro, XS, X | 1170 x 2532 | 2532 x 1170 |
| 5.5" | iPhone 8 Plus, 7 Plus, 6S Plus | 1242 x 2208 | 2208 x 1242 |
| 4.7" | iPhone SE (3rd/2nd), 8, 7, 6S | 750 x 1334 | 1334 x 750 |
| 4" | iPhone SE (1st), 5S, 5C, 5 | 640 x 1136 | 1136 x 640 |
| 3.5" | iPhone 4S, 4 | 640 x 960 | 960 x 640 |

### iPad

| Display | Devices | Portrait | Landscape |
|---|---|---|---|
| 13" | iPad Pro (M5-1st gen), iPad Air (M3, M2) | 2064 x 2752 | 2752 x 2064 |
| 12.9" | iPad Pro (2nd gen) | 2048 x 2732 | 2732 x 2048 |
| 11" | iPad Pro (M5-1st gen), Air (M3-4th), iPad (A16, 10th), mini (A17 Pro, 6th) | 1488 x 2266 | 2266 x 1488 |
| 10.5" | iPad Pro, iPad Air (3rd), iPad (9th-7th) | 1668 x 2224 | 2224 x 1668 |
| 9.7" | iPad Pro, iPad Air 1/2, iPad (6th-3rd), mini (5th-2nd) | 1536 x 2048 | 2048 x 1536 |

### Mac

| Aspect Ratio | Dimensions |
|---|---|
| 16:10 (min) | 1280 x 800 |
| 16:10 | 1440 x 900 |
| 16:10 | 2560 x 1600 |
| 16:10 (max) | 2880 x 1800 |

### Apple Watch

| Device | Dimensions |
|---|---|
| Ultra 3 | 422 x 514 |
| Ultra 2, Ultra | 410 x 502 |
| Series 11, 10 | 416 x 496 |
| Series 9, 8, 7 | 396 x 484 |
| Series 6, 5, 4, SE 3, SE | 368 x 448 |
| Series 3 | 312 x 390 |

### Apple TV

| Resolution | Dimensions |
|---|---|
| HD | 1920 x 1080 |
| 4K | 3840 x 2160 |

### Apple Vision Pro

| Resolution | Dimensions |
|---|---|
| Standard | 3840 x 2160 |

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Platform**: macOS 15.0+
- **Translation**: Apple Translation Framework

## Roadmap

- [ ] **Phase 1**: Core functionality - project management, image placement, text editing, single export
- [ ] **Phase 2**: Device frame mockups, template gallery
- [ ] **Phase 3**: Auto scaling, translation integration
- [ ] **Phase 4**: Batch export, advanced customization

## Build

```bash
# Clone the repository
git clone https://github.com/fromkk/ScreenShotMaker.git
cd ScreenShotMaker

# Open in Xcode
open ScreenShotMaker.xcodeproj
```

Requires Xcode 16.0+ and macOS 15.0+.

## License

MIT License. See [LICENSE](LICENSE) for details.
