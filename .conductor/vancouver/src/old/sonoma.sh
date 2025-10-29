#!/bin/zsh

# shellcheck shell=bash

#region SECURITY

assert_apple_id() {

	# Handle parameters
	local appmail=$(security find-generic-password -a $USER -s appmail -w 2>/dev/null)
	local apppass=$(security find-generic-password -a $USER -s apppass -w 2>/dev/null)

	printf "\r\033[93m%s\033[00m" "CHECKING APPLE CREDENTIALS, PLEASE BE PATIENT"
	brew install xcodesorg/made/xcodes &>/dev/null

	correct() {
		[[ -z "$appmail" || -z "$apppass" ]] && return 1
		export XCODES_USERNAME="$appmail"
		export XCODES_PASSWORD="$apppass"
		expect <<-EOD
			log_user 0
			set timeout 8
			spawn xcodes install --latest
			expect {
				-re {.*(A|a)pple ID.*} { exit 1 }
				-re {.*(E|e)rror.*} { exit 1 }
				-re {.*(L|l)ocked.*} { exit 1 }
				-re {.*(P|p)assword.*} { exit 1 }
				timeout { exit 0 }
			}
		EOD
	}

	if ! correct; then
		security delete-generic-password -s appmail &>/dev/null
		security delete-generic-password -s apppass &>/dev/null
		printf "\r\033[91m%s\033[00m\n\n" "APPLE CREDENTIALS NOT IN KEYCHAIN OR INCORRECT"
		printf "\r\033[92m%s\033[00m\n" "security add-generic-password -a \$USER -s appmail -w username"
		printf "\r\033[92m%s\033[00m\n\n" "security add-generic-password -a \$USER -s apppass -w password"
		return 1
	fi

	return 0

}

assert_executor() {

	# Handle parameters
	local is_root=$([[ $EUID = 0 ]] && echo "true" || echo "false")

	if [[ "$is_root" == "true" ]]; then
		printf "\r\033[91m%s\033[00m\n\n" "EXECUTING THIS SCRIPT AS ROOT IS NOT ADMITTED"
		return 1
	fi

	return 0

}

assert_password() {

	# Handle parameters
	local account=$(security find-generic-password -a $USER -s account -w 2>/dev/null)
	local correct=$(sudo -k ; echo "$account" | sudo -S -v &>/dev/null && echo "true" || echo "false")

	if [[ "$correct" == "false" ]]; then
		security delete-generic-password -s account &>/dev/null
		printf "\r\033[91m%s\033[00m\n\n" "ACCOUNT PASSWORD NOT IN KEYCHAIN OR INCORRECT"
		printf "\r\033[92m%s\033[00m\n\n" "security add-generic-password -a \$USER -s account -w password"
		return 1
	fi

	return 0

}

handle_security() {

	# Verify version
	if [[ ${"$(sw_vers -productVersion)":0:2} != "14" ]]; then
		printf "\r\033[91m%s\033[00m\n\n" "CURRENT MACOS VERSION (${"$(sw_vers -productVersion)":0:4}) IS NOT SUPPORTED"
		return 1
	fi

	# Output message
	printf "\r\033[93m%s\033[00m" "CHANGING SECURITY, PLEASE FOLLOW THE MESSAGES"

	# Handle functions
	allowed() { osascript -e 'tell application "System Events" to log ""' &>/dev/null }
	capable() { osascript -e 'tell application "System Events" to key code 60' &>/dev/null }
	granted() { ls "$HOME/Library/Messages" &>/dev/null }
	display() {
		heading=$(basename "$ZSH_ARGZERO" | cut -d . -f 1)
		osascript <<-EOD &>/dev/null
			tell application "${TERM_PROGRAM//Apple_/}"
				display alert "$heading" message "$1" as informational giving up after 10
			end tell
		EOD
	}

	while ! allowed; do
		display "You have to tap the OK button to continue."
		tccutil reset AppleEvents &>/dev/null
	done

	while ! capable; do
		display "You have to add your current terminal application to accessibility. When it's done, close the System Settings application to continue."
		open -W "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
	done

	while ! granted; do
		display "You have to add your current terminal application to full disk access. When it's done, close the System Settings application to continue."
		open -W "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
	done

}

#endregion

#region SERVICES

change_default_browser() {

	# Handle parameters
	local browser=${1:-safari}

	# Update dependencies
	brew install defaultbrowser

	# Change browser
	local factors=(brave chrome chromium firefox safari vivaldi)
	[[ ${factors[*]} =~ $browser ]] || return 1
	defaultbrowser "$browser" && osascript <<-EOD
		tell application "System Events"
			try
				tell application process "CoreServicesUIAgent"
					tell window 1
						tell (first button whose name starts with "use") to perform action "AXPress"
					end tell
				end tell
			end try
		end tell
	EOD

}

change_dock_items() {

	# Handle parameters
	local factors=("${@}")

	# Remove everything
	defaults write com.apple.dock persistent-apps -array

	# Append items
	for element in "${factors[@]}"; do
		[[ "$element" == "" ]] && defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'
		if [[ -d "$element" ]]; then
			local content="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$element"
			local content="$content</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
			defaults write com.apple.dock persistent-apps -array-add "$content"
		fi
	done

}

expand_archive() {

	# Handle parameters
	local archive=${1}
	local deposit=${2:-.}
	local subtree=${3:-0}

	# Expand archive
	if [[ -n $archive && ! -f $deposit && $subtree =~ ^[0-9]+$ ]]; then
		mkdir -p "$deposit"
		if [[ $archive = http* ]]; then
			curl -L "$archive" | tar -zxf - -C "$deposit" --strip-components=$((subtree))
		else
			tar -zxf "$archive" -C "$deposit" --strip-components=$((subtree))
		fi
		printf "%s" "$deposit"
	fi

}

expand_pattern() {

	# Handle parameters
	local pattern=${1}
	local expanse=${2:-0}

	# Expand pattern
	echo "$(/bin/zsh -c "find $pattern -maxdepth $expanse" 2>/dev/null | sort -r | head -1)" || sudo !!

}

