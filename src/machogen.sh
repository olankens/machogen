# !/bin/zsh
# shellcheck shell=bash

# region services

# @define Append application to the dock
# @params The application full path
append_dock_application() {

	# Handle parameters
	local element=${1}

	# Append application
	if [[ -d "$element" ]]; then
		defaults write com.apple.dock persistent-apps -array-add "<dict>
			<key>tile-data</key>
			<dict>
				<key>file-data</key>
				<dict>
					<key>_CFURLString</key>
					<string>${element}</string>
					<key>_CFURLStringType</key>
					<integer>0</integer>
				</dict>
			</dict>
		</dict>"
	fi

}

# @define Append folder to the dock
# @params The folder full path
# @params The arrangement integer (1: name, 2: added, 3: modified, 4: created, 5: kind)
# @params The displayas integer (0: stack, 1: folder)
# @params The showas integer (0: automatic, 1: fan, 2: grid, 3: list)
append_dock_folder() {

	# Handle parameters
	local element=${1}
	local arrangement=${2:-1}
	local display_as=${3:-0}
	local show_as=${4:-0}

	# Append folder
	if [[ -d "$element" ]]; then
		defaults write com.apple.dock persistent-others -array-add "<dict>
			<key>tile-data</key>
			<dict>
				<key>arrangement</key>
				<integer>${arrangement}</integer>
				<key>displayas</key>
				<integer>${display_as}</integer>
				<key>file-data</key>
				<dict>
					<key>_CFURLString</key>
					<string>file://${element}</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-type</key>
				<integer>2</integer>
				<key>showas</key>
				<integer>${show_as}</integer>
			</dict>
			<key>tile-type</key>
			<string>directory-tile</string>
		</dict>"
	fi

}

# @define Assert apple credentials from keychain
# @return 0 for success, 1 for failure
assert_apple_id() {

	# Handle passwords
	local secret1=$(gather_password apple-username generic)
	local secret2=$(gather_password apple-password generic)
	[[ -z "$secret1" || -z "$secret2" ]] && return 1

	# Verify passwords
	brew install xcodesorg/made/xcodes &>/dev/null
	export XCODES_USERNAME="$secret1"
	export XCODES_PASSWORD="$secret2"
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

# @define Assert script is running with sudo privileges
# @return 0 for success, 1 for failure
assert_admin_execution() {

	# Verify privileges
	[[ $EUID = 0 ]]

}

# @define Assert sudo password from keychain
# @return 0 for success, 1 for failure
assert_admin_password() {

	# Handle password
	local secret1=$(gather_password admin-password generic)

	# Verify password
	sudo -k && echo "$secret1" | sudo -S -v &>/dev/null

}

# @define Assert current macos version
# @params The expected major macos version
# @return 0 for success, 1 for failure
assert_macos_version() {

	# Handle parameters
	local version=${1:-14}

	# Verify version
	[[ $(sw_vers -productVersion) =~ ^$version ]] || return 1

}

# @define Change chromium download folder
# @params The download location full path
change_chromium_download() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# Change deposit
	defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	mkdir -p "$deposit" && killall "Chromium" 2>/dev/null && sleep 4
	osascript <<-EOD
		set starter to "/Applications/Chromium.app"
		tell application starter
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

}

# @define Change chromium search engine
# @params The pattern used to identify the engine in the list
change_chromium_engine() {

	# INFO: Google intentionally randomized and restricted access to search engine list
	# TODO: Use keystrokes and OCR to achieve
	return 1

	# Handle parameters
	local pattern=${1:-duckduckgo}
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# Change search engine
	killall "Chromium" 2>/dev/null && sleep 4
	defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	osascript <<-EOD
		set starter to "/Applications/Chromium.app"
		tell application starter
			activate
			reopen
			delay 4
			open location "chrome://settings/search"
			delay 2
			tell application "System Events"
				repeat 2 times
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

}

# @define Change chromium flag
# @params The chromium flag to change
# @params The payload value to set for the specified flag
change_chromium_flag() {

	# Handle parameters
	local element=${1}
	local payload=${2}
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# Change flag
	defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	killall "Chromium" 2>/dev/null && sleep 4
	if [[ "$element" == "custom-ntp" ]]; then
		osascript <<-EOD
			set starter to "/Applications/Chromium.app"
			tell application starter
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "custom-ntp"
					delay 2
					repeat 4 times
						key code 48
					end repeat
					delay 2
					keystroke "a" using {command down}
					delay 1
					keystroke "${payload}"
					delay 2
					key code 48
					key code 48
					delay 2
					key code 125
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
	elif [[ "$element" == "extension-mime-request-handling" ]]; then
		osascript <<-EOD
			set starter to "/Applications/Chromium.app"
			tell application starter
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
					key code 125
					delay 2
					keystroke "${payload}"
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD
	elif [[ "$element" == "remove-tabsearch-button" ]]; then
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
					repeat 5 times
						key code 48
					end repeat
					delay 2
					key code 125
					delay 2
					keystroke "${payload}"
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD
	elif [[ "$element" == "show-avatar-button" ]]; then
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
					key code 125
					delay 2
					keystroke "${payload}"
					delay 2
					key code 49
				end tell
				delay 2
				quit
				delay 2
			end tell
		EOD
	fi

}

