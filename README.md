# <samp>OVERVIEW</samp>

<img src="assets/img1.png" width="49.25%"/><img src="assets/img0.png" width="1.5%"/><img src="assets/img2.png" width="49.25%"/>

Post-installation script to set up a whole developer-friendly environment on MacOS.
It installs, updates, and configures every single software on your machine automatically.
This is highly opinionated with harsh defaults and shouldn't be executed blindly.

It intentionally uses Ungoogled Chromium as the main browser and has advanced mechanisms to install official and unofficial extensions.
Yeah, the best extensions are not on the store and the best features are not available on official Chrome or shit-tier forks.
Ungoogled Chromium is also used for development purposes with a specific Developer profile.
This profile has to be used when debugging with your code editors and IDEs.

This script was tested on macOS Sonoma (14), Sequoia (15), and Tahoe (26).

# <samp>FEATURES</samp>

- Update System
- Update Android Studio
- Update Calibre
- Update Chromium (Ungoogled)
- Update Claude Code
- Update Docker
- Update Figma
- Update Fork
- Update Git
- Update GitHub CLI
- Update IINA
- Update IntelliJ IDEA Ultimate
- Update JDownloader
- Update Joal Desktop
- Update KeepingYouAwake
- Update Keka
- Update Miniforge
- Update Nightlight
- Update Node
- Update Notion
- Update PostgreSQL
- Update Temurin
- Update Transmission
- Update UTM
- Update Xcode
- Update Youtube Music
- Update Android DevTools
- Update Angular DevTools
- Update Apple DevTools
- Update Spring DevTools
- Update Appearance

# <samp>GUIDANCE</samp>

### Launch Script

You have to use ZSH to run this script.

```shell
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)"
```

### Import Functions

You can invoke specific functions.

```shell
source <(curl -fsSL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)
update_android_devtools
update_angular_devtools
```
