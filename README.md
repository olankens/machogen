# <samp>OVERVIEW</samp>

<img src=".assets/before.png" width="49%"/><img src=".assets/1x1.png" width="2%"/><img src=".assets/after.png" width="49%"/>

Post-installation script to set up a whole developer-friendly environment on macOS.
It installs, updates, and configures every single software on your machine automatically.
This is highly opinionated with harsh defaults and shouldn't be executed blindly.

It intentionally uses Ungoogled Chromium as the main browser and has advanced mechanisms to install official and unofficial extensions.
Yeah, the best extensions are not on the store and the best features are not available on official Chrome or shit-tier forks.
Ungoogled Chromium is also used for development purposes with a specific Developer profile.
This profile has to be used when debugging with your code editors and IDEs.

# <samp>FEATURES</samp>

- Update System
- Update Android Studio
- Update Calibre
- Update Chromium (Ungoogled)
- Update Claude Code
- Update Cursor
- Update Docker
- Update Figma
- Update Flutter
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
- Update Pearcleaner
- Update PostgreSQL
- Update Temurin
- Update Transmission
- Update UTM
- Update Xcode
- Update Youtube Music
- Update Android DevTools
- Update Angular DevTools
- Update Apple DevTools
- Update Flutter DevTools
- Update Ionic DevTools
- Update React DevTools
- Update React Native DevTools
- Update Spring DevTools
- Update Appearance

# <samp>GUIDANCE</samp>

### Launch Script

You have to use ZSH to run this script.

```shell
/bin/zsh -c "$(curl -fsL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)"
```

### Import Functions

You can invoke specific functions.

```shell
source <(curl -fsL https://raw.githubusercontent.com/olankens/machogen/HEAD/src/machogen.sh)
update_android_devtools
update_angular_devtools
```
