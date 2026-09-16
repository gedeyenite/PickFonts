# Modern Font Picker

A fast, lightweight, native macOS font preview and selection utility written in SwiftUI.

Inspired by the classic legacy utility *Font Picker* (fontpicker.net), this project is a clean-room rewrite built from the ground up for modern macOS releases and Apple Silicon (ARM64) architecture.

## Features

- **Native Apple Silicon Support:** Runs natively on M-series chips with zero overhead.
- **Dynamic Font Browsing:** Renders real-time text previews using your installed system and user fonts.
- **Interactive Sizing & Previewing:** Instant text customization and size adjustments.
- **Quick Jump & Search:** A–Z fast-index navigation and instant substring filtering.
- **Font Culling:** Dismiss unwanted fonts from the view with a single click to narrow down your final selections.

## Building from Source

Requires macOS 14.0+ and Xcode Command Line Tools.

```bash
./build.sh
```

The script compiles the standalone `Font Picker.app` bundle ready to run.

## License

This project is licensed under the [MIT License](LICENSE).