expand_version() {

	# Handle parameters
	local payload=${1}
	local default=${2:-0.0.0.0}

	# Update dependencies
	brew install grep
	brew upgrade grep

	# Expand version
	local starter=$(expand_pattern "$payload/*ontents/*nfo.plist")
	local version=$(defaults read "$starter" CFBundleShortVersionString 2>/dev/null)
	echo "$version" | ggrep -oP "[\d.]+" || echo "$default"

}

update_chromium_extension() {

	# Handle parameters
	local payload=${1}

	# Update extension
	if [[ -d "/Applications/Chromium.app" ]]; then
		if [[ ${payload:0:4} == "http" ]]; then
			local address="$payload"
			local package=$(mktemp -d)/$(basename "$address")
		else
			local version=$(defaults read "/Applications/Chromium.app/Contents/Info" CFBundleShortVersionString)
			local address="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
			local address="${address}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
			local package=$(mktemp -d)/${payload}.crx
		fi
		curl -LA "mozilla/5.0" "$address" -o "$package" || return 1
		defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
		if [[ $package = *.zip ]]; then
			local storage="/Applications/Chromium.app/Unpacked/$(echo "$payload" | cut -d / -f5)"
			local present=$([[ -d "$storage" ]] && echo "true" || echo "false")
			expand_archive "$package" "$storage" 1
			if [[ "$present" == "false" ]]; then
				osascript <<-EOD
					set checkup to "/Applications/Chromium.app"
					tell application checkup
						activate
						reopen
						delay 4
						open location "chrome://extensions/"
						delay 2
						tell application "System Events"
							key code 48
							delay 2
							key code 49
							delay 2
							key code 48
							delay 2
							key code 49
							delay 2
							key code 5 using {command down, shift down}
							delay 2
							keystroke "$storage"
							delay 2
							key code 36
							delay 2
							key code 36
						end tell
						delay 2
						quit
						delay 2
					end tell
					tell application checkup
						activate
						reopen
						delay 4
						open location "chrome://extensions/"
						delay 2
						tell application "System Events"
							key code 48
							delay 2
							key code 49
						end tell
						delay 2
						quit
						delay 2
					end tell
				EOD
			fi
		else
			osascript <<-EOD
				set checkup to "/Applications/Chromium.app"
				tell application checkup
					activate
					reopen
					delay 4
					open location "file:///$package"
					delay 4
					tell application "System Events"
						key code 125
						delay 2
						key code 49
					end tell
					delay 6
					quit
					delay 2
				end tell
			EOD
		fi
	fi

}

#endregion

#region UPDATERS

update_android_cmdline() {

	# Update dependencies
	brew install curl fileicon grep
	brew upgrade curl fileicon grep
	brew install --cask --no-quarantine temurin
	brew upgrade --cask --no-quarantine temurin

	# Update package
	local sdkroot="$HOME/Library/Android/sdk"
	local deposit="$sdkroot/cmdline-tools"
	if [[ ! -d $deposit ]]; then
		mkdir -p "$deposit"
		local website="https://developer.android.com/studio#command-tools"
		local version="$(curl -s "$website" | ggrep -oP "commandlinetools-mac-\K(\d+)" | head -1)"
		local address="https://dl.google.com/android/repository/commandlinetools-mac-${version}_latest.zip"
		local archive="$(mktemp -d)/$(basename "$address")"
		curl -L "$address" -o "$archive"
		expand_archive "$archive" "$deposit"
		yes | "$deposit/cmdline-tools/bin/sdkmanager" --sdk_root="$sdkroot" "cmdline-tools;latest"
		rm -rf "$deposit/cmdline-tools"
	fi

	# Change environment
	local configs="$HOME/.zshrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/.android/sdk"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

}

update_android_studio() {

	# Update dependencies
	brew install fileicon grep xmlstarlet
	brew upgrade fileicon grep xmlstarlet

	# Update package
	local starter="/Applications/Android Studio.app"
	local present=$([[ -d "$starter" ]] && echo true || echo false)
	brew install --cask --no-quarantine android-studio
	brew upgrade --cask --no-quarantine android-studio

	# Launch it once
	if [[ "$present" == "false" ]]; then
		osascript <<-EOD
			set checkup to "/Applications/Android Studio.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					tell process "Android Studio"
						with timeout of 30 seconds
							repeat until (exists window 1)
								delay 1
							end repeat
						end timeout
					end tell
				end tell
				delay 4
				quit app "Android Studio"
				delay 4
			end tell
		EOD
		pkill -9 -f 'Android Studio'
	fi

	# Finish installation
	if [[ "$present" == "false" ]]; then
		update_android_cmdline
		yes | sdkmanager "build-tools;34.0.0"
		yes | sdkmanager "emulator"
		yes | sdkmanager "platform-tools"
		yes | sdkmanager "platforms;android-34"
		yes | sdkmanager "sources;android-34"
		yes | sdkmanager "system-images;android-34;google_apis;arm64-v8a"
		yes | sdkmanager --licenses
		yes | sdkmanager --update
		avdmanager create avd -n "Pixel_3a_API_34" -d "pixel_3a" -k "system-images;android-34;google_apis;arm64-v8a" -f
	fi

	# Update plugins
	studio installPlugins com.github.airsaid.androidlocalize

}

