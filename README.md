# PickFonts

A fast, lightweight, native macOS font preview and selection utility written in SwiftUI.

PickFonts is a clean-room rewrite built from the ground up for modern macOS releases and Apple Silicon (ARM64) architecture, inspired by the utility concept of classic web and desktop font comparison tools.

## Features

- **Native Apple Silicon Support:** Runs natively on M-series chips with zero overhead.
- **Dynamic Font Browsing:** Renders real-time text previews using your installed system and user fonts.
- **Interactive Sizing & Previewing:** Instant text customization and size adjustments.
- **Quick Jump & Search:** A–Z fast-index navigation and instant substring filtering.
- **Favorites & Pinning:** Pin your favorite fonts to the top of the list, toggle a "Favorites Only" view, and copy your shortlisted font names. Favorites persist automatically across restarts.
- **Font List Files (`.flxml`):** Full backward compatibility with classic Font Picker `.flxml` files. Open, Save, and Save As your custom preview phrase and shortlisted fonts with `⌘O` / `⌘S`, or drag and drop files directly into the app.
- **Font Culling:** Dismiss unwanted fonts from the view with a single click to narrow down your final selections.

## Download

Pre-compiled Apple Silicon builds are available on the [Releases](https://github.com/gedeyenite/PickFonts/releases) page. Download the `.zip` archive, extract it, and move `PickFonts.app` to your `/Applications` folder.

## Building from Source

Requires macOS 14.0+ and Xcode Command Line Tools.

```bash
./build.sh
```

The script compiles the standalone `PickFonts.app` bundle ready to run.

## License

This project is licensed under the [MIT License](LICENSE).