# @define Change default web browser
# @params The browser name (chrome, chromium, firefox, safari, vivaldi, ...)
change_default_browser() {

	# Handle parameters
	local browser=${1:-safari}

	# Handle dependencies
	update_brew defaultbrowser

	# Change browser
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

# @define Change desktop wallpaper
# @params The picture full path
change_desktop_wallpaper() {

	# Handle parameters
	local picture=${1}

	# Change wallpaper
	osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$picture\""

}

# @define Change system hostname
# @params The new hostname
change_hostname() {

	# Handle parameters
	local payload=${1}

	# Change hostname
	sudo scutil --set ComputerName "$payload"
	sudo scutil --set HostName "$payload"
	sudo scutil --set LocalHostName "$payload"
	sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$payload"

}

# @define Change system sleep settings by enabling or disabling sleeping
# @params True to restore default sleep settings or false to disable it
change_sleeping() {

	# Handle parameters
	local enabled=${1:-true}

	# Enable sleeping
	if [[ "$enabled" == "true" ]]; then
		sudo pmset restoredefaults >/dev/null
	else
		sudo pmset -a displaysleep 0 && sudo pmset -a sleep 0
		(caffeinate -i -w $$ &) &>/dev/null
	fi

}

# @define Change sudo timeouts by enabling or disabling the password prompt
# @params True to enable the timeouts or false to disable it
change_timeouts() {

	# Handle parameters
	local enabled=${1:-true}

	# Enable timeouts
	if [[ "$enabled" == "true" ]]; then
		sudo rm /private/etc/sudoers.d/disable_timeout 2>/dev/null
	else
		echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /private/etc/sudoers.d/disable_timeout >/dev/null
	fi

}

# @define Change system timezone
# @params The timezone string
change_timezone() {

	# Handle parameters
	local payload=${1}

	# Change timezone
	sudo systemsetup -settimezone "$payload" &>/dev/null

}

# @define Expand archive
# @params The archive path or direct http url
# @params The deposit path for extraction
# @params The number of leading dirs to strip
# @return The extraction full path
expand_archive() {

	# Handle parameters
	local archive=${1}
	local deposit=${2:-.}
	local leading=${3:-0}

	# Expand archive
	if [[ -n $archive && ! -f $deposit && $leading =~ ^[0-9]+$ ]]; then
		mkdir -p "$deposit"
		if [[ $archive = http* ]]; then
			curl -L "$archive" | tar -zxf - -C "$deposit" --strip-components=$((leading))
		else
			tar -zxf "$archive" -C "$deposit" --strip-components=$((leading))
		fi
		printf "%s" "$deposit"
	fi

}

# @define Gather password from current user's keychain
# @params The service name
# @params The password variant (generic or internet)
# @return The gathered password or empty string
gather_password() {

	# Handle parameters
	local service=${1}
	local variant=${2:-generic}

	# Gather password
	security find-"$variant"-password -a "$USER" -s "$service" -w 2>/dev/null

}

# @define Gather path
# @params The search pattern or directory
# @params The maximum depth for search
# @return The gathered full path
gather_pattern() {

	# Handle parameters
	local pattern=${1}
	local maximum=${2:-0}

	# Gather path
	echo "$(/bin/zsh -c "find $pattern -maxdepth $maximum" 2>/dev/null | sort -r | head -1)" || sudo !!

}

# @define Gather installed application version
# @params The application full path
# @return The gathered version for success, 0.0.0.0 for failure
gather_version() {

	# Handle parameters
	local apppath=${1}

	# Handle dependencies
	update_brew grep

	# Gather version
	local starter=$(gather_pattern "$apppath/*ontents/*nfo.plist")
	local version=$(defaults read "$starter" CFBundleShortVersionString 2>/dev/null)
	echo "$version" | ggrep -oP "[\d.]+" || echo "0.0.0.0"

}

# @define Invoke application, wait for first window and close
# @params The whole application name
# @params The whole process name
# @params The maximum wait time (seconds) for the window
invoke_once() {

	# Handle parameters
	local appname=${1}
	local process=${2:-$1}
	local timeout=${3:-30}

	# Invoke application
	osascript <<-EOD
		set starter to "/Applications/${appname}.app"
		tell application starter
			activate
			reopen
			tell application "System Events"
				tell process "${process}"
					with timeout of ${timeout} seconds
						repeat until (exists window 1)
							delay 1
						end repeat
					end timeout
				end tell
			end tell
			delay 4
			quit app "${appname}"
			delay 4
		end tell
	EOD
	pkill -9 -f "$appname"

}

# @define Invoke functions with a welcome message and tracks time
# @params The welcome message to display at the start
# @params The timezone string
# @params The machine hostname
# @params The functions to invoke in sequence
invoke_wrapper() {

	# Handle parameters
	local welcome=${1}
	local country=${2}
	local machine=${3}
	local members=("${@:4}")

	# Change headline
	printf "\033]0;%s\007" "$(basename "$ZSH_ARGZERO" | cut -d . -f 1)"

	# Verify executor
	clear && printf "\n\033[92m%s\033[00m\n\n" "$welcome"
	verify_executor || return 1

	# Prompt password
	sudo -v; local results=$?; printf "\n"; [[ $results -ne 0 ]] && return 1
	clear && printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove timeouts
	change_timeouts false

	# Remove sleeping
	change_sleeping false

	# Verify requirements
	verify_security || return 1
	verify_homebrew || return 1
	# verify_apple_id || return 1

	# Change timezone
	change_timezone "$country"

	# Change hostname
	change_hostname "$machine"

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

	# Enable sleeping
	change_sleeping true

	# Enable timeouts
	change_timeouts true

	# Output newline
	printf "\n"

}

# @define Scrape data from website using regex pattern
# @params The address to scrape
# @params The pattern to evaluate against the scraped content
# @return The scraped string matching the provided regex pattern
scrape_website() {

	# Handle parameters
	local address=${1}
	local pattern=${2}

	# Handle dependencies
	update_brew grep

	# Scrape website
	local content=$(curl -s "$address")
	local results=$(echo "$content" | ggrep -oP "$pattern" | head -n 1)
	echo "$results"

}

# @define Update brew packages
# @params The brew package names
update_brew() {

	# Handle parameters
	local payload=("$@")

	# Update packages
	brew install "${payload[@]}"
	brew upgrade "${payload[@]}"

}

# @define Update cask packages
# @params The cask package names
update_cask() {

	# Handle parameters
	local payload=("$@")

	# Updade packages
	brew install --cask --no-quarantine "${payload[@]}"
	brew upgrade --cask --no-quarantine "${payload[@]}"

}

# @define Update chromium extension
# @params The payload (crx url, zip url or extension uuid)
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

# @define Handle apple id credential verification in the keychain
# @return 0 for success, 1 for failure
verify_apple_id() {

	printf "\r\033[K"
	printf "\r\033[93m%s\033[00m" "VERIFYING KEYCHAIN ELEMENTS, BE PATIENT"
	if ! assert_apple_id; then
		security delete-generic-password -s apple-username &>/dev/null
		security delete-generic-password -s apple-password &>/dev/null
		printf "\r\033[91m%s\033[00m\n\n" "APPLE CREDENTIALS NOT IN KEYCHAIN OR INCORRECT"
		printf "\r\033[92m%s\033[00m\n" "security add-generic-password -a \$USER -s apple-username -w username"
		printf "\r\033[92m%s\033[00m\n\n" "security add-generic-password -a \$USER -s apple-password -w password"
		return 1
	fi

}

# @define Handle verifying the executor's privileges
# @return 0 for success, 1 for failure
verify_executor() {

	if assert_admin_execution; then
		printf "\r\033[K"
		printf "\r\033[91m%s\033[00m\n\n" "EXECUTING MACHOGEN AS ROOT IS FORBIDDEN"
		return 1
	fi

}

# @define Handle upgrading and configuring homebrew
# @return 0 for success, 1 for failure
verify_homebrew() {

	printf "\r\033[K"
	printf "\r\033[93m%s\033[00m" "VERIFYING HOMEBREW PRESENCE, BE PATIENT"
	local command=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
	CI=1 /bin/bash -c "$command" &>/dev/null
	local configs="$HOME/.zprofile"
	if ! grep -q "/opt/homebrew/bin/brew shellenv" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$configs"
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi
	brew analytics off
	brew cleanup &>/dev/null
	return 0

}

# @define Handle current shell privileges, requires user interaction 
# @return 0 for success, 1 for failure
verify_security() {

	printf "\r\033[K"
	printf "\r\033[93m%s\033[00m" "VERIFYING TERMINAL SECURITY, FOLLOW DIALOGS"
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
	return 0

}

# endregion

# region updaters

# @define Update android-cmdline
update_android_cmdline() {

	# Handle dependencies
	update_brew curl grep jq
	update_temurin

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

# @define Update android-studio
update_android_studio() {

	# Handle dependencies
	update_brew grep xmlstarlet

	# Update package
	local present="$([[ -d "/Applications/Android Studio.app" ]] && echo true || echo false)"
	update_cask android-studio

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "Android Studio"; fi

	# TODO: Change settings

}

# @define Update appearance
update_appearance() {

	# Change dock
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0
	defaults write com.apple.dock autohide-time-modifier -float 0.25
	defaults write com.apple.dock minimize-to-application -bool true
	defaults write com.apple.dock orientation bottom
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.Dock size-immutable -bool yes
	defaults write com.apple.dock tilesize -int 36
	defaults write com.apple.dock wvous-bl-corner -int 0
	defaults write com.apple.dock wvous-br-corner -int 0
	defaults write com.apple.dock wvous-tl-corner -int 0
	defaults write com.apple.dock wvous-tr-corner -int 0
	defaults delete com.apple.dock persistent-apps
	defaults delete com.apple.dock persistent-others
	append_dock_application "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
	append_dock_application "/Applications/Chromium.app"
	append_dock_application "/Applications/JDownloader 2/JDownloader2.app"
	append_dock_application "/Applications/Transmission.app"
	append_dock_application "/Applications/Joal Desktop.app"
	append_dock_application "/Applications/Discord.app"
	append_dock_application "/Applications/Vesktop.app"
	append_dock_application "/Applications/calibre.app"
	append_dock_application "/Applications/Notion.app"
	append_dock_application "/Applications/Visual Studio Code.app"
	append_dock_application "/Applications/Android Studio.app"
	append_dock_application "/Applications/Xcode.app"
	append_dock_application "/Applications/WebStorm.app"
	append_dock_application "/Applications/IntelliJ IDEA.app"
	append_dock_application "/Applications/Cursor.app"
	append_dock_application "/Applications/UTM.app"
	append_dock_application "/Applications/Figma.app"
	append_dock_application "/Applications/OBS.app"
	append_dock_application "/Applications/mpv.app"
	append_dock_application "/Applications/YouTube Music.app"
	append_dock_application "/Applications/CrossOver.app"
	append_dock_application "/Applications/Pearcleaner.app"
	append_dock_application "/System/Applications/Utilities/Terminal.app"
	killall Dock

}

# @define Update awscli
update_awscli() {

	# Update package
	update_brew awscli

	# TODO: Change settings

}

# @define Update calibre
update_calibre() {

	# Handle dependencies
	update_brew curl fileicon

	# Update package
	update_cask calibre

	# Finish install
	invoke_once "calibre"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/calibre.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/calibre.app" "$picture" || sudo !!
}

# @define Update chromium
update_chromium() {
	
	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local pattern=${2:-duckduckgo}
	local tabpage=${3:-about:blank}

	# Handle dependencies
	update_brew curl jq

	# Update package
	local present="$([[ -d "/Applications/Chromium.app" ]] && echo "true" || echo "false")"
	update_cask eloston-chromium
	killall Chromium || true

	# Change default browser
	change_default_browser "chromium"

	# Finish installation
	if [[ "$present" == "false" ]]; then

		# Handle notifications
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

		# Change settings
		change_chromium_download "$deposit"

		# Change engine
		change_chromium_engine "$pattern"

		# Change flags
		change_chromium_flag "custom-ntp" "about:blank"
		change_chromium_flag "extension-mime-request-handling" "always"
		change_chromium_flag "remove-tabsearch-button" "enabled"
		change_chromium_flag "show-avatar-button" "never"

		# Toggle bookmarks
		osascript <<-EOD
			set starter to "/Applications/Chromium.app"
			tell application starter
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
		local website="https://api.github.com/repos/NeverDecaf/chromium-web-store/releases"
		local version=$(curl -s "$website" | jq -r ".[0].tag_name" | tr -d "v")
		local address="https://github.com/NeverDecaf/chromium-web-store/releases/download/v$version/Chromium.Web.Store.crx"
		update_chromium_extension "$address"

		# Update extensions
		# update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
		# update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		# update_chromium_extension "lkahpjghmdhpiojknppmlenngmpkkfma" # skip-ad-ad-block-auto-ad
		# update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "nngceckbapebfimnlniiiahkandclblb" # bitwarden-password-manage

	fi

	# Update bypass-paywalls-chrome-clean
	# update_chromium_extension "https://github.com/bpc-clone/bpc_updates/releases/download/latest/bypass-paywalls-chrome-clean-master.zip"

}

# @define Update claude-code
update_claude_code() {

	# Handle dependencies
	update_brew ccusage

	# Update package
	# npm install -g @anthropic-ai/claude-code
	curl -fsSL https://claude.ai/install.sh | bash

	# Update vscode extensions
	code --install-extension "anthropic.claude-code" --force

	# Update intellij plugins
	idea installPlugins com.anthropic.code.plugin
	webstorm installPlugins com.anthropic.code.plugin

}

# @define Update crossover
update_crossover() {

	# Change settings
	defaults write com.codeweavers.CrossOver AskForRatings -bool false
	defaults write com.codeweavers.CrossOver SUAutomaticallyUpdate -bool false
	defaults write com.codeweavers.CrossOver SUEnableAutomaticChecks -bool false
	defaults write com.codeweavers.CrossOver SUHasLaunchedBefore -bool true

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/crossover.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/CrossOver.app" "$picture" || sudo !!

}

# @define Update cursor
update_cursor() {

	# Handle dependencies
	update_brew jq sponge

	# Update package
	update_cask cursor

	# Change settings
	local configs="$HOME/Library/Application Support/Cursor/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/cursor.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Cursor.app" "$picture" || sudo !!

}

# @define Update docker
update_docker() {

	# Handle dependencies
	update_brew colima docker-buildx docker-compose jq sponge

	# Update package
	update_brew docker

	# Launch service
	# colima start

	# Change settings
	local configs="$HOME/.docker/config.json"
	jq '. + {cliPluginsExtraDirs: ["/opt/homebrew/lib/docker/cli-plugins"]}' "$configs" | sponge "$configs"

}

# @define Update figma
update_figma() {

	# Handle dependencies
	update_brew jq sponge

	# Update package
	update_cask figma

	# Change settings
	local configs="$HOME/Library/Application Support/Figma/settings.json"
	jq '.showFigmaInMenuBar = false' "$configs" | sponge "$configs"

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/figma.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Figma.app" "$picture" || sudo !!

}

# @define Update git
update_git() {

	# Handle parameters
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	# Update package
	update_brew git

	# Change settings
	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail"
	[[ -n "$gituser" ]] && git config --global user.name "$gituser"
	git config --global checkout.workers 0
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global push.autoSetupRemote true

}

# @define Update git
update_github_cli() {

	# Update package
	update_brew gh

}

# @define Update intellij-idea
update_intellij_idea() {

	# Handle dependencies
	update_brew grep xmlstarlet

	# Update package
	local present="$([[ -d "/Applications/IntelliJ IDEA.app" ]] && echo "true" || echo "false")"
	update_cask intellij-idea

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "IntelliJ IDEA"; fi

	# TODO: Change settings

}

# @define Update jdownloader
update_jdownloader() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/JD2}

	# Handle dependencies
	update_brew coreutils curl fileicon jq

	# Update package
	local present="$([[ -d "/Applications/JDownloader 2/JDownloader2.app" ]] && echo "true" || echo "false")"
	update_cask jdownloader

	# Finish install
	if [[ "$present" == "false" || true ]]; then
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

	# Changes icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/jdownloader.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/JDownloader 2/JDownloader2.app" "$picture" || sudo !!
	fileicon set "/Applications/JDownloader 2/Uninstall JDownloader.app" "$picture" || sudo !!
	cp "$picture" "/Applications/JDownloader 2/JDownloader2.app/Contents/Resources/app.icns"
	local sitting="/Applications/JDownloader 2/themes/standard/org/jdownloader/images/logo/jd_logo_128_128.png"
	sips -Z 128 -s format png "$picture" --out "$sitting"

}