update_appearance() {

	# Update dependencies
	brew install curl imagemagick
	brew upgrade curl imagemagick

	# Change dock items
	local members=(
		# Internet
		"/Applications/Chromium.app"
		"/Applications/JDownloader 2/JDownloader2.app"
		"/Applications/Transmission.app"
		# Social
		"/Applications/Discord.app"
		# Productivity
		"/Applications/Notion.app"
		"/Applications/KeePassXC.app"
		# Development
		"/Applications/UTM.app"
		"/Applications/IntelliJ IDEA.app"
		"/Applications/DataGrip.app"
		"/Applications/Xcode.app"
		"/Applications/Android Studio.app"
		"/Applications/Visual Studio Code.app"
		"/Applications/StarUML.app"
		"/Applications/Fork.app"
		# Graphics
		"/Applications/Figma.app"
		# Multimedia
		"/Applications/YouTube Music.app"
		"/Applications/IINA.app"
		# "/Applications/Mpv.app"
		"/Applications/OBS.app"
		# Gaming
		"/Applications/Whisky.app"
		# System
		"/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
		"/System/Applications/Utilities/Terminal.app"
	)
	change_dock_items "${members[@]}"

	# Change dock settings
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0
	defaults write com.apple.dock autohide-time-modifier -float 0.25
	defaults write com.apple.dock minimize-to-application -bool true
	defaults write com.apple.dock orientation bottom
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.Dock size-immutable -bool yes
	defaults write com.apple.dock tilesize -int 38
	defaults write com.apple.dock wvous-bl-corner -int 0
	defaults write com.apple.dock wvous-br-corner -int 0
	defaults write com.apple.dock wvous-tl-corner -int 0
	defaults write com.apple.dock wvous-tr-corner -int 0
	killall Dock

	# Change wallpaper
	local address="https://raw.githubusercontent.com/olankens/andpaper/HEAD/src/android-bottom-darker.svg"
	local fetched="$(mktemp -d)/$(basename "$address")"
	local xfactor="$(system_profiler SPDisplaysDataType | grep Resolution | awk -F'[^0-9,]+' '{ print $2 }')"
	local yfactor="$(system_profiler SPDisplaysDataType | grep Resolution | awk -F'[^0-9,]+' '{ print $3 }')"
	mkdir -p "$(dirname $fetched)" && curl -L "$address" -o "$fetched"
	local picture="$HOME/Pictures/Backgrounds/$(basename "$fetched" ".svg").png"
	magick "$fetched" -scale "x$((yfactor*2))" -gravity southeast -crop "$((xfactor*2))x$((yfactor*2))+0+0" "$picture"
	osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$picture\""

}

update_awscli() {
	
	# Update package
	brew install awscli
	brew upgrade awscli

}

