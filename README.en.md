# Loadr

[Español](README.md) · **English**

[![Release](https://img.shields.io/github/v/release/stargazecas/Loadr?label=version)](https://github.com/stargazecas/Loadr/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
[![MIT License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A native macOS front end for [yt-dlp](https://github.com/yt-dlp/yt-dlp), written in SwiftUI.
Paste a URL, pick a quality and download. No Terminal needed.

---

## Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Quality and format options](#quality-and-format-options)
- [Playlists](#playlists)
- [Language](#language)
- [Automatic URL cleanup](#automatic-url-cleanup)
- [Where files are saved](#where-files-are-saved)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Building from source](#building-from-source)
- [Project layout](#project-layout)
- [Technical documentation](#technical-documentation)
- [Roadmap](#roadmap)
- [License](#license)

---

## Features

- Download videos by simply pasting the URL.
- Preview before downloading: title, thumbnail and duration.
- Quality picker: best quality, 1080p, 720p or audio only (MP3).
- Video format picker: automatic, MP4, MKV or WebM.
- Live progress with percentage, speed and time remaining.
- Download queue: up to 3 at once; the rest wait their turn.
- Cancel downloads, and retry failed or canceled ones with one click.
- Show the downloaded file in Finder.
- YouTube playlist support, with an option to save into their own folder.
- Tracking parameters are stripped from URLs automatically.
- English and Spanish interface, switchable instantly.
- Your quality, format and language choices are remembered between launches.

Loadr doesn't implement downloading itself: it hands everything to `yt-dlp` and `ffmpeg`.
That's why it works with any site `yt-dlp` supports.

---

## Installation

### 1. Install the dependencies

Loadr needs [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [ffmpeg](https://ffmpeg.org).
The easiest way to get them is [Homebrew](https://brew.sh):

```sh
brew install yt-dlp ffmpeg
```

Loadr looks for them in `/opt/homebrew/bin` (Apple silicon) and `/usr/local/bin` (Intel).
If you installed `yt-dlp` or `ffmpeg` another way and Loadr can't find them, see
[Troubleshooting](#troubleshooting).

### 2. Download the app

1. Go to the [Releases](https://github.com/stargazecas/Loadr/releases) page.
2. Download `Loadr-<version>-macOS.zip` from the latest release.
3. Unzip it and move `Loadr.app` to your **Applications** folder.

### 3. First launch (unsigned app)

Published builds **aren't signed or notarized by Apple**, so macOS blocks the app the first
time. To open it, use one of these two options:

**Option A: from System Settings**

1. Try to open `Loadr.app`. macOS shows a warning and blocks it.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the Security section and click **Open Anyway** next to the Loadr message.
4. Confirm with your password or Touch ID.

**Option B: from Terminal**

```sh
xattr -dr com.apple.quarantine /Applications/Loadr.app
```

You only need to do this once. If you'd rather not trust an unsigned binary, you can
[build it yourself](#building-from-source).

---

## Usage

### Downloading a video

1. Open Loadr.
2. Paste the video URL into the field at the top.
3. Choose the **quality** and **format** (see [options](#quality-and-format-options)).
4. Click **Download** or press **Return**.

Loadr adds the download to the list. It first shows "Fetching info…", then the thumbnail,
title and duration appear. Once downloading starts you'll see the percentage, speed and
time remaining.

> The **Download** button is only enabled when the text is a valid `http` or `https` URL.

### Downloading several videos

Paste another URL and click **Download** again without waiting for the previous one.
Loadr downloads up to **3 videos at once**; the rest are "Queued" and start in the order they
were added as slots free up. The most recent downloads appear at the top.

### Canceling and retrying

Click the **✕** on the right of a row to cancel it. The download is marked "Canceled".
If it had already started, a partial file (`.part`) may be left in the destination folder;
you can delete it by hand.

Canceled or failed downloads show a **↻** button. Click it to put them back in the queue.

### Viewing the downloaded file

When a download finishes, a folder icon appears. Click it to show the file in Finder.
If Loadr can't locate the file, it opens the `Downloads/Loadr` folder instead.

The **trash** button in the top bar removes completed downloads from the list (the files
stay on disk).

### Download states

| State | Meaning |
| --- | --- |
| Queued | Waiting for a slot: 3 downloads are already running. |
| Fetching info… | Loadr is reading the title, thumbnail and duration. |
| Percentage + speed + time remaining | Download in progress. |
| Completed | The file is ready. |
| Canceled | You canceled it. It can be retried. |
| Red message | The download failed. The message comes from `yt-dlp`. It can be retried. |

---

## Quality and format options

### Quality

| Option | What it does |
| --- | --- |
| **Best Quality** | The best video and audio combination available. |
| **1080p** | Up to 1080p tall. If the site doesn't offer that size, the best lower one is used. |
| **720p** | Same, capped at 720p. |
| **Audio Only (MP3)** | Downloads just the audio and converts it to MP3. |

### Video format

| Option | What it does |
| --- | --- |
| **Automatic** | `yt-dlp` picks the container based on the downloaded streams. |
| **MP4** | Forces an MP4 container. The most compatible with players and editors. |
| **MKV** | Matroska container. Accepts almost any codec combination. |
| **WebM** | WebM container. Works well with VP9/Opus streams; with other codecs it may not be possible. |

With **Audio Only (MP3)** the format picker is disabled, since the output is always MP3.

Your quality and format choices are saved and applied the next time you open the app.

> **ffmpeg** must be installed to merge video and audio. Without it, most best-quality
> downloads will fail.

---

## Playlists

If you paste a YouTube playlist URL (an address like `youtube.com/playlist?list=…`), Loadr
shows a dialog with the number of videos and asks where to save them:

- **Folder named after the playlist**: creates a subfolder inside `Downloads/Loadr`.
  The characters `/` and `:` in the title are replaced with `-`.
- **Main Folder**: saves everything straight into `Downloads/Loadr`.
- **Cancel**: downloads nothing.

Each video is then added to the list as its own download, with its thumbnail, duration and
the quality and format selected at that moment. Videos join the queue in playlist order and
download 3 at a time.

**Important:** only URLs that point to `/playlist` are treated as playlists. If you paste a
video URL that also contains `&list=…` (for example, a video opened from inside a playlist),
Loadr downloads **only that video**.

---

## Language

Loadr comes in English and Spanish. To switch, open **Loadr → Settings…** (⌘,) and choose:

- **System**: uses your macOS language if it's English or Spanish; otherwise English.
- **English** or **Español**: always use that language.

The window switches right away. The menu bar (File, Edit…) is drawn by macOS and picks up the
new language the next time you open Loadr.

---

## Automatic URL cleanup

Before downloading, Loadr strips tracking parameters from the URL you paste:

- **YouTube** (`youtube.com`, `youtu.be`, `youtube-nocookie.com`): keeps only what's needed
  (`v`, `t` and `list`; on `youtu.be`, only `t`) and drops the rest, such as `si` or `feature`.
- **Other sites**: removes `utm_*`, `si`, `igsh`, `fbclid`, `gclid`, `dclid`, `mc_cid` and `mc_eid`.

You don't have to do anything: it happens automatically and doesn't change which video is
downloaded.

---

## Where files are saved

```
~/Downloads/Loadr/
├── My video.mp4
├── Another video.mkv
└── Playlist name/
    ├── Video 1.mp4
    └── Video 2.mp4
```

Files are named after the video title (`%(title)s.%(ext)s`); if one with that name already
exists, `yt-dlp` doesn't download it again.
For now the destination folder can't be changed from the app.

---

## Troubleshooting

### The yellow "Missing tools" banner appears

Loadr can't find `yt-dlp` and/or `ffmpeg`.

1. Click **Copy Command** and paste it into Terminal:

   ```sh
   brew install yt-dlp ffmpeg
   ```

2. Go back to Loadr and click **Check Again**.

If you already have them installed, check where they are:

```sh
which yt-dlp ffmpeg
```

Loadr only looks in `/opt/homebrew/bin` and `/usr/local/bin` (or inside the app bundle).
If they live somewhere else, install them with Homebrew or create a symbolic link in one of
those folders.

### A download fails with "HTTP 403", "unable to extract" or similar

It's almost always an outdated `yt-dlp`: sites change often and `yt-dlp` ships fixes
frequently. Update it and click **↻** to retry:

```sh
brew upgrade yt-dlp
```

### Merging video and audio fails

Check that `ffmpeg` works:

```sh
ffmpeg -version
```

If it doesn't respond, reinstall it with `brew reinstall ffmpeg`. If the error only happens
with the **WebM** format, try **MKV** or **Automatic**.

### The video is private, requires sign-in or is age-restricted

Loadr doesn't handle accounts or cookies, so it can't download content that requires
signing in.

### macOS says the app "is damaged" or "can't be opened"

That's the normal block for unsigned apps. Follow the
[First launch](#3-first-launch-unsigned-app) steps.

### A failed download's error message is cut off

Loadr keeps the last lines `yt-dlp` printed and the row shows up to three of them. To see
the full error, run the same URL in Terminal with `yt-dlp <url>`.

### The menu bar is still in the old language

That's expected: quit Loadr (⌘Q) and open it again. See [Language](#language).

---

## FAQ

**Which sites are supported?**
Every site `yt-dlp` supports. See its
[list of supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).
Playlist detection, however, only works with YouTube.

**Does it work on Intel and Apple silicon?**
Yes, it looks for the tools in Homebrew's paths for both architectures.

**Can I download just the audio?**
Yes: choose **Audio Only (MP3)** in the quality picker.

**How many downloads run at once?**
Three. The rest wait in the queue and start as soon as one finishes.

**Can I use Loadr in Spanish?**
Yes, from **Settings** (⌘,). See [Language](#language).

**Can I change the destination folder?**
Not yet. It's on the [Roadmap](#roadmap).

**Does Loadr send my data anywhere?**
Loadr has no servers of its own and no telemetry. Requests are made by `yt-dlp` directly to
the source site, and the thumbnail is loaded from the URL that site provides.

---

## Building from source

### Requirements

- macOS 15 or later.
- Xcode 16 or later.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen):

  ```sh
  brew install xcodegen
  ```

- `yt-dlp` and `ffmpeg` to run the app (see [Installation](#1-install-the-dependencies)).

### Steps

```sh
git clone https://github.com/stargazecas/Loadr.git
cd Loadr
xcodegen
xcodebuild -scheme Loadr -configuration Debug build
```

You can also open `Loadr.xcodeproj` in Xcode and press **Run** (⌘R).

The project configuration lives in `project.yml`. If you change files or settings, run
`xcodegen` again to regenerate the `.xcodeproj`.

### Publishing a release

The GitHub Actions workflow (`.github/workflows/release.yml`) builds and publishes a release
automatically whenever a tag starting with `v` is pushed. The full steps (version bump,
changelog, tag) are in [docs/publicar-version.md](docs/publicar-version.md) (Spanish).

---

## Project layout

```
Loadr/
├── project.yml                     XcodeGen project definition
├── Config/Info.plist               Languages the app declares (en, es)
├── Sources/Loadr/
│   ├── LoadrApp.swift              Entry point: main window and Settings
│   ├── Localization/
│   │   ├── LanguageSettings.swift  Language preference and system language detection
│   │   └── L10n.swift              Every UI string, in English and Spanish
│   ├── Models/
│   │   ├── DownloadTask.swift      Model for a single download
│   │   └── DownloadManager.swift   Download queue, settings and playlist logic
│   ├── Services/
│   │   └── YTDLPService.swift      yt-dlp wrapper (processes, output parsing)
│   └── Views/
│       ├── ContentView.swift       Main window
│       ├── DownloadRowView.swift   One row per download
│       └── SettingsView.swift      Settings window
├── docs/                           Technical documentation (Spanish)
└── .github/workflows/release.yml   Builds and publishes a release when a v* tag is pushed
```

The app hands all downloading to the `yt-dlp` binary and parses its standard output to show
progress.

---

## Technical documentation

The in-depth guides are written in Spanish:

- [Architecture](docs/arquitectura.md): components, download lifecycle, how `yt-dlp` is called and how its output is parsed.
- [Languages](docs/idiomas.md): how language switching works and how to add or edit strings.
- [Releasing](docs/publicar-version.md): steps to ship a new version.
- [Changelog](CHANGELOG.md).

---

## Roadmap

- Configurable number of simultaneous downloads.
- Choose the destination folder.
- Download history.
- Automatic paste from the clipboard.

---

Loadr is a tool made solely for downloading. I'm not responsible for the kind of content you
choose to get with it, nor am I interested in it. Be free.

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