# @define Update joal-desktop
update_joal_desktop() {

	# Handle dependencies
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

# @define Update keepingyouawake
update_keepingyouawake() {

	# Update package
	update_cask keepingyouawake

}

# @define Update kubernetes
update_kubernetes() {

	# TODO: Implement function

}

# @define Update miniforge
update_miniforge() {

	# Update package
	update_cask miniforge

	# Change settings
	conda init zsh
	conda config --set auto_activate_base false

}

# @define Update mpv
update_mpv() {

	# Handle dependencies
	update_brew curl fileicon yt-dlp

	# Update package
	update_cask mpv

	# Change settings
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

# @define Update nightlight
update_nightlight() {

	# Handle parameters
	local percent=${1:-75}
	local forever=${2:-true}

	# Update package
	update_brew smudge/smudge/nightlight

	# Change settings
	[[ "$forever" == "true" ]] && nightlight schedule 3:00 2:59
	nightlight temp "$percent" && nightlight on

}

# @define Update nodejs (lts)
update_nodejs() {

	# Handle dependencies
	update_brew curl grep jq

	# Update package
	local address="https://raw.githubusercontent.com/scoopinstaller/main/master/bucket/nodejs-lts.json"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq '.version' | ggrep -oP "[\d]+" | head -1)
	update_brew node@"$version"

	# Change environment
	if ! grep -q "/opt/homebrew/opt/node" "$HOME/.zshrc" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || echo '#!/bin/zsh' >"$HOME/.zshrc"
		[[ -z $(tail -1 "$HOME/.zshrc") ]] || echo "" >>"$HOME/.zshrc"
		echo "export PATH=\"\$PATH:/opt/homebrew/opt/node@$version/bin\"" >>"$HOME/.zshrc"
		source "$configs"
	else
		sed -i "" -e "s#/opt/homebrew/opt/node.*/bin#/opt/homebrew/opt/node@$version/bin#" "$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

}

# @define Update notion
update_notion() {

	# Handle dependencies
	update_brew curl fileicon

	# Update package
	update_cask notion

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

# @define Update obs
update_obs() {

	# Handle dependencies
	update_brew curl fileicon

	# Update package
	update_cask obs

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/obs.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/OBS.app" "$picture" || sudo !!
}

# @define Update pearcleaner
update_pearcleaner() {

	# Update package
	update_cask pearcleaner

}

# @define Update postgresql
update_postgresql() {

	# Handle parameters
	local version=${1:-14}

	# Update package
	# INFO: Default credentials are $USER with empty password
	update_brew postgresql@"$version"

	# Launch service
	brew services restart postgresql@"$version"

}

# @define Update system
update_system() {

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

	# Remove chime
	sudo nvram StartupMute=%01

	# Update rosetta
	/usr/sbin/softwareupdate --install-rosetta --agree-to-license &>/dev/null

	# Update system
	# INFO: Takes ages
	# sudo softwareupdate --download --all --force --agree-to-license --verbose

}

# @define Update temurin (lts)
update_temurin() {

	# Handle dependencies
	update_brew curl jq

	# Update package
	local version=$(curl -s "https://api.adoptium.net/v3/info/available_releases" | jq -r ".most_recent_lts")
	update_cask temurin@"$version"

}

# @define Update the-unarchiver
update_the_unarchiver() {

	# Update package
	local present="$([[ -d "/Applications/The Unarchiver.app" ]] && echo "true" || echo "false")"
	update_cask the-unarchiver

	# Finish install
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
	defaults write com.macpaw.site.theunarchiver AdditionalAnalyticsEnabled -integer 0
	defaults write com.macpaw.site.theunarchiver AnalyticsEnabled -integer 0
	defaults write com.macpaw.site.theunarchiver extractionDestination -integer 3
	defaults write com.macpaw.site.theunarchiver isFreshInstall -integer 1
	defaults write com.macpaw.site.theunarchiver RotatingBannerLastClosedDate "2099-12-31 23:59:59 +0000"
	defaults write com.macpaw.site.theunarchiver RotatingBannerLastShownDate "2099-12-31 23:59:59 +0000"
	defaults write com.macpaw.site.theunarchiver userAgreedToNewTOSAndPrivacy -integer 1


}

# @define Update transmission
update_transmission() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/P2P}
	local seeding=${2:-0.1}

	# Handle dependencies
	update_brew curl fileicon

	# Update package
	update_cask transmission

	# Change settings
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

# @define Update utm
update_utm() {

	# Handle dependencies
	update_brew curl fileicon

	# Update package
	update_cask utm

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/utm.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/UTM.app" "$picture" || sudo !!
}

# @define Update vesktop
update_vesktop() {

	# Update package
	local address="https://api.github.com/repos/Vencord/Vesktop/releases/latest"
	local version=$(scrape_website "$address" '"tag_name":\s*"\K([^"]+)' | tr -d -c '0-9.')
	[[ -z "$version" ]] && return 1
	local current=$(gather_version "/*ppl*/Vesktop*")
	autoload is-at-least
	local updated=$(is-at-least "$version" "$current" && echo "true" || echo "false")
	if [[ "$updated" == "false" ]]; then
		local address=$(scrape_website "$address" 'https://github\.com/[^"]+\.dmg')
		local package=$(mktemp -d)/$(basename "$address") && curl -LA "mozilla/5.0" "$address" -o "$package"
		hdiutil attach "$package" -noautoopen -nobrowse
		cp -R /Volumes/Veskt*/Vesktop.app /Applications
		sleep 4 && hdiutil detach /Volumes/Veskt*
		sudo xattr -rd com.apple.quarantine /Applications/Vesktop.app
	fi

}

# @define Update vscode
update_vscode() {

	# Handle dependencies
	update_brew jq sponge

	# Update package
	update_cask visual-studio-code

	# Update extensions
	code --install-extension "github.github-vscode-theme" --force

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

# @define Update webstorm
update_webstorm() {

	# Handle dependencies
	update_brew grep xmlstarlet

	# Update package
	local present="$([[ -d "/Applications/WebStorm.app" ]] && echo "true" || echo "false")"
	update_cask webstorm

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "WebStorm"; fi

	# TODO: Change settings

}

# @define Update xcode
update_xcode() {

	# Handle dependencies
	assert_apple_id || return 1
	update_brew cocoapods curl fileicon grep xcodesorg/made/xcodes

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

	# Change icons
	local address="https://github.com/olankens/machogen/raw/HEAD/assets/xcode.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "$starter" "$picture" || sudo !!

}

# @define Update youtube-music
update_youtube_music() {

	# Handle dependencies
	update_brew jq sponge

	# Update package
	update_cask th-ch/youtube-music/youtube-music

	# Change settings
	local configs="$HOME/Library/Application Support/YouTube Music/config.json"
	jq '.plugins."quality-changer".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."sponsorblock".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."synced-lyrics".enabled = true' "$configs" | sponge "$configs"
	# jq '.plugins."no-google-login".enabled = true' "$configs" | sponge "$configs"

}

# endregion

# region devtools

# @define Update android devtools
update_android_devtools() {

	# Handle dependencies
	update_android_cmdline
	update_android_studio

	# Update sdks
	yes | sdkmanager "cmdline-tools;latest"
	yes | sdkmanager "build-tools;34.0.0"
	yes | sdkmanager "emulator"
	yes | sdkmanager "platform-tools"
	yes | sdkmanager "platforms;android-34"
	yes | sdkmanager "sources;android-34"
	yes | sdkmanager "system-images;android-34;google_apis;arm64-v8a"
	yes | sdkmanager --licenses
	yes | sdkmanager --update

	# Create emulators
	avdmanager create avd -n "Pixel_3a_API_34" -d "pixel_3a" -k "system-images;android-34;google_apis;arm64-v8a" -f

	# Update plugins
	# studio installPlugins com.github.airsaid.androidlocalize
	"/Applications/Android Studio.app/Contents/MacOS/studio" installPlugins com.github.airsaid.androidlocalize

}

# @define Update angular devtools
update_angular_devtools() {
	
	# Handle dependencies
	update_chromium
	update_cursor
	update_intellij_idea
	update_nodejs
	update_vscode

	# Update chromium extensions
	# update_chromium_extension "ienfalfjdbdpebioblfackkekamfmbnh" # angular-devtools

	# Update cursor extensions
	cursor --install-extension "angular.ng-template" --force
	cursor --install-extension "bradlc.vscode-tailwindcss" --force
	cursor --install-extension "dbaeumer.vscode-eslint" --force
	cursor --install-extension "mikestead.dotenv" --force
	cursor --install-extension "usernamehw.errorlens" --force
	cursor --install-extension "yoavbls.pretty-ts-errors" --force

	# Update vscode extensions
	code --install-extension "angular.ng-template" --force
	code --install-extension "bradlc.vscode-tailwindcss" --force
	code --install-extension "dbaeumer.vscode-eslint" --force
	code --install-extension "mikestead.dotenv" --force
	code --install-extension "usernamehw.errorlens" --force
	code --install-extension "yoavbls.pretty-ts-errors" --force

	# Update intellij plugins
	idea installPlugins AngularJS # angular

	# Change cursor settings
	local configs="$HOME/Library/Application Support/Cursor/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit"' "$configs" | sponge "$configs"
	jq '."editor.defaultFormatter" = "dbaeumer.vscode-eslint"' "$configs" | sponge "$configs"
	jq '."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."eslint.format.enable" = true' "$configs" | sponge "$configs"

	# Change vscode settings
	local configs="$HOME/Library/Application Support/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit"' "$configs" | sponge "$configs"
	jq '."editor.defaultFormatter" = "dbaeumer.vscode-eslint"' "$configs" | sponge "$configs"
	jq '."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."eslint.format.enable" = true' "$configs" | sponge "$configs"

	# Update angular cli
	export NG_CLI_ANALYTICS="ci" && npm i -g @angular/cli
	ng analytics off

	# Change environment
	local configs="$HOME/.zshrc"
	if ! grep -q "ng completion script" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'autoload -Uz compinit && compinit' >>"$configs"
		echo 'source <(ng completion script)' >>"$configs"
		source "$configs"
	fi

}

# @define Update ionic devtools
update_ionic_devtools() {
	
	# Handle dependencies
	update_android_devtools
	update_angular_devtools
	update_ios_devtools

	# Update cursor extensions
	cursor --install-extension "WebNative.webnative" --force

	# Update vscode extensions
	code --install-extension "WebNative.webnative" --force

}

# @define Update ios devtools
update_ios_devtools() {
	
	# Handle dependencies
	update_xcode

	# Update xcode extensions
	update_cask swiftformat-for-xcode

}

# @define Update nest devtools
update_nest_devtools() {

	# Handle dependencies
	update_cursor
	update_intellij_idea
	update_nodejs
	update_vscode

	# Update cursor extensions
	cursor --install-extension "dbaeumer.vscode-eslint" --force
	cursor --install-extension "imgildev.vscode-nestjs-generator" --force
	cursor --install-extension "imgildev.vscode-nestjs-snippets-extension" --force
	cursor --install-extension "imgildev.vscode-nestjs-swagger-snippets" --force
	cursor --install-extension "mikestead.dotenv" --force
	cursor --install-extension "usernamehw.errorlens" --force
	cursor --install-extension "yoavbls.pretty-ts-errors" --force

	# Update vscode extensions
	code --install-extension "dbaeumer.vscode-eslint" --force
	code --install-extension "imgildev.vscode-nestjs-generator" --force
	code --install-extension "imgildev.vscode-nestjs-snippets-extension" --force
	code --install-extension "imgildev.vscode-nestjs-swagger-snippets" --force
	code --install-extension "mikestead.dotenv" --force
	code --install-extension "usernamehw.errorlens" --force
	code --install-extension "yoavbls.pretty-ts-errors" --force

	# Update intellij plugins
	idea installPlugins com.github.dinbtechit.jetbrainsnestjs # nestjs

	# Change cursor settings
	local configs="$HOME/Library/Application Support/Cursor/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit"' "$configs" | sponge "$configs"
	jq '."editor.defaultFormatter" = "dbaeumer.vscode-eslint"' "$configs" | sponge "$configs"
	jq '."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."eslint.format.enable" = true' "$configs" | sponge "$configs"

	# Change vscode settings
	local configs="$HOME/Library/Application Support/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit"' "$configs" | sponge "$configs"
	jq '."editor.defaultFormatter" = "dbaeumer.vscode-eslint"' "$configs" | sponge "$configs"
	jq '."editor.formatOnSave" = true' "$configs" | sponge "$configs"
	jq '."eslint.format.enable" = true' "$configs" | sponge "$configs"

}

# @define Update spring devtools
update_spring_devtools() {
	
	# Handle dependencies
	update_intellij_idea
	update_temurin
	update_vscode
	update_brew gradle maven

	# Update intellij plugins
	# idea installPlugins com.haulmont.jpab # jpa-buddy

	# Update vscode extensions
	code --install-extension "vmware.vscode-boot-dev-pack" --force
	code --install-extension "vscjava.vscode-java-pack" --force

}

# endregion

if [[ $ZSH_EVAL_CONTEXT != *:file ]]; then

	read -r -d "" welcome <<-EOD
	███╗░░░███╗░█████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
	████╗░████║██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
	██╔████╔██║███████║██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
	██║╚██╔╝██║██╔══██║██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
	██║░╚═╝░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
	╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD

	local country="Europe/Brussels"
	local machine="macintosh"
	local members=(
		"update_system"
		"update_android_studio"
		"update_chromium"
		"update_cursor"
		"update_intellij_idea"
		"update_webstorm"
		"update_vscode"
		"update_xcode"

		"update_awscli"
		"update_calibre"
		# "update_claude_code"
		"update_crossover"
		"update_docker"
		"update_figma"
		"update_git 'main' 'olankens' '173156207+olankens@users.noreply.github.com'"
		"update_github_cli"
		"update_jdownloader"
		"update_joal_desktop"
		"update_keepingyouawake"
		"update_kubernetes"
		"update_miniforge"
		"update_mpv"
		"update_nightlight"
		"update_nodejs"
		"update_notion"
		"update_obs"
		"update_pearcleaner"
		"update_postgresql"
		"update_temurin"
		"update_the_unarchiver"
		"update_transmission"
		"update_utm"
		"update_vesktop"
		"update_youtube_music"
		"update_android_devtools"
		"update_angular_devtools"
		"update_ionic_devtools"
		"update_ios_devtools"
		"update_nest_devtools"
		"update_spring_devtools"
		"update_appearance"
	)

	invoke_wrapper "$welcome" "$country" "$machine" "${members[@]}"

fi
