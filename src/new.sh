# !/bin/bash
# shellcheck shell=bash

# region services

# @define Appends application to the dock
# @params The application full path
append_dock_application() {
	local element=${1}
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

# @define Appends folder to the dock
# @params The folder full path
# @params The arrangement integer (1: name, 2: added, 3: modified, 4: created, 5: kind)
# @params The displayas integer (0: stack, 1: folder)
# @params The showas integer (0: automatic, 1: fan, 2: grid, 3: list)
append_dock_folder() {
	local element=${1}
	local arrangement=${2:-1}
	local display_as=${3:-0}
	local show_as=${4:-0}
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

# @define Asserts apple credentials from keychain
# @return 0 for success, 1 for failure
assert_apple_id() {
	local username=$(gather_password apple-username generic)
	local password=$(gather_password apple-password generic)
	[[ -z "$username" || -z "$password" ]] && return 1
	brew install xcodesorg/made/xcodes &>/dev/null
	export XCODES_USERNAME="$username"
	export XCODES_PASSWORD="$password"
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

# @define Asserts script is running with sudo privileges
# @return 0 for success, 1 for failure
assert_admin_execution() {
	[[ $EUID = 0 ]]
}

# @define Asserts sudo password from keychain
# @return 0 for success, 1 for failure
assert_admin_password() {
	local password=$(gather_password sudo-password generic)
	sudo -k && echo "$password" | sudo -S -v &>/dev/null
}

# @define Asserts current macos version
# @params The expected major macos version
# @return 0 for success, 1 for failure
assert_macos_version() {
	local version=${1:-14}
	[[ $(sw_vers -productVersion) =~ ^$version ]] || return 1
}

# @define Changes chromium download folder
# @params The download location full path
change_chromium_download() {
	local deposit=${1:-$HOME/Downloads/DDL}
	[[ -d "/Applications/Chromium.app" ]] || return 1
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

# @define Changes chromium search engine
# @params The pattern used to identify the engine in the list
change_chromium_engine() {
	# INFO: Google intentionally randomized and restricted access to search engine list to limit abuse
	# TODO: Use keystrokes and OCR to achieve
	# local pattern=${1:-duckduckgo}
	# [[ -d "/Applications/Chromium.app" ]] || return 1
	# killall "Chromium" 2>/dev/null && sleep 4
	# defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	# osascript <<-EOD
	# 	set starter to "/Applications/Chromium.app"
	# 	tell application starter
	# 		activate
	# 		reopen
	# 		delay 4
	# 		open location "chrome://settings/search"
	# 		delay 2
	# 		tell application "System Events"
	# 			repeat 2 times
	# 				key code 48
	# 			end repeat
	# 			delay 2
	# 			key code 49
	# 			delay 2
	# 			keystroke "${pattern}"
	# 			delay 2
	# 			key code 49
	# 		end tell
	# 		delay 2
	# 		quit
	# 		delay 2
	# 	end tell
	# EOD
}

# @define Changes chromium flag
# @params The chromium flag to change
# @params The payload value to set for the specified flag
change_chromium_flag() {
	local element=${1}
	local payload=${2}
	[[ -d "/Applications/Chromium.app" ]] || return 1
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

# @define Changes current shell privileges, requires user interaction
change_shell_security() {
	return 1
}

# @define Changes default web browser
# @params The browser name (chrome, chromium, firefox, safari, vivaldi, ...)
change_default_browser() {
	local browser=${1:-safari}
	update_brew defaultbrowser
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

# @define Changes desktop wallpaper
# @params The picture full path
change_desktop_wallpaper() {
	local picture=${1}
	osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$picture\""
}

# @define Changes system sleep settings by enabling or disabling sleeping
# @params True to restore default sleep settings or false to disable it
change_sleeping() {
	local enabled=${1:-true}
	if [[ "$enabled" == "true" ]]; then
		sudo pmset restoredefaults >/dev/null
	else
		sudo pmset -a displaysleep 0 && sudo pmset -a sleep 0
		(caffeinate -i -w $$ &) &>/dev/null
	fi
}

# @define Changes sudo timeouts by enabling or disabling the password prompt
# @params True to enable the timeouts or false to disable it
change_timeouts() {
	local enabled=${1:-true}
	if [[ "$enabled" == "true" ]]; then
		sudo rm /private/etc/sudoers.d/disable_timeout 2>/dev/null
	else
		echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /private/etc/sudoers.d/disable_timeout >/dev/null
	fi
}

# @define Changes system timezone
# @params The timezone string
change_timezone() {
	local payload=${1}
	sudo systemsetup -settimezone "$payload" &>/dev/null
}

# @define Expands archive
# @params The archive path or direct http url
# @params The deposit path for extraction
# @params The number of leading dirs to strip
# @return The extraction full path
expand_archive() {
	local archive=${1}
	local deposit=${2:-.}
	local leading=${3:-0}
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

# @define Gathers password from current user's keychain
# @params The service name
# @params The password variant (generic or internet)
# @return The gathered password or empty string
gather_password() {
	local service=${1}
	local variant=${2:-generic}
	security find-"$variant"-password -a "$USER" -s "$service" -w 2>/dev/null
}

# @define Gathers path
# @params The search pattern or directory
# @params The maximum depth for search
# @return The gathered full path
gather_pattern() {
	local pattern=${1}
	local maximum=${2:-0}
	echo "$(/bin/zsh -c "find $pattern -maxdepth $maximum" 2>/dev/null | sort -r | head -1)" || sudo !!
}

# @define Gathers installed application version
# @params The application full path
# @return The gathered version for success, 0.0.0.0 for failure
gather_version() {
	local apppath=${1}
	update_brew grep
	local starter=$(gather_pattern "$apppath/*ontents/*nfo.plist")
	local version=$(defaults read "$starter" CFBundleShortVersionString 2>/dev/null)
	echo "$version" | ggrep -oP "[\d.]+" || echo "0.0.0.0"
}

# @define Invokes application, wait for first window and close
# @params The application name
# @params The maximum wait time (seconds) for the window
invoke_once() {
	local appname=${1}
	local timeout=${2:-30}
	osascript <<-EOD
		set starter to "/Applications/${appname}.app"
		tell application starter
			activate
			reopen
			tell application "System Events"
				tell process "${appname}"
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

# @define Invokes functions with a welcome message and tracks time
# @params The welcome message to display at the start
# @params The functions to invoke in sequence
invoke_wrapper() {
	local welcome=${1}
	local members=("${@:2}")
	verify_executor || return 1
	clear && sudo -v && clear
	printf "\033]0;%s\007" "$(basename "$ZSH_ARGZERO" | cut -d . -f 1)"
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"
	change_timeouts false
	change_sleeping false
	# verify_computer || return 1
	verify_security || return 1
	# verify_homebrew || return 1
	# verify_apple_id || return 1
	change_timezone "Europe/Brussels"
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
	change_sleeping true
	change_timeouts true
	printf "\n"
}

# @define Scrapes data from website using regex pattern
# @params The address to scrape
# @params The pattern to evaluate against the scraped content
# @return The scraped string matching the provided regex pattern
scrape_website() {
	local address=${1}
	local pattern=${2}
	update_brew grep
	local content=$(curl -s "$address")
	local results=$(echo "$content" | ggrep -oP "$pattern" | head -n 1)
	echo "$results"
}

# @define Updates brew packages
# @params The brew package names
update_brew() {
	local payload=("$@")
	brew install "${payload[@]}"
	brew upgrade "${payload[@]}"
}

# @define Updates cask packages
# @params The cask package names
update_cask() {
	local payload=("$@")
	brew install --cask --no-quarantine "${payload[@]}"
	brew upgrade --cask --no-quarantine "${payload[@]}"
}

# @define Updates chromium extension
# @params The payload (crx url, zip url or extension uuid)
update_chromium_extension() {
	local payload=${1}
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

# @define Handles apple id credential verification in the keychain
# @return 0 for success, 1 for failure
verify_apple_id() {
	printf "\r\033[93m%s\033[00m" "CHECKING APPLE CREDENTIALS, PLEASE BE PATIENT"
	if ! assert_apple_id; then
		security delete-generic-password -s appmail &>/dev/null
		security delete-generic-password -s apppass &>/dev/null
		printf "\r\033[91m%s\033[00m\n\n" "APPLE CREDENTIALS NOT IN KEYCHAIN OR INCORRECT"
		printf "\r\033[92m%s\033[00m\n" "security add-generic-password -a \$USER -s appmail -w username"
		printf "\r\033[92m%s\033[00m\n\n" "security add-generic-password -a \$USER -s apppass -w password"
		return 1
	fi
}

# @define Handles verifying the macos version
# @return 0 for success, 1 for failure
verify_computer() {
	if assert_macos_version "14"; then
		printf "\r\033[91m%s\033[00m\n\n" "CURRENT MACOS VERSION (${"$(sw_vers -productVersion)":0:4}) IS NOT SUPPORTED"
		return 1
	fi
}

# @define Handle verifying the executor's privileges
# @return 0 for success, 1 for failure
verify_executor() {
	if assert_admin_execution; then
		printf "\r\033[91m%s\033[00m\n\n" "EXECUTING THIS SCRIPT AS ROOT IS NOT ADMITTED"
		return 1
	fi
}

# @define Handles upgrading and configuring homebrew
# @return 0 for success, 1 for failure
verify_homebrew() {
	printf "\r\033[93m%s\033[00m" "UPGRADING HOMEBREW PACKAGE, PLEASE BE PATIENT"
	local command=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
	CI=1 /bin/bash -c "$command" &>/dev/null
	local configs="$HOME/.zprofile"
	if ! grep -q "/opt/homebrew/bin/brew shellenv" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$configs"
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi
	brew cleanup &>/dev/null
	return 0
}

# @define Handles current shell privileges, requires user interaction 
# @return 0 for success, 1 for failure
verify_security() {
	printf "\r\033[93m%s\033[00m" "CHANGING SECURITY, PLEASE FOLLOW THE MESSAGES"
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

# @define Updates android-cmdline
update_android_cmdline() {
	update_brew curl grep jq
	update_temurin

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

# @define Updates android-studio
update_android_studio() {
	update_brew grep xmlstarlet
	local present="$([[ -d "/Applications/Android Studio.app" ]] && echo true || echo false)"
	update_cask android-studio

	if [[ "$present" == "false" ]]; then invoke_once "Android Studio"; fi
}

# @define Updates appearance
update_appearance() {
	defaults delete com.apple.dock persistent-apps
	defaults delete com.apple.dock persistent-others
	append_dock_application "/Applications/Chromium.app"
	append_dock_application "/Applications/JDownloader 2/JDownloader2.app"
	append_dock_application "/Applications/NetNewsWire.app"
	append_dock_application "/Applications/Vesktop.app"
	append_dock_application "/Applications/Notion.app"
	append_dock_application "/Applications/Visual Studio Code.app"
	append_dock_application "/Applications/Android Studio.app"
	append_dock_application "/Applications/Xcode.app"
	append_dock_application "/Applications/IntelliJ IDEA.app"
	append_dock_application "/Applications/Fork.app"
	append_dock_application "/Applications/Tower.app"
	append_dock_application "/Applications/MQTTX.app"
	append_dock_application "/Applications/Insomnia.app"
	append_dock_application "/Applications/Figma.app"
	append_dock_application "/Applications/OBS.app"
	append_dock_application "/Applications/Mpv.app"
	append_dock_application "/Applications/YouTube Music.app"
	append_dock_application "/Applications/Calibre.app"
	append_dock_application "/Applications/Whisky.app"
	append_dock_application "/Applications/Pearcleaner.app"
	append_dock_application "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
	append_dock_application "/System/Applications/Utilities/Terminal.app"
	killall Dock
	# TODO: Update the wallpapers
}

# @define Updates awscli
update_awscli() {
	update_brew awscli
}

# @define Updates calibre
update_calibre() {
	update_brew curl fileicon
	update_cask calibre
	mv -f /Applications/calibre.app /Applications/Calibre.app

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/calibre.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Calibre.app" "$picture" || sudo !!
}

# @define Updates chromium
update_chromium() {
	#TODO
}

# @define Updates docker
update_docker() {
	update_brew colima docker docker-compose jq sponge
	colima start

	local configs="$HOME/.docker/config.json"
	jq '. + {cliPluginsExtraDirs: ["/opt/homebrew/lib/docker/cli-plugins"]}' "$configs" | sponge "$configs"
}

# @define Updates eid_belgium
update_eid_belgium() {
	#TODO
}

# @define Updates figma
update_figma() {
	update_brew jq sponge
	update_cask figma

	local configs="$HOME/Library/Application Support/Figma/settings.json"
	jq '.showFigmaInMenuBar = false' "$configs" | sponge "$configs"
}

# @define Updates git
update_git() {
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}
	update_brew git

	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail"
	[[ -n "$gituser" ]] && git config --global user.name "$gituser"
	git config --global checkout.workers 0
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global push.autoSetupRemote true
}

# @define Updates git
update_github_cli() {
	update_brew gh
}

# @define Updates insomnia
update_insomnia() {
	update_cask insomnia
}

# @define Updates intellij
update_intellij() {
	local present=$([[ -d "/Applications/IntelliJ IDEA.app" ]] && echo "true" || echo "false")
	update_cask intellij-idea

	if [[ "$present" == "false" ]]; then invoke_once "IntelliJ IDEA"; fi
}

# @define Updates jdownloader
update_jdownloader() {
	local deposit=${1:-$HOME/Downloads/JD2}
	update_brew coreutils curl fileicon jq
	local present=$([[ -d "/Applications/JDownloader 2/JDownloader2.app" ]] && echo "true" || echo "false")
	update_cask jdownloader

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

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/jdownloader.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/JDownloader 2/JDownloader2.app" "$picture" || sudo !!
	fileicon set "/Applications/JDownloader 2/Uninstall JDownloader.app" "$picture" || sudo !!
	cp "$picture" "/Applications/JDownloader 2/JDownloader2.app/Contents/Resources/app.icns"
	local sitting="/Applications/JDownloader 2/themes/standard/org/jdownloader/images/logo/jd_logo_128_128.png"
	sips -Z 128 -s format png "$picture" --out "$sitting"
}

# @define Updates miniforge
update_miniforge() {
	update_cask miniforge

	conda init zsh
	conda config --set auto_activate_base false
}

# @define Updates mpv
update_mpv() {
	update_brew curl fileicon yt-dlp
	update_cask mpv
	mv -f /Applications/mpv.app /Applications/Mpv.app

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

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/mpv.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Mpv.app" "$picture" || sudo !!
}

# @define Updates nightlight
update_nightlight() {
	local percent=${1:-75}
	local forever=${2:-true}
	update_brew smudge/smudge/nightlight

	[[ "$forever" == "true" ]] && nightlight schedule 3:00 2:59
	nightlight temp "$percent" && nightlight on
}

# @define Updates nodejs
update_nodejs() {
	update_brew grep jq
	local address="https://raw.githubusercontent.com/scoopinstaller/main/master/bucket/nodejs-lts.json"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq '.version' | ggrep -oP "[\d]+" | head -1)
	update_brew node@"$version"

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

# @define Updates notion
update_notion() {
	update_brew curl fileicon
	update_cask notion

	local configs="$HOME/Library/Application Support/Notion/state.json"
	mkdir -p "$(dirname $configs)"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '.appState.preferences.isMenuBarIconEnabled = false' "$configs" | sponge "$configs"
	jq '.appState.preferences.isAutoUpdaterDisabled = true' "$configs" | sponge "$configs"

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/notion.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/Notion.app" "$picture" || sudo !!
}

# @define Updates obs
update_obs() {
	update_brew curl fileicon
	update_cask obs

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/obs.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/OBS.app" "$picture" || sudo !!
}

# @define Updates pearcleaner
update_pearcleaner() {
	update_cask pearcleaner
}

# @define Updates postgresql
update_postgresql() {
	local version=${1:-14}

	# INFO: Default credentials are $USER with empty password
	brew install postgresql@"$version"
	brew upgrade postgresql@"$version"
	brew services restart postgresql@"$version"
}

# @define Updates system
update_system() {
	local machine=${1:-macintosh}

	sudo scutil --set ComputerName "$machine"
	sudo scutil --set HostName "$machine"
	sudo scutil --set LocalHostName "$machine"
	sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$machine"

	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	defaults write com.apple.finder ShowPathbar -bool true

	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

	defaults write com.apple.Preview NSRecentDocumentsLimit 0
	defaults write com.apple.Preview NSRecentDocumentsLimit 0

	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
	defaults write com.apple.LaunchServices "LSQuarantine" -bool false

	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
	/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

	find ~ -name ".DS_Store" -delete

	sudo nvram StartupMute=%01

	/usr/sbin/softwareupdate --install-rosetta --agree-to-license &>/dev/null

	# INFO: Takes ages
	# sudo softwareupdate --download --all --force --agree-to-license --verbose
}

# @define Updates temurin (lts)
update_temurin() {
	update_brew curl grep jq
	local version=$(curl -s "https://api.adoptium.net/v3/info/available_releases" | jq -r ".most_recent_lts")
	update_cask temurin@"$version"
}

# @define Updates the-unarchiver
update_the_unarchiver() {
	local present=$([[ -d "/Applications/The Unarchiver.app" ]] && echo "true" || echo "false")
	update_cask the-unarchiver

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

	defaults write com.macpaw.site.theunarchiver extractionDestination -integer 3
	defaults write com.macpaw.site.theunarchiver isFreshInstall -integer 1
	defaults write com.macpaw.site.theunarchiver userAgreedToNewTOSAndPrivacy -integer 1
}

# @define Updates utm
update_utm() {
	update_brew curl fileicon
	update_cask utm

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/utm.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "/Applications/UTM.app" "$picture" || sudo !!
}

# @define Updates vesktop
update_vesktop() {
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

# @define Updates vscode
update_vscode() {
	update_brew jq sponge
	update_cask visual-studio-code

	code --install-extension "github.github-vscode-theme" --force

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

# @define Updates whisky
update_whisky() {
	update_cask whisky
}

# @define Updates xcode
update_xcode() {
	assert_apple_id || return 1
	update_brew cocoapods curl fileicon grep xcodesorg/made/xcodes

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

	local address="https://github.com/olankens/machogen/raw/HEAD/assets/xcode.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "$starter" "$picture" || sudo !!
}

# @define Updates youtube-music
update_youtube_music() {
	update_brew jq sponge
	update_cask th-ch/youtube-music/youtube-music

	local configs="$HOME/Library/Application Support/YouTube Music/config.json"
	jq '.plugins."quality-changer".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."sponsorblock".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."synced-lyrics".enabled = true' "$configs" | sponge "$configs"
	# jq '.plugins."no-google-login".enabled = true' "$configs" | sponge "$configs"
}

# @define Updates android devtools
update_android_devtools() {
	update_android_cmdline
	update_android_studio
	yes | sdkmanager "build-tools;34.0.0"
	yes | sdkmanager "emulator"
	yes | sdkmanager "platform-tools"
	yes | sdkmanager "platforms;android-34"
	yes | sdkmanager "sources;android-34"
	yes | sdkmanager "system-images;android-34;google_apis;arm64-v8a"
	yes | sdkmanager --licenses
	yes | sdkmanager --update
	avdmanager create avd -n "Pixel_3a_API_34" -d "pixel_3a" -k "system-images;android-34;google_apis;arm64-v8a" -f
	studio installPlugins com.github.airsaid.androidlocalize
}

# @define Updates angular devtools
update_angular_devtools() {}

# @define Updates spring devtools
update_spring_devtools() {}

# endregion

# @define Handles main script logic
main() {
	read -r -d "" welcome <<-EOD
	███╗░░░███╗░█████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
	████╗░████║██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
	██╔████╔██║███████║██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
	██║╚██╔╝██║██╔══██║██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
	██║░╚═╝░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
	╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	local members=(
		"update_calibre"
		"update_mpv"
		"update_vesktop"
		"update_appearance"
	)
	invoke_wrapper "$welcome" "${members[@]}"
}

# admin=$(assert_admin_execution && echo true || echo false)
# echo $admin
# change_chromium_download "$HOME/Downloads/DDL"
# change_chromium_flag "custom-ntp" "about:blank"
# change_chromium_flag "extension-mime-request-handling" "always"
# change_chromium_flag "remove-tabsearch-button" "enabled"
# change_chromium_flag "show-avatar-button" "never"
main "$@"
