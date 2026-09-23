<div align="center">
  <p><img src=".assets/icon.avif" align="center" width="128"></p>
  <h1><code>MACHOGEN</code></h1>
</div>

<table>
  <tbody><tr><td align="center" width="99999"><div>
    <a href="https://olankens.com">WEBSITE</a> ·
    <a href="https://ko-fi.com/olankens">FUNDING</a>
  </div></td></tr></tbody>
  <tbody><tr><td align="center" width="99999">&nbsp;<div>
    Configure your macOS machine automatically with this highly opinionated post-installation script. Update and install all necessary development tools and apply strict defaults without manual intervention.
  </div>&nbsp;</td></tr></tbody>
  <tbody><tr><td align="center" width="99999">
    <a href="https://www.apple.com/os/macos"><img src=".assets/apple.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://brew.sh"><img src=".assets/homebrew.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://wikipedia.org/wiki/Bash_(Unix_shell)"><img src=".assets/bash.svg" align="center" width="56"></a>
  </td></tr></tbody>
</table>

## PREVIEWS

<table><tbody><tr><td width="99999">
  <img src=".assets/preview-01.avif" align="center" width="49.21875%"><picture><img src=".assets/spacer.gif" align="center" width="1.5625%"></picture><img src=".assets/preview-02.avif" align="center" width="49.21875%">
</td></tr></tbody></table>

## FEATURES

<table>
  <tbody><tr><td width="99999">Installs Homebrew through its official script, wires the brew shell environment into .zprofile, disables analytics, and accepts the Xcode license when xcodebuild is available. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs zsh-autosuggestions with a compinit loader sourced from the Homebrew prefix, appends it to .zshrc, and drops an .hushlogin file to silence the last login banner. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Renames the computer, host and NetBIOS name through scutil, forces the Europe/Brussels timezone with systemsetup, and silences the boot chime by setting StartupMute in nvram. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Rosetta 2 silently with softwareupdate for Apple Silicon compatibility and sweeps every .DS_Store file from the home directory to remove Finder leftovers. Ready from the very first shell.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Verifies the terminal holds Accessibility and Full Disk Access before starting, walking you through the System Settings dialogs and blocking until both grants are confirmed. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Temporarily disables system sleep with pmset while keeping the machine awake with caffeinate, and writes a NOPASSWD sudoers rule so the run never stalls on password prompts. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Turns on dark mode through System Events, disables the wallpaper window tint in System Settings, and applies dock defaults like autohide, bottom orientation, and no recents. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Rebuilds the dock with the curated app and folder set, downloads the java wallpaper from the devpaper repository, and rebrands every supported application with custom icns icons. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Ungoogled Chromium through Homebrew casks, dismisses the default-browser notification dialogs, and registers it as the system default with the defaultbrowser helper. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Configures Chromium through scripted keystrokes: the download folder, custom NTP page, disabled avatar and tab search, forced dark mode, and the extension handling flag. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs the chromium-web-store bridge plus uBlock Origin, Bitwarden, Simple Translate, SponsorBlock, JSON formatter and Bypass Paywalls Clean, refreshing them when outdated. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Git and GitHub CLI with the gh-stack extension, configures the identity from the authenticated account, and sets rebase pulls, auto setup remote, and a large post buffer. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs the Temurin JDK, the Node LTS release with pnpm, and Miniforge with conda initialized for zsh and base auto-activation disabled, plus PowerShell with telemetry off. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Android command-line tools, the full SDK with build tools, platforms, sources, system images and licenses, then creates a Pixel 7a emulator for the target API level. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Xcode through xcodes with license acceptance and first-launch setup, then adds Flutter with precached artifacts, disabled analytics, and accepted Android licenses. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Docker CLI, Colima, Buildx and Compose, boots the Colima VM once to finish setup, and registers the Homebrew CLI plugins directory in the Docker client configuration. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Figma with the menu bar icon disabled, Orca with a rebranded icon and resources, UTM, and Calibre with Goodreads, Kobo Metadata and resize cover plugins enabled. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs IntelliJ IDEA, Android Studio with the Islands Dark scheme, and Visual Studio Code, finishing first launches automatically and rebranding each app with a custom icon. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Applies the Islands Dark theme to JetBrains IDEs, installs JetBrains Mono as the editor font, and configures editor settings like format on save and active bracket pairs. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs dotenv, Error Lens and the spell checker extensions, then tunes VS Code settings from AI feature disabling to telemetry level, update mode, and workspace trust. Ready from the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Prepares the JavaScript and TypeScript stack with Biome, ESLint and Prettier, plus Angular CLI with devtools and Astro, alongside the shortest import specifier preset. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Sets up the Spring Boot toolchain with Initializr, dashboard and container extensions plus IDEA plugins, the KMM plugin pair, and the NestJS CLI with snippets and containers. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs ShellCheck and shfmt with the Bash IDE extension for shell scripts, and PowerShell with the IntelliJ plugin, telemetry opt-out, and update checks disabled. Ready from the very first shell.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Claude Code globally through npm, skips onboarding and co-authored trailers, raises the output token ceiling, and adds the Headroom context tool through uv. Ready from the very first shell.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs the Claude Code extension for VS Code and wires the claude-agent-acp bridge so JetBrains IDEs and other editors can manage the agent through the ACP protocol. Ready from the first shell.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Calibre rebranded and codesigned with the Goodreads, Kobo Metadata and resize cover plugins, plus Notion with auto-updater, menu bar and login items disabled. Ready from the first shell.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs JDownloader with banners, clipboard monitoring and donation dialogs disabled, and Transmission with a dedicated download folder, incomplete folder, and ratio limit. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs Keka with its external helper set as the default archive handler, plus Mole from the tw93 tap, covering extraction and cleanup needs without further configuration. Ready on the first run.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Installs KeepingYouAwake for display sleep control, and Nightlight with the color temperature set to sixty percent and an always-on schedule running from three until three. Ready on the first run.</td><td>✅</td></tr></tbody>
</table>

## LEARNING

### LAUNCH SCRIPT

```sh
/bin/zsh -c "$(curl -fsL https://github.com/olankens/machogen/releases/latest/download/machogen.sh)"
```

### IMPORT FUNCTIONS

```sh
source <(curl -fsL https://github.com/olankens/machogen/releases/latest/download/machogen.sh)
```
