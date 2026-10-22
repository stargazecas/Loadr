# Loadr

[Español](README.md) · **English**

[![Release](https://img.shields.io/github/v/release/stargazecas/Loadr?label=version)](https://github.com/stargazecas/Loadr/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)

A native macOS front end for [yt-dlp](https://github.com/yt-dlp/yt-dlp), written in SwiftUI.
Paste a video URL, pick a quality and format, and Loadr runs yt-dlp, shows the progress and saves
the file to `~/Downloads/Loadr`.

Loadr doesn't download anything by itself: it is a visual layer over `yt-dlp` and `ffmpeg`, so it
works with any site yt-dlp supports.

> Only download content you have the right to download, and respect each site's terms of use.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Building from source](#building-from-source)
- [Project layout](#project-layout)
- [Technical documentation](#technical-documentation)
- [Roadmap](#roadmap)

## Features

- **Quality:** best available, up to 1080p, up to 720p, or audio only (MP3).
- **Container format:** automatic, MP4, MKV or WebM.
- **Download queue:** up to 3 downloads at once; the rest wait in line and run in order.
- **Live progress:** percentage, speed and time remaining.
- **YouTube playlists:** download every video into a folder named after the playlist, or into the main folder.
- **Readable errors:** when something fails you see yt-dlp's last output lines and can retry.
- **Clean URLs:** tracking parameters (`utm_*`, `si`, `fbclid`, …) are stripped before downloading.
- **English and Spanish:** switch the interface language instantly from Settings.
- **Remembered settings:** quality, format and language persist between launches.

## Requirements

| Requirement | Version |
| --- | --- |
| macOS | 15 Sequoia or later (Apple silicon or Intel) |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Recent; YouTube changes often and old versions stop working |
| [ffmpeg](https://ffmpeg.org) | Any; used to merge video + audio and to convert to MP3 |

Install both with [Homebrew](https://brew.sh):

```sh
brew install yt-dlp ffmpeg
```

Loadr looks for them in `/opt/homebrew/bin` (Apple silicon), `/usr/local/bin` (Intel) and inside the
app bundle. If either is missing, the window shows a banner with a button that copies the install
command.

## Installation

1. Download `Loadr-x.y.z-macOS.zip` from [Releases](https://github.com/stargazecas/Loadr/releases/latest).
2. Unzip it and move `Loadr.app` to your **Applications** folder.
3. Install `yt-dlp` and `ffmpeg` if you don't have them yet (see [Requirements](#requirements)).

### First launch (Gatekeeper)

Loadr isn't signed with an Apple Developer certificate or notarized yet, so macOS blocks it the
first time. Since macOS 15, Control-click → Open no longer works; you approve the app in System
Settings instead:

1. Open `Loadr.app`. macOS shows a warning that it couldn't verify the app; dismiss it without moving the app to the Trash.
2. Go to **System Settings → Privacy & Security** and scroll down to the **Security** section.
3. Next to the message about Loadr, click **Open Anyway** and confirm with your password or Touch ID.

You only need to do this once. If macOS says the app "is damaged", remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/Loadr.app
```

## Usage

### Downloading a video

1. Copy the video URL and paste it into the text field.
2. Choose a **Quality** and **Format** (both are remembered for next time).
3. Click **Download** or press Return.

Each download shows up in the list with its thumbnail, duration and status:

| Status | Meaning |
| --- | --- |
| Queued | Waiting for a free slot (3 downloads are already running). |
| Fetching info… | yt-dlp is reading the title, thumbnail and duration. |
| 42.0% | Downloading; speed and time remaining are on the right. |
| Completed | Done. The folder button shows the file in Finder. |
| Canceled / error | Can be retried with the ↻ button. |

The trash button in the top bar removes completed downloads from the list (the files stay on disk).

### Quality and format

| Option | What it asks yt-dlp for |
| --- | --- |
| Best Quality | The best video + best audio available (`bv*+ba/b`). |
| 1080p / 720p | The best video **up to** that height, plus the best audio. |
| Audio Only (MP3) | Just the audio track, converted to MP3 with ffmpeg. |

**Format** sets the container of the final file when yt-dlp merges video and audio. *Automatic*
lets yt-dlp decide; MP4 is the most compatible with QuickTime and Photos. With *Audio Only* the
format picker is disabled, since the result is always MP3.

### Playlists

Paste the playlist link (`https://www.youtube.com/playlist?list=…`). Loadr lists its videos and asks
where to save them:

- **Folder "Playlist name"**: creates a subfolder inside `~/Downloads/Loadr`.
- **Main Folder**: saves them straight into `~/Downloads/Loadr`.

Videos join the queue in playlist order. A video link that contains `&list=…` downloads only that
video.

### Language

Open **Loadr → Settings…** (⌘,) and pick a language:

- **System**: uses your macOS language if it's English or Spanish; otherwise English.
- **English** or **Español**: always use that language.

The window switches right away. The menu bar (File, Edit, …) is drawn by macOS and picks up the new
language the next time you open Loadr.

### Where files are saved

In `~/Downloads/Loadr`. The file name is the video title. If a file with that name already exists,
yt-dlp doesn't download it again.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Missing tools" banner | Run `brew install yt-dlp ffmpeg` and click **Check Again**. Loadr only looks in Homebrew's paths; if you installed yt-dlp another way (pip, MacPorts…), install it with Homebrew. |
| A YouTube download that used to work now fails | Almost always an outdated yt-dlp: `brew upgrade yt-dlp`. |
| The error message is yt-dlp's raw output | That's intentional, so no detail is lost. |
| The video downloads without audio, or as two files | ffmpeg is missing or not in the paths Loadr checks. Check with `which ffmpeg`. |
| macOS won't open the app | Follow [First launch](#first-launch-gatekeeper). |
| The menu bar is still in the old language | Expected: quit Loadr (⌘Q) and open it again. |

## Building from source

You need Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen). The Xcode project
is generated from `project.yml`.

```sh
brew install xcodegen
git clone https://github.com/stargazecas/Loadr.git
cd Loadr
xcodegen
open Loadr.xcodeproj          # then press Run (⌘R)
```

Or from the terminal:

```sh
xcodebuild -scheme Loadr -configuration Debug build
```

Whenever you add, move or delete files, run `xcodegen` again to refresh `Loadr.xcodeproj`.

## Project layout

```
Loadr/
├── project.yml                     XcodeGen project definition
├── Config/Info.plist               Extra Info.plist keys (supported languages)
├── Sources/Loadr/
│   ├── LoadrApp.swift              Entry point: main window and Settings
│   ├── Localization/
│   │   ├── LanguageSettings.swift  Language preference and system language detection
│   │   └── L10n.swift              Every UI string, in English and Spanish
│   ├── Models/
│   │   ├── DownloadManager.swift   Queue, playlists, URL cleanup, output folder
│   │   └── DownloadTask.swift      Observable state of a single download
│   ├── Services/
│   │   └── YTDLPService.swift      Runs yt-dlp and turns its output into events
│   └── Views/
│       ├── ContentView.swift       Main window
│       ├── DownloadRowView.swift   One row per download
│       └── SettingsView.swift      Settings window
├── docs/                           Technical documentation (Spanish)
└── .github/workflows/release.yml   Builds and publishes a release when a v* tag is pushed
```

## Technical documentation

The in-depth guides are written in Spanish:

- [Architecture](docs/arquitectura.md): components, download lifecycle, how yt-dlp is called and how its output is parsed.
- [Languages](docs/idiomas.md): how language switching works and how to add or edit strings.
- [Releasing](docs/publicar-version.md): steps to ship a new version.
- [Changelog](CHANGELOG.md).

## Roadmap

- Choose the output folder.
- Progress via `--progress-template` instead of parsing yt-dlp's text output.
- Developer ID signing and notarization.
- Download history.
- Automatic paste from the clipboard.
- Android port.

## License

To be decided.