update_chromium() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local pattern=${2:-duckduckgo}
	local tabpage=${3:-about:blank}

	# Update dependencies
	brew install jq
	brew upgrade jq

	# Update package
	local starter="/Applications/Chromium.app"
	local present=$([[ -d "$starter" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine eloston-chromium
	brew upgrade --cask --no-quarantine eloston-chromium
	killall Chromium || true

	# Change default browser
	change_default_browser "chromium"

	# Finish installation
	if [[ "$present" == "false" ]]; then

		# Change language
		defaults write org.chromium.Chromium AppleLanguages "(en-US)"

		# Handle notification
		open -a "/Applications/Chromium.app"
		osascript <<-EOD
			if running of application "Chromium" then tell application "Chromium" to quit
			do shell script "/usr/bin/osascript -e 'tell application \"Chromium\" to do shell script \"\"' &>/dev/null &"
			repeat 5 times
				try
					tell application "System Events"
						tell application process "UserNotificationCenter"
							click button 3 of window 1
						end tell
					end tell
				end try
				delay 1
			end repeat
			if running of application "Chromium" then tell application "Chromium" to quit
			delay 4
		EOD
		killall "Chromium" && sleep 4

		# Change deposit
		mkdir -p "$deposit" && osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://settings/"
				delay 2
				tell application "System Events"
					keystroke "before downloading"
					delay 4
					repeat 3 times
						key code 48
					end repeat
					delay 2
					key code 36
					delay 4
					key code 5 using {command down, shift down}
					delay 4
					keystroke "${deposit}"
					delay 2
					key code 36
					delay 2
					key code 36
					delay 2
					key code 48
					key code 36
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change engine
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://settings/"
				delay 2
				tell application "System Events"
					keystroke "search engines"
					delay 2
					repeat 4 times
						key code 48
					end repeat
					delay 2
					key code 49
					delay 2
					keystroke "${pattern}"
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change custom-ntp
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "custom-ntp"
					delay 2
					repeat 5 times
						key code 48
					end repeat
					delay 2
					keystroke "a" using {command down}
					delay 1
					keystroke "${tabpage}"
					delay 2
					key code 48
					delay 2
					key code 49
					delay 2
					key code 125
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change extension-mime-request-handling
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "extension-mime-request-handling"
					delay 2
					repeat 5 times
						key code 48
					end repeat
					delay 2
					key code 49
					delay 2
					key code 125
					key code 125
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change hide-sidepanel-button
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "hide-sidepanel-button"
					delay 2
					repeat 5 times
						key code 48
					end repeat
					delay 2
					key code 49
					delay 2
					key code 125
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change remove-tabsearch-button
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "remove-tabsearch-button"
					delay 2
					repeat 4 times
						key code 48
					end repeat
					delay 2
					key code 49
					delay 2
					key code 125
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Change show-avatar-button
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "show-avatar-button"
					delay 2
					repeat 5 times
						key code 48
					end repeat
					delay 2
					key code 49
					delay 2
					key code 125
					key code 125
					key code 125
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Remove bookmark bar
		osascript <<-EOD
			set checkup to "/Applications/Chromium.app"
			tell application checkup
				activate
				reopen
				delay 4
				open location "about:blank"
				delay 2
				tell application "System Events"
					keystroke "b" using {shift down, command down}
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD

		# Revert language
		defaults delete org.chromium.Chromium AppleLanguages

		# Update chromium-web-store
		website="https://api.github.com/repos/NeverDecaf/chromium-web-store/releases"
		version=$(curl -s "$website" | jq -r ".[0].tag_name" | tr -d "v")
		address="https://github.com/NeverDecaf/chromium-web-store/releases/download/v$version/Chromium.Web.Store.crx"
		update_chromium_extension "$address"

		# Update extensions
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "lkahpjghmdhpiojknppmlenngmpkkfma" # skip-ad-ad-block-auto-ad
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "nngceckbapebfimnlniiiahkandclblb" # bitwarden-password-manage

	fi

	# TODO: Handle blocking password prompt properly.
	if [[ "$present" == "true" ]]; then return 0; fi

	# Update bypass-paywalls-chrome-clean
	update_chromium_extension "https://github.com/bpc-clone/bpc_updates/releases/download/latest/bypass-paywalls-chrome-clean-master.zip"

}

update_datagrip() {

	# Update package
	brew install --cask --no-quarantine datagrip
	brew upgrade --cask --no-quarantine datagrip

}

update_discord() {

	# Update package
	brew install --cask --no-quarantine discord
	brew upgrade --cask --no-quarantine discord

}

update_docker() {

	# Update dependencies
	brew install colima docker-compose jq sponge
	brew upgrade colima docker-compose jq sponge

	# Update package
	brew install docker
	brew upgrade docker

	# Launch background service
	colima start

	# Change settings
	local configs="$HOME/.docker/config.json"
	jq '. + {cliPluginsExtraDirs: ["/opt/homebrew/lib/docker/cli-plugins"]}' "$configs" | sponge "$configs"

}

update_flutter() {

	# Update dependencies
	brew install dart
	brew upgrade dart

	# Update package
	brew install --cask --no-quarantine flutter
	brew upgrade --cask --no-quarantine flutter

	# Finish installation
	flutter precache && flutter upgrade
	dart --disable-analytics
	flutter config --no-analytics
	yes | flutter doctor --android-licenses

	# Change environment
	local altered="$(grep -q "CHROME_EXECUTABLE" "$HOME/.zshrc" >/dev/null 2>&1 && echo "true" || echo "false")"
	local present="$([[ -d "/Applications/Chromium.app" ]] && echo "true" || echo "false")"
	if [[ "$altered" == "false" && "$present" == "true" ]]; then
		[[ -s "$HOME/.zshrc" ]] || echo '#!/bin/zsh' >"$HOME/.zshrc"
		[[ -z $(tail -1 "$HOME/.zshrc") ]] || echo "" >>"$HOME/.zshrc"
		echo 'export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"' >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

	# Update android-studio plugins
	studio installPlugins Dart
	studio installPlugins io.flutter
	studio installPlugins com.localizely.flutter-intl
	studio installPlugins org.tbm98.flutter-riverpod-snippets

	# Update vscode extensions
	code --install-extension "alexisvt.flutter-snippets" --force
	code --install-extension "dart-code.flutter" --force
	code --install-extension "pflannery.vscode-versionlens" --force
	code --install-extension "RichardCoutts.mvvm-plus" --force
	code --install-extension "robert-brunhage.flutter-riverpod-snippets" --force
	code --install-extension "usernamehw.errorlens" --force

	# TODO: Add `readlink -f $(which flutter)` to android-studio
	# NOTE: /usr/local/Caskroom/flutter/*/flutter

}

update_figma() {

	# Update dependencies
	brew install curl fileicon jq sponge
	brew upgrade curl fileicon jq sponge

	# Update package
	brew install --cask --no-quarantine figma
	brew upgrade --cask --no-quarantine figma

	# Change settings
	local configs="$HOME/Library/Application Support/Figma/settings.json"
	jq '.showFigmaInMenuBar = false' "$configs" | sponge "$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/figma.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Figma.app" "$picture" || sudo !!

}

update_fork() {

	# Update package
	brew install --cask --no-quarantine fork
	brew upgrade --cask --no-quarantine fork

}

update_git() {

	# Handle parameters
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	# Update package
	brew install git
	brew upgrade git

	# Change settings
	git config --global checkout.workers 0
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global push.autoSetupRemote true
	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail" || true
	[[ -n "$gituser" ]] && git config --global user.name "$gituser" || true

}

update_github_cli() {

	# Update package
	brew install gh
	brew upgrade gh

}

update_homebrew() {

	# Update package
	printf "\r\033[93m%s\033[00m" "UPGRADING HOMEBREW PACKAGE, PLEASE BE PATIENT"
	local command=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
	CI=1 /bin/bash -c "$command" &>/dev/null

	# Change environment
	local configs="$HOME/.zprofile"
	if ! grep -q "/opt/homebrew/bin/brew shellenv" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$configs"
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi

	# Vanish cache
	brew cleanup &>/dev/null

}

update_iina() {

	# Update dependencies
	brew install curl fileicon
	brew upgrade curl fileicon

	# Update package
	local present=$([[ -d "/Applications/IINA.app" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine iina
	brew upgrade --cask --no-quarantine iina

	# Finish installation
	if [[ "$present" == "false" ]]; then
		osascript <<-EOD
			set checkup to "/Applications/IINA.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					with timeout of 10 seconds
						repeat until (exists window 1 of application process "IINA")
							delay 0.02
						end repeat
						tell application process "IINA" to set visible to false
					end timeout
				end tell
				delay 4
				quit
				delay 4
			end tell
		EOD
		update_chromium_extension "pdnojahnhpgmdhjdhgphgdcecehkbhfo"
	fi

	# Change settings
	defaults write com.colliderli.iina recordPlaybackHistory -integer 0
	defaults write com.colliderli.iina recordRecentFiles -integer 0
	defaults write com.colliderli.iina SUEnableAutomaticChecks -integer 0
	defaults write com.colliderli.iina ytdlSearchPath "/usr/local/bin"

	# Change association
	local address="https://api.github.com/repos/jdek/openwith/releases/latest"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
	local address="https://github.com/jdek/openwith/releases/download/v$version/openwith-v$version.tar.xz"
	local archive=$(mktemp -d)/$(basename "$address") && curl -LA "mozilla/5.0" "$address" -o "$archive"
	local deposit=$(mktemp -d)
	expand_archive "$archive" "$deposit"
	"$deposit/openwith" com.colliderli.iina mkv mov mp4 avi

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/iina.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/IINA.app" "$picture" || sudo !!

}

update_intellij_idea() {

	# Handle parameters
	local deposit="${1:-$HOME/Projects}"

	# Update dependencies
	brew install fileicon
	brew upgrade fileicon

	# Update package
	local present=$([[ -d "/Applications/IntelliJ IDEA.app" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine intellij-idea
	brew upgrade --cask --no-quarantine intellij-idea

	# Launch it once
	if [[ "$present" == "false" ]]; then
		osascript <<-EOD
			set checkup to "/Applications/IntelliJ IDEA.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					tell process "IntelliJ IDEA"
						with timeout of 30 seconds
							repeat until (exists window 1)
								delay 1
							end repeat
						end timeout
					end tell
				end tell
				delay 4
				quit app "IntelliJ IDEA"
				delay 4
			end tell
		EOD
		pkill -9 -f 'IntelliJ IDEA'
	fi

}

update_jdownloader() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	brew install coreutils curl fileicon jq
	brew upgrade coreutils curl fileicon jq

	# Update package
	local present=$([[ -d "/Applications/JDownloader 2/JDownloader2.app" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine jdownloader

	# Finish installation
	if [[ "$present" == "false" ]]; then
		local appdata="/Applications/JDownloader 2/cfg"
		local config1="$appdata/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
		local config2="$appdata/org.jdownloader.settings.GeneralSettings.json"
		local config3="$appdata/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
		local config4="$appdata/org.jdownloader.extensions.extraction.ExtractionExtension.json"
		osascript <<-EOD
			set checkup to "/Applications/JDownloader 2/JDownloader2.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					repeat until (exists window 1 of application process "JDownloader2")
						delay 0.02
					end repeat
					tell application process "JDownloader2" to set visible to false
					repeat until (do shell script "test -f '$config1' && echo true || echo false") as boolean is true
						delay 1
					end repeat
				end tell
				delay 8
				quit
				delay 4
			end tell
		EOD
		jq ".bannerenabled = false" "$config1" | sponge "$config1"
		jq ".clipboardmonitored = false" "$config1" | sponge "$config1"
		jq ".donatebuttonlatestautochange = 4102444800000" "$config1" | sponge "$config1"
		jq ".donatebuttonstate = \"AUTO_HIDDEN\"" "$config1" | sponge "$config1"
		jq ".myjdownloaderviewvisible = false" "$config1" | sponge "$config1"
		jq ".premiumalertetacolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalertspeedcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalerttaskcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".specialdealoboomdialogvisibleonstartup = false" "$config1" | sponge "$config1"
		jq ".specialdealsenabled = false" "$config1" | sponge "$config1"
		jq ".speedmetervisible = false" "$config1" | sponge "$config1"
		mkdir -p "$deposit" && jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
		jq ".enabled = false" "$config3" | sponge "$config3"
		jq ".enabled = false" "$config4" | sponge "$config4"
		update_chromium_extension "fbcohnmimjicjdomonkcbcpbpnhggkip"
	fi

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/jdownloader.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/JDownloader 2/JDownloader2.app" "$picture" || sudo !!
	fileicon set "/Applications/JDownloader 2/Uninstall JDownloader.app" "$picture" || sudo !!
	cp "$picture" "/Applications/JDownloader 2/JDownloader2.app/Contents/Resources/app.icns"
	local sitting="/Applications/JDownloader 2/themes/standard/org/jdownloader/images/logo/jd_logo_128_128.png"
	sips -Z 128 -s format png "$picture" --out "$sitting"

}

update_joal_desktop() {

	# Update dependencies
	brew install curl fileicon grep jq
	brew upgrade curl fileicon grep jq

	# Update package
	local address="https://api.github.com/repos/anthonyraymond/joal-desktop/releases/latest"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
	local current=$(expand_version "/*ppl*/*oal*esk*")
	autoload is-at-least
	local updated=$(is-at-least "$version" "$current" && echo "true" || echo "false")
	if [[ "$updated" == "false" ]]; then
		local address="https://github.com/anthonyraymond/joal-desktop/releases"
		local address="$address/download/v$version/JoalDesktop-$version-mac-x64.dmg"
		local package=$(mktemp -d)/$(basename "$address") && curl -LA "mozilla/5.0" "$address" -o "$package"
		hdiutil attach "$package" -noautoopen -nobrowse
		cp -fr /Volumes/Joal*/Joal*.app /Applications
		hdiutil detach /Volumes/Joal*
		sudo xattr -rd com.apple.quarantine /Applications/Joal*.app
	fi

	# Change settings
	local configs="$HOME/Library/Application Support/JoalDesktop/joal-core/config.json"
	mkdir -p "$(dirname $configs)"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."minUploadRate" = 300' "$configs" | sponge "$configs"
	jq '."maxUploadRate" = 450' "$configs" | sponge "$configs"
	jq '."simultaneousSeed" = 200' "$configs" | sponge "$configs"
	jq '."client" = "transmission-3.00.client"' "$configs" | sponge "$configs"
	jq '."keepTorrentWithZeroLeechers" = true' "$configs" | sponge "$configs" 
	jq '."uploadRatioTarget" = -1' "$configs" | sponge "$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/joal-desktop.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/JoalDesktop.app" "$picture" || sudo !!

}

update_keepingyouawake() {

	# Update package
	brew install --cask --no-quarantine keepingyouawake
	brew upgrade --cask --no-quarantine keepingyouawake

}

update_miniforge() {

	# Update package
	brew install --cask --no-quarantine miniforge
	brew upgrade --cask --no-quarantine miniforge

	# Change environment
	conda init zsh

	# Change settings
	conda config --set auto_activate_base false

}

update_mpv() {

	# Update dependencies
	brew install curl fileicon grep
	brew upgrade curl fileicon grep

	# Update package
	brew install --cask --no-quarantine mpv
	brew upgrade --cask --no-quarantine mpv
	mv -f /Applications/mpv.app /Applications/Mpv.app

	# Create configuration
	local configs="$HOME/.config/mpv/mpv.conf"
	mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
	echo "profile=gpu-hq" >>"$configs"
	echo "hwdec=auto" >>"$configs"
	echo "keep-open=yes" >>"$configs"
	echo "interpolation=yes" >>"$configs"
	echo "blend-subtitles=yes" >>"$configs"
	echo "tscale=oversample" >>"$configs"
	echo "video-sync=display-resample" >>"$configs"
	echo 'ytdl-format="bestvideo[height<=?2160][vcodec!=vp9]+bestaudio/best"' >>"$configs"
	echo "[protocol.http]" >>"$configs"
	echo "force-window=immediate" >>"$configs"
	echo "[protocol.https]" >>"$configs"
	echo "profile=protocol.http" >>"$configs"
	echo "[protocol.ytdl]" >>"$configs"
	echo "profile=protocol.http" >>"$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/mpv.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Mpv.app" "$picture" || sudo !!

}

update_nightlight() {

	# Handle parameters
	local percent=${1:-75}
	local forever=${2:-true}

	# Update package
	brew install smudge/smudge/nightlight
	brew upgrade smudge/smudge/nightlight

	# Change settings
	[[ "$forever" == "true" ]] && nightlight schedule 3:00 2:59
	nightlight temp "$percent" && nightlight on

}

update_nodejs() {

	# Update dependencies
	brew install grep jq
	brew upgrade grep jq

	# Update package
	local address="https://raw.githubusercontent.com/scoopinstaller/main/master/bucket/nodejs-lts.json"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq '.version' | ggrep -oP "[\d]+" | head -1)
	brew install node@"$version"
	brew upgrade node@"$version"
	# brew link node@"$version" --force

	# Change environment
	if ! grep -q "/opt/homebrew/opt/node" "$HOME/.zshrc" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || echo '#!/bin/zsh' >"$HOME/.zshrc"
		[[ -z $(tail -1 "$HOME/.zshrc") ]] || echo "" >>"$HOME/.zshrc"
		echo "export PATH=\"\$PATH:/opt/homebrew/opt/node@$version/bin\"" >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	else
		sed -i "" -e "s#/opt/homebrew/opt/node.*/bin#/opt/homebrew/opt/node@$version/bin#" "$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

}

update_notion() {

	# Update dependencies
	brew install curl fileicon
	brew upgrade curl fileicon

	# Update package
	brew install --cask --no-quarantine notion
	brew upgrade --cask --no-quarantine notion

	# Change settings
	local configs="$HOME/Library/Application Support/Notion/state.json"
	mkdir -p "$(dirname $configs)"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '.appState.preferences.isMenuBarIconEnabled = false' "$configs" | sponge "$configs"
	jq '.appState.preferences.isAutoUpdaterDisabled = true' "$configs" | sponge "$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/notion.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Notion.app" "$picture" || sudo !!

}

update_obs() {

	# Update dependencies
	brew install curl fileicon
	brew upgrade curl fileicon

	# Update package
	brew install --cask --no-quarantine obs
	brew upgrade --cask --no-quarantine obs

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/obs.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/OBS.app" "$picture" || sudo !!

}

update_postgresql() {

	# Handle parameters
	local version=${1:-14}

	# Update package
	# INFO: Default credentials are $USER with empty password
	brew install postgresql@"$version"
	brew upgrade postgresql@"$version"
	brew services restart postgresql@"$version"

}

update_pycharm() {

	# Handle parameters
	local deposit="${1:-$HOME/Projects}"

	# Update dependencies
	brew install fileicon
	brew upgrade fileicon

	# Update package
	local present=$([[ -d "/Applications/PyCharm.app" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine pycharm
	brew upgrade --cask --no-quarantine pycharm

	# Launch it once
	if [[ "$present" == "false" ]]; then
		osascript <<-EOD
			set checkup to "/Applications/PyCharm.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					tell process "PyCharm"
						with timeout of 30 seconds
							repeat until (exists window 1)
								delay 1
							end repeat
						end timeout
					end tell
				end tell
				delay 4
				quit app "PyCharm"
				delay 4
			end tell
		EOD
		pkill -9 -f 'PyCharm'
	fi

}

update_rapidapi() {

	# Update package
	brew install --cask --no-quarantine rapidapi
	brew upgrade --cask --no-quarantine rapidapi

}

update_scrcpy() {

	# Update package
	brew install scrcpy
	brew upgrade scrcpy

}

update_staruml() {

	# Update dependencies
	brew install fileicon
	brew upgrade fileicon

	# Update package
	# brew install --cask --no-quarantine staruml
	# brew upgrade --cask --no-quarantine staruml

	# Update settings
	# https://gist.github.com/K1ethoang/83267585235bbb6a55e5479ae969d7a3
	# brew tap buo/cask-upgrade
	# brew cu pin staruml

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/staruml.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/StarUML.app" "$picture" || sudo !!

}

update_system() {

	# Handle parameters
	local machine=${1:-macintosh}

	# Change hostname
	sudo scutil --set ComputerName "$machine"
	sudo scutil --set HostName "$machine"
	sudo scutil --set LocalHostName "$machine"
	sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$machine"

	# Change finder
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	defaults write com.apple.finder ShowPathbar -bool true

	# Change globals
	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

	# Change preview
	defaults write com.apple.Preview NSRecentDocumentsLimit 0
	defaults write com.apple.Preview NSRecentDocumentsLimit 0

	# Change services
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
	defaults write com.apple.LaunchServices "LSQuarantine" -bool false

	# Enable tap-to-click
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
	/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

	# Remove remnants
	find ~ -name ".DS_Store" -delete

	# Remove startup chime
	sudo nvram StartupMute=%01

	# Update rosetta
	/usr/sbin/softwareupdate --install-rosetta --agree-to-license &>/dev/null

	# Update system (takes ages)
	# sudo softwareupdate --download --all --force --agree-to-license --verbose

}

update_the_unarchiver() {

	# Update package
	local present=$([[ -d "/Applications/The Unarchiver.app" ]] && echo "true" || echo "false")
	brew install --cask --no-quarantine the-unarchiver
	brew upgrade --cask --no-quarantine the-unarchiver

	# Finish installation
	if [[ "$present" == "false" ]]; then
		osascript <<-EOD
			set checkup to "/Applications/The Unarchiver.app"
			tell application checkup
				activate
				reopen
				tell application "System Events"
					with timeout of 10 seconds
						repeat until (exists window 1 of application process "The Unarchiver")
							delay 1
						end repeat
					end timeout
					tell process "The Unarchiver"
						try
							click button "Accept" of window 1
							delay 2
						end try
						click button "Select All" of tab group 1 of window 1
					end tell
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD
	fi

	# Change settings
	defaults write com.macpaw.site.theunarchiver extractionDestination -integer 3
	defaults write com.macpaw.site.theunarchiver isFreshInstall -integer 1
	defaults write com.macpaw.site.theunarchiver userAgreedToNewTOSAndPrivacy -integer 1

}

update_transmission() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/P2P}
	local seeding=${2:-0.1}

	# Update dependencies
	brew install curl fileicon
	brew upgrade curl fileicon

	# Update package
	brew install --cask --no-quarantine transmission
	brew upgrade --cask --no-quarantine transmission

	# Change settings
	# INFO: Use `osascript -e 'id of app "Transmission"'` to get bundle id
	mkdir -p "$deposit/Incompleted"
	defaults write org.m0k.transmission DownloadFolder -string "$deposit"
	defaults write org.m0k.transmission IncompleteDownloadFolder -string "$deposit/Incompleted"
	defaults write org.m0k.transmission RatioCheck -bool true
	defaults write org.m0k.transmission RatioLimit -int "$seeding"
	defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
	defaults write org.m0k.transmission WarningDonate -bool false
	defaults write org.m0k.transmission WarningLegal -bool false

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/transmission.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Transmission.app" "$picture" || sudo !!

}

update_utm() {

	# Update dependencies
	brew install curl fileicon
	brew upgrade curl fileicon

	# Update package
	brew install --cask --no-quarantine utm
	brew upgrade --cask --no-quarantine utm

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/utm.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/UTM.app" "$picture" || sudo !!

}

update_vscode() {

	# Update dependencies
	brew install jq sponge
	brew upgrade jq sponge

	# Update package
	brew install --cask --no-quarantine visual-studio-code
	brew upgrade --cask --no-quarantine visual-studio-code
	
	# Update extensions
	code --install-extension "Codeium.codeium" --force
	code --install-extension "foxundermoon.shell-format" --force
	code --install-extension "github.github-vscode-theme" --force
	code --install-extension "streetsidesoftware.code-spell-checker" --force

	# Change settings
	local configs="$HOME/Library/Application Support/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.fontSize" = 13' "$configs" | sponge "$configs"
	jq '."editor.guides.bracketPairs" = "active"' "$configs" | sponge "$configs"
	jq '."editor.lineHeight" = 36' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."telemetry.telemetryLevel" = "crash"' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"
	jq '."workbench.startupEditor" = "none"' "$configs" | sponge "$configs"

}

update_whisky() {

	# Update package
	brew install --cask --no-quarantine whisky
	brew upgrade --cask --no-quarantine whisky

}

update_xcode() {

	# Verify apple id
	assert_apple_id || return 1

	# Update dependencies
	brew install cocoapods curl fileicon grep xcodesorg/made/xcodes
	brew upgrade cocoapods curl fileicon grep xcodesorg/made/xcodes

	# Update package
	local starter="/Applications/Xcode.app"
	local current=$(expand_version "$starter")
	local version=$(xcodes list | tail -5 | grep -v Beta | tail -1 | ggrep -oP "[\d.]+" | head -1)
	autoload is-at-least
	local updated=$(is-at-least "$version" "$current" && echo "true" || echo "false")
	if [[ "$updated" == "false" ]]; then
		xcodes install --latest
		rm -fr "$starter" && mv -f /Applications/Xcode*.app "$starter"
		sudo xcode-select --switch "$starter/Contents/Developer"
		sudo xcodebuild -runFirstLaunch
		sudo xcodebuild -license accept
	fi

	# TODO: Change settings
	# TODO: Change plugins

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/xcode.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "$starter" "$picture" || sudo !!

}

update_youtube_music() {

	# Update dependencies
	brew install jq sponge
	brew upgrade jq sponge

	# Update package
	brew install --cask --no-quarantine th-ch/youtube-music/youtube-music
	brew upgrade --cask --no-quarantine th-ch/youtube-music/youtube-music

	# Change settings
	local configs="$HOME/Library/Application Support/YouTube Music/config.json"
	jq '.plugins."quality-changer".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."sponsorblock".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."synced-lyrics".enabled = true' "$configs" | sponge "$configs"
	# jq '.plugins."no-google-login".enabled = true' "$configs" | sponge "$configs"

}

update_yt_dlp() {

	# Update package
	brew install yt-dlp
	brew upgrade yt-dlp

	# Create symlink
	sudo ln -sf /usr/local/bin/yt-dlp /usr/local/bin/youtube-dl

}

#endregion

#region DEVTOOLS

update_angular_devtools() {

	# Update dependencies
	update_chromium
	update_intellij_idea
	update_nodejs
	update_vscode

	# Update chromium extensions
	update_chromium_extension "ienfalfjdbdpebioblfackkekamfmbnh" # angular-devtools

	# Update intellij plugins
	idea installPlugins AngularJS # angular

}

update_odoo_devtools() {

	# Update dependencies
	update_miniforge
	update_nodejs
	update_postgresql
	update_pycharm
	update_vscode
	xcode-select --install
	brew install --cask --no-quarantine wkhtmltopdf
	brew upgrade --cask --no-quarantine wkhtmltopdf

	# Create postgresql database
	createdb $USER 2>/dev/null

	# Update nodejs modules
	npm install -g rtlcss

	# TODO: Create miniforge environment
	# TODO: Install odoo community on created environment

	# Update pycharm plugins
	pycharm installPlugins dev.ngocta.pycharm-odoo
	pycharm installPlugins net.seesharpsoft.intellij.plugins.csv
	pycharm installPlugins XPathView

	# Update vscode extensions
	code --install-extension "jigar-patel.odoosnippets" --force
	code --install-extension "mechatroner.rainbow-csv" --force
	code --install-extension "ms-python.vscode-pylance" --force

	# Change vscode settings
	local configs="$HOME/Library/Application Support/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."[python]"."editor.codeActionsOnSave"."source.fixAll" = "explicit"' "$configs" | sponge "$configs"
	jq '."[python]"."editor.defaultFormatter" = "ms-python.black-formatter"' "$configs" | sponge "$configs"
	jq '."[python]"."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."[python]"."editor.tabSize" = 4' "$configs" | sponge "$configs"

}

update_spring_devtools() {

	# Update dependencies
	update_intellij_idea
	update_vscode
	brew install gradle maven
	brew upgrade gradle maven
	brew install --cask --no-quarantine temurin
	brew upgrade --cask --no-quarantine temurin

	# Update vscode extensions
	code --install-extension "vmware.vscode-boot-dev-pack" --force
	code --install-extension "vscjava.vscode-java-pack" --force

	# Update intellij plugins
	idea installPlugins com.haulmont.jpab # jpa-buddy

}

update_react_devtools() {

	# Update dependencies
	update_chromium
	update_nodejs
	update_vscode

	# Update chromium extensions
	update_chromium_extension "fmkadmapgofadopljbjfkapdkoienihi" # react-developer-tools
	update_chromium_extension "lmhkpmbekcpmknklioeibfkpmmfibljd" # redux-devtools

	# Update vscode extensions
	code --install-extension "bradlc.vscode-tailwindcss" --force
	code --install-extension "dbaeumer.vscode-eslint" --force
	code --install-extension "deerawan.vscode-modern-react-typescript-snippets" --force
	code --install-extension "esbenp.prettier-vscode" --force
	code --install-extension "usernamehw.errorlens" --force
	code --install-extension "yoavbls.pretty-ts-errors" --force

	# Change vscode settings
	local configs="$HOME/Library/Application Support/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."[css][javascript][javascriptreact][json][html][typescript][typescriptreact]"."editor.codeActionsOnSave"."source.fixAll" = "explicit"' "$configs" | sponge "$configs"
	jq '."[css][javascript][javascriptreact][json][html][typescript][typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode"' "$configs" | sponge "$configs"
	jq '."[css][javascript][javascriptreact][json][html][typescript][typescriptreact]"."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."[css][javascript][javascriptreact][json][html][typescript][typescriptreact]"."editor.tabSize" = 2' "$configs" | sponge "$configs"
	jq '."[css][javascript][javascriptreact][json][html][typescript][typescriptreact]"."prettier.printWidth" = 120' "$configs" | sponge "$configs"

	# Update intellij plugins
	idea installPlugins com.haulmont.rcb # react-buddy

}

#endregion

main() {

	# Verify executor
	assert_executor || return 1

	# Change headline
	printf "\033]0;%s\007" "$(basename "$ZSH_ARGZERO" | cut -d . -f 1)"

	# Prompt password
	clear && sudo -v

	# Output greeting
	clear && read -r -d "" welcome <<-EOD
	███╗░░░███╗░█████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
	████╗░████║██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
	██╔████╔██║███████║██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
	██║╚██╔╝██║██╔══██║██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
	██║░╚═╝░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
	╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove timeouts
	echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /private/etc/sudoers.d/disable_timeout >/dev/null

	# Remove sleeping
	sudo pmset -a displaysleep 0 && sudo pmset -a sleep 0
	(caffeinate -i -w $$ &) &>/dev/null

	# Verify password
	assert_password || return 1

	# Handle security
	handle_security || return 1

	# Update homebrew
	update_homebrew || return 1

	# Verify apple id
	# assert_apple_id || return 1

	# Change timezone
	sudo systemsetup -settimezone "Europe/Brussels" &>/dev/null

	# Handle elements
	local members=(
		# "update_system"
		# "update_android_studio"
		# "update_chromium"
		# "update_git 'main' 'olankens' '173156207+olankens@users.noreply.github.com'"
		# "update_vscode"
		# "update_xcode"
		# "update_awscli"
		# "update_datagrip"
		"update_discord"
		# "update_docker"
		# "update_figma"
		# "update_flutter"
		# "update_fork"
		# "update_github_cli"
		# "update_iina"
		"update_intellij_idea"
		# "update_jdownloader"
		# "update_joal_desktop"
		# "update_keepingyouawake"
		# "update_miniforge"
		# "update_mpv"
		# "update_nightlight"
		# "update_nodejs"
		"update_notion"
		# "update_obs"
		# "update_postgresql"
		# "update_pycharm"
		# "update_scrcpy"
		# "update_staruml"
		# "update_the_unarchiver"
		# "update_transmission"
		# "update_utm"
		# "update_whisky"
		# "update_youtube_music"
		# "update_yt_dlp"
		# "update_angular_devtools"
		# "update_odoo_devtools"
		# "update_spring_devtools"
		# "update_react_devtools"
		"update_appearance"
	)

	# Output progress
	local bigness=$((${#welcome} / $(echo "$welcome" | wc -l)))
	local heading="\r%-"$((bigness - 19))"s   %-5s   %-8s\n\n"
	local loading="\033[93m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\b\033[0m"
	local failure="\033[91m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	local success="\033[92m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	printf "$heading" "FUNCTION" "ITEMS" "DURATION"
	local minimum=1 && local maximum=${#members[@]}
	for element in "${members[@]}"; do
		local written=$(basename "$(echo "$element" | cut -d "'" -f 1)" | tr "[:lower:]" "[:upper:]")
		local started=$(date +"%s") && printf "$loading" "$written" "$minimum" "$maximum" "--:--:--"
		eval "$element" >/dev/null 2>&1 && local current="$success" || local current="$failure"
		# eval "$element" && local current="$success" || local current="$failure"
		local extinct=$(date +"%s") && elapsed=$((extinct - started))
		local elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$minimum" "$maximum" "$elapsed" && ((minimum++))
	done

	# Revert sleeping
	sudo pmset restoredefaults >/dev/null

	# Revert timeouts
	sudo rm /private/etc/sudoers.d/disable_timeout 2>/dev/null

	# Output new line
	printf "\n"

}

[[ $ZSH_EVAL_CONTEXT != *:file ]] && main "$@"
