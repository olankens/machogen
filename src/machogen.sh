#!/bin/zsh

# shellcheck shell=bash
# shellcheck disable=SC1091,SC2005,SC2012,SC2015,SC2016,SC2059,SC2125,SC2128,SC2129,SC2155,SC2178

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

# @define Assert current user is signed in with an apple account
# @return 0 for success, 1 for failure
assert_apple_id() {

	# Gather window title from apple id preference pane
	results=$(
		osascript <<-EOF
			do shell script "open 'x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane'"
			delay 2
			tell application "System Events" to tell process "System Settings" to return (value of every static text of window 1) as string
		EOF
	)

	# Finish the system settings application
	osascript -e 'tell application "System Settings" to quit'

	# Verify if there was sign in in the windows title
	[[ "$results" == *"Sign in"* ]] && return 1 || return 0

}

# @define Assert script is running with sudo privileges
# @return 0 for success, 1 for failure
assert_admin_execution() {

	# Verify privileges
	[[ $EUID = 0 ]]

}

# @define Change application icon
# @params The distant icon name from repository
# @params The application full path
change_appicon() {

	# Handle dependencies
	update_brew curl fileicon

	# Handle parameters
	local distant=${1}
	local apppath=${2}

	# Change icon
	local address="https://github.com/olankens/machogen/raw/HEAD/.assets/icons/$distant.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	fileicon set "$apppath" "$picture"

}

# @define Change chromium download folder
# @params The download location full path
# @params The user-data-dir full path, empty for default one
change_chromium_download() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local datadir=${2}

	# Ensure presence
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# Change deposit
	defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	mkdir -p "$deposit" && killall "Chromium" 2>/dev/null && sleep 4
	osascript <<-EOD
		do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
		delay 4
		tell application "Chromium"
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
# @params The user-data-dir full path, empty for default one
change_chromium_engine() {

	# INFO: Google intentionally randomized and restricted access to search engine list
	# IDEA: Use keystrokes with OCR to achieve it
	return 1

	# Handle parameters
	# local pattern=${1:-duckduckgo}
	# local datadir=${2}
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# # Change search engine
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

# @define Change chromium flag
# @params The chromium flag to change
# @params The payload value to set for the specified flag
# @params The user-data-dir full path, empty for default one
change_chromium_flag() {

	# Handle parameters
	local element=${1}
	local payload=${2}
	local datadir=${3}

	# Ensure presence
	[[ -d "/Applications/Chromium.app" ]] || return 1

	# Change flag
	defaults write org.chromium.Chromium AppleLanguages "(en-US)"
	killall "Chromium" 2>/dev/null && sleep 4
	if [[ "$element" == "custom-ntp" ]]; then
		osascript <<-EOD
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
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
	elif [[ "$element" == "enable-force-dark" ]]; then
		osascript <<-EOD
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "enable-force-dark"
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
	elif [[ "$element" = "extension-disable-unsupported-developer-mode-extensions" ]]; then
		osascript <<-EOD
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
				activate
				reopen
				delay 4
				open location "chrome://flags/"
				delay 2
				tell application "System Events"
					keystroke "extension-disable-unsupported-developer-mode-extensions"
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
	elif [[ "$element" == "extension-mime-request-handling" ]]; then
		osascript <<-EOD
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
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
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
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
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
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

# @define Change chromium default profile theme
# @params The number of times to press the right arrow key
# @params The user-data-dir full path, empty for default one
change_chromium_theme() {

	# Handle parameters
	local repeats=${1:-0}
	local datadir=${2}

	# # Change theme
	killall "Chromium" 2>/dev/null && sleep 4
	osascript <<-EOD
		do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
		delay 4
		tell application "Chromium"
			activate
			reopen
			delay 4
			open location "chrome://settings/manageProfile"
			delay 2
			tell application "System Events"
				repeat 2 times
					key code 48
				end repeat
				repeat $repeats times
					key code 124
				end repeat
				delay 2
				key code 49
			end tell
			delay 2
			quit
			delay 2
		end tell
	EOD

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

# @define Change default wallpaper
# @params The url of the wallpaper to download
# @params The full path of the downloaded wallpaper
change_wallpaper() {

	# Handle dependencies
	update_brew curl

	# Handle parameters
	local address=${1}
	local picture=${2}

	# Change wallpaper
	# local address="https://github.com/olankens/machogen/raw/HEAD/.assets/walls/$distant.heic"
	# local picture="$HOME/Pictures/Wallpapers/$(basename "$address")"
	rm -v "$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
	killall WallpaperAgent
	mkdir -p "$(dirname "$picture")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$picture\""

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

# @define Gather path using find command
# @params The search pattern or directory path
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
		tell application "/Applications/${appname}.app"
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
	sudo -v
	local results=$?
	printf "\n"
	[[ $results -ne 0 ]] && return 1
	clear && printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove timeouts
	change_timeouts false

	# Remove sleeping
	change_sleeping false

	# Verify requirements
	verify_security || return 1
	verify_apple_id || return 1

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

	# Update packages
	brew install --cask --no-quarantine "${payload[@]}"
	brew upgrade --cask --no-quarantine "${payload[@]}"

}

# @define Update chromium extension
# @params The payload (crx url or extension uuid)
# @params The user-data-dir full path, empty for default one
# @params Maximum age in seconds before extension is considered outdated (default: 2592000)
update_chromium_extension() {

	# Handle parameters
	local payload=${1}
	local datadir=${2:-$HOME/Library/Application Support/Chromium}
	local maximum=${3:-2592000}

	# Verify presence
	[[ ! -d "/Applications/Chromium.app" ]] && return 1

	# Verify outdated
	if [[ ${payload:0:4} == "http" ]] && [[ "$payload" == *.crx ]]; then
		local package=$(mktemp) && curl -LA "mozilla/5.0" "$payload" -o "$package" || return 1
		local key=$(python3 -c "import zipfile,json;print(zipfile.ZipFile('$package').open('manifest.json').read().decode().split('\"key\": \"')[1].split('\"')[0] if 'key' in zipfile.ZipFile('$package').open('manifest.json').read().decode() else '')" 2>/dev/null)
		local uuid=$(python3 -c "import base64,hashlib;h=hashlib.sha256(base64.b64decode('$key')).digest()[:16];a='abcdefghijklmnop';print(''.join([a[b>>4&0xF]+a[b&0xF] for b in h])[:32])" 2>/dev/null)
		[[ $(stat -f %B "$datadir/Default/Extensions/$uuid"/*/manifest.json 2>/dev/null | head -n1) -gt $(($(date +%s) - maximum)) ]] && return 0
	elif [[ ${payload:0:4} != "http" ]]; then
		local configs=$(ls -1t "$datadir/Default/Extensions/$payload"/*/manifest.json 2>/dev/null | head -n1)
		[[ $(stat -f %B "$configs" 2>/dev/null) -gt $(($(date +%s) - maximum)) ]] && return 0
	fi

	# Create address
	if [[ ${payload:0:4} != "http" ]]; then
		local version=$(defaults read "/Applications/Chromium.app/Contents/Info" CFBundleShortVersionString)
		local baseurl="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
		local payload="${baseurl}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
	fi

	# Update extension
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	osascript <<-EOD
		do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
		delay 4
		tell application "Chromium"
			activate
			reopen
			delay 4
			open location "$payload"
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

}

# @define Handle apple id presence verification
# @return 0 for success, 1 for failure
verify_apple_id() {

	printf "\r\033[K"
	printf "\r\033[93m%s\033[00m" "VERIFYING APPLE ID PRESENCE, BE PATIENT"
	if ! assert_apple_id; then
		printf "\r\033[91m%s\033[00m\n\n" "NO APPLE ID ACCOUNT FOUND, PLEASE LOGIN"
		osascript -e 'tell application "App Store" to activate'
		osascript -e "tell application \"${TERM_PROGRAM//Apple_/}\" to activate"
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

# @define Handle current shell privileges, requires user interaction
# @return 0 for success, 1 for failure
verify_security() {

	printf "\r\033[K"
	printf "\r\033[93m%s\033[00m" "VERIFYING TERMINAL SECURITY, FOLLOW DIALOGS"
	# allowed() { osascript -e 'tell application "System Events" to log ""' &>/dev/null; }
	capable() { osascript -e 'tell application "System Events" to key code 60' &>/dev/null; }
	granted() { ls "$HOME/Library/Messages" &>/dev/null; }
	display() {
		heading=$(basename "$ZSH_ARGZERO" | cut -d . -f 1)
		osascript <<-EOD &>/dev/null
			tell application "${TERM_PROGRAM//Apple_/}"
				display alert "$heading" message "$1" as informational giving up after 10
			end tell
		EOD
	}
	# while ! allowed; do
	# 	display "You have to tap the OK button to continue."
	# 	tccutil reset AppleEvents &>/dev/null
	# done
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
	if ! grep -q "ANDROID_HOME" "$HOME/.zshrc" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || printf "#!/bin/zsh" >"$HOME/.zshrc"
		perl -i -0777 -pe "s/\n*\z/\n/s" "$HOME/.zshrc" 2>/dev/null || true
		printf "\n%s" "# Append android sdk tools to path" >>"$HOME/.zshrc"
		printf "\n%s" 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >>"$HOME/.zshrc"
		printf "\n%s" 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$HOME/.zshrc"
		printf "\n%s" 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$HOME/.zshrc"
		printf "\n%s\n" 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

}

# @define Update android-studio
update_android_studio() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}

	# Handle dependencies
	update_brew grep xmlstarlet

	# Update package
	local present="$([[ -d "/Applications/Android Studio.app" ]] && echo true || echo false)"
	update_cask android-studio

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "Android Studio"; fi

	# Change theme
	local configs=$(find "$HOME/Library/Application Support/Google/AndroidStudio"*/options -name "laf.xml" 2>/dev/null | sort -r | head -1)
	if [[ -f "$configs" ]]; then
		xmlstarlet ed -L -u "//component[@name='LafManager']/laf/@themeId" -v "Islands Dark" "$configs" 2>/dev/null ||
			xmlstarlet ed -L -s "//application" -t elem -n "component" -v "" \
				-i "//component[not(@name)]" -t attr -n "name" -v "LafManager" \
				-s "//component[@name='LafManager']" -t elem -n "laf" -v "" \
				-i "//laf[not(@themeId)]" -t attr -n "themeId" -v "Islands Dark" \
				"$configs" 2>/dev/null
	fi

	# Change scheme
	local configs=$(find "$HOME/Library/Application Support/Google/AndroidStudio"*/options -name "colors.scheme.xml" 2>/dev/null | sort -r | head -1)
	if [[ -f "$configs" ]]; then
		xmlstarlet ed -L -u "//component[@name='EditorColorsManagerImpl']/global_color_scheme/@name" -v "Islands Dark" "$configs" 2>/dev/null ||
			xmlstarlet ed -L -s "//application" -t elem -n "component" -v "" \
				-i "//component[not(@name)]" -t attr -n "name" -v "EditorColorsManagerImpl" \
				-s "//component[@name='EditorColorsManagerImpl']" -t elem -n "global_color_scheme" -v "" \
				-i "//global_color_scheme" -t attr -n "name" -v "Islands Dark" \
				"$configs" 2>/dev/null
	fi

	# Change appearance
	change_appicon "android-studio" "/Applications/Android Studio.app"

}

# @define Update appearance
update_appearance() {

	# Enable dark theme
	osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

	# Enable dark icons
	osascript <<-EOF
		tell application "System Settings"
			activate
			delay 1
		end tell
		tell application "System Events"
			tell process "System Settings"
				click menu item "Appearance" of menu "View" of menu bar 1
				delay 2
				tell window "Appearance"
					click button 2 of group 3 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1
				end tell
			end tell
		end tell
		quit application "System Settings"
	EOF

	# Remove tinted windows
	osascript <<-EOF
		tell application "System Settings"
			activate
			delay 1
		end tell
		tell application "System Events"
			tell process "System Settings"
				click menu item "Appearance" of menu "View" of menu bar 1
				delay 2
				tell window "Appearance"
					set theCheckbox to checkbox "Tint window background with wallpaper color" of group 4 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1
					if value of theCheckbox is 1 then
						click theCheckbox
					end if
				end tell
			end tell
		end tell
		quit application "System Settings"
	EOF

	# Change dock settings
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0
	defaults write com.apple.dock autohide-time-modifier -float 0.25
	defaults write com.apple.dock minimize-to-application -bool true
	defaults write com.apple.dock orientation bottom
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.dock size-immutable -bool yes
	defaults write com.apple.dock tilesize -int 40
	defaults write com.apple.dock wvous-bl-corner -int 0
	defaults write com.apple.dock wvous-br-corner -int 0
	defaults write com.apple.dock wvous-tl-corner -int 0
	defaults write com.apple.dock wvous-tr-corner -int 0

	# Remove dock elements
	defaults delete com.apple.dock persistent-apps
	defaults delete com.apple.dock persistent-others

	# Append network elements
	# append_dock_application "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
	append_dock_application "/Applications/Chromium.app"
	# append_dock_application "/Applications/Google Chrome.app"
	append_dock_application "/Applications/JDownloader 2/JDownloader2.app"
	# append_dock_application "/Applications/JoalDesktop.app"
	append_dock_application "/Applications/NetNewsWire.app"
	append_dock_application "/Applications/Transmission.app"

	# Append finance elements
	# append_dock_application "/Applications/IBKR Desktop.app"

	# Append social elements
	append_dock_application "/Applications/Discord.app"
	# append_dock_application "/Applications/Telegram.app"

	# Append office elements
	append_dock_application "/Applications/Calibre.app"
	append_dock_application "/Applications/Notion.app"

	# Append development elements
	append_dock_application "/Applications/Android Studio.app"
	append_dock_application "/Applications/Conductor.app"
	# append_dock_application "/Applications/Fork.app"
	# append_dock_application "/Applications/Hoppscotch.app"
	append_dock_application "/Applications/IntelliJ IDEA.app"
	# append_dock_application "/Applications/MQTTX.app"
	append_dock_application "/Applications/VSCodium.app"
	append_dock_application "/Applications/Xcode.app"

	# Append graphics elements
	append_dock_application "/Applications/ComfyUI.app"
	append_dock_application "/Applications/Icon Composer.app"
	append_dock_application "/Applications/Figma.app"
	# append_dock_application "/Applications/Frame0.app"

	# Append audio and video elements
	append_dock_application "/Applications/CapCut.app"
	append_dock_application "/Applications/DaVinci Resolve.app"
	append_dock_application "/Applications/OBS.app"

	# Append multimedia elements
	append_dock_application "/Applications/IINA.app"
	append_dock_application "/Applications/YouTube Music.app"

	# Append gaming elements
	append_dock_application "/Applications/CrossOver.app"

	# Append utility elements
	append_dock_application "/Applications/Pearcleaner.app"
	append_dock_application "/Applications/UTM.app"
	append_dock_application "/System/Applications/Utilities/Terminal.app"

	# Append downloads folder
	append_dock_folder "$HOME/Downloads" 1 1 2

	# Append documents folder
	append_dock_folder "$HOME/Documents" 1 1 2

	# Change wallpaper
	local address="https://github.com/olankens/codewall/raw/HEAD/src/node-01.avif"
	local picture="$HOME/Pictures/Wallpapers/$(basename "$address")"
	change_wallpaper "$address" "$picture"

	# Reload dock
	killall Dock

}

# @define Update calibre
update_calibre() {

	# Update package
	update_cask calibre

	# Finish install
	invoke_once "calibre"

	# Update goodreads
	# TODO: Scrape the latest version from github api
	local program="/Applications/calibre.app/Contents/MacOS/calibre-customize"
	local address="https://github.com/kiwidude68/calibre_plugins/releases/download/goodreads-v1.8.3/goodreads-v1.8.3.zip"
	local archive=$(mktemp -d)/$(basename "$address") && curl -LA "mozilla/5.0" "$address" -o "$archive"
	"$program" --add-plugin "$archive"
	"$program" --enable-plugin "Goodreads"

	# Change appearance
	sudo /usr/libexec/PlistBuddy -c "Set :CFBundleName Calibre" /Applications/calibre.app/Contents/Info.plist 2>/dev/null
	sudo /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Calibre" /Applications/calibre.app/Contents/Info.plist 2>/dev/null
	sudo xattr -cr /Applications/calibre.app
	sudo codesign --remove-signature /Applications/calibre.app
	sudo codesign --deep --sign - /Applications/calibre.app
	sudo mv /Applications/calibre.app /Applications/Calibre.app
	change_appicon "calibre" "/Applications/Calibre.app"

}

# @define Update capcut
update_capcut() {

	# Handle dependencies
	update_brew mas

	# Update package
	mas install 1500855883
	mas upgrade 1500855883

	# Change appearance
	local address="https://github.com/olankens/machogen/raw/HEAD/.assets/icons/capcut.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	sudo fileicon set "/Applications/CapCut.app" "$picture"

}

# @define Update chromium
update_chromium() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local tabpage=${2:-about:blank}
	local pattern=${3:-duckduckgo}
	local datadir=${4}

	# Handle dependencies
	update_brew coreutils curl jq

	# Update package
	local present=$([[ (-n "$datadir" && -d "$datadir") || (-z "$datadir" && -d "/Applications/Chromium.app") ]] && echo true || echo false)
	update_cask ungoogled-chromium
	killall Chromium || true

	# Change default
	change_default_browser "chromium"

	# Create datadir
	[[ -n "$datadir" ]] && mkdir -p "$datadir"

	# Finish install
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
		change_chromium_download "$deposit" "$datadir"
		change_chromium_engine "$pattern" "$datadir"
		change_chromium_flag "custom-ntp" "$tabpage" "$datadir"
		[[ -z "$datadir" ]] && change_chromium_flag "enable-force-dark" "enabled with selective image inversion based on" "$datadir"
		change_chromium_flag "extension-disable-unsupported-developer-mode-extensions" "disabled" "$datadir"
		change_chromium_flag "extension-mime-request-handling" "always" "$datadir"
		change_chromium_flag "remove-tabsearch-button" "enabled" "$datadir"
		change_chromium_flag "show-avatar-button" "never" "$datadir"

		# Toggle bookmarks
		osascript <<-EOD
			do shell script "open -na '/Applications/Chromium.app' --args --user-data-dir='$datadir'"
			delay 4
			tell application "Chromium"
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
		update_chromium_extension "$address" "$datadir"

	fi

	# Update extensions
	if [[ -z "$datadir" ]]; then
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		# update_chromium_extension "mgpdnhlllbpncjpgokgfogidhoegebod" # photoshow
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "nngceckbapebfimnlniiiahkandclblb" # bitwarden-password-manage
		# update_chromium_extension "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass-paywalls-chrome-clean-master.zip"
		update_chromium_extension "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass-paywalls-chrome-clean-latest.crx"
	fi

	# Change appearance
	change_appicon "chromium" "/Applications/Chromium.app"

}

# @define Update chromium-developer
update_chromium_developer() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local tabpage=${2:-about:blank}
	local pattern=${3:-duckduckgo}
	local datadir=${4:-$HOME/Library/Application Support/Chromium/Developer}

	# Update package
	local present=$([[ (-n "$datadir" && -d "$datadir") || (-z "$datadir" && -d "/Applications/Chromium.app") ]] && echo true || echo false)
	update_chromium "$deposit" "$tabpage" "$pattern" "$datadir"

	# Change theme
	[[ "$present" == "false" ]] && change_chromium_theme 8 "$datadir" # citron

	# Update extensions
	update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" "$datadir" # json-formatter
	update_chromium_extension "blipmdconlkpinefehnmjammfjpmpbjk" "$datadir" # lighthouse
	update_chromium_extension "bjogjfinolnhfhkbipphpdlldadpnmhc" "$datadir" # seo-meta-in-1-click

}

# @define Update claude-code
update_claude_code() {

	# Handle dependencies
	update_nodejs

	# Update package
	npm install -g @anthropic-ai/claude-code

	# Change settings
	local configs="$HOME/.claude/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '.includeCoAuthoredBy = false' "$configs" | sponge "$configs"

}

# @define Update comfyui
update_comfyui() {

	# Update package
	update_cask comfyui

	# Change appearance
	change_appicon "comfyui" "/Applications/ComfyUI.app"

}

# @define Update conductor
update_conductor() {

	# Update package
	update_cask conductor

	# Change appearance
	change_appicon "conductor" "/Applications/Conductor.app"

}

# @define Update crossover
update_crossover() {

	# Update package
	update_cask crossover

	# Change settings
	defaults write com.codeweavers.CrossOver AskForRatings -bool false
	defaults write com.codeweavers.CrossOver SUAutomaticallyUpdate -bool false
	defaults write com.codeweavers.CrossOver SUEnableAutomaticChecks -bool false
	defaults write com.codeweavers.CrossOver SUHasLaunchedBefore -bool true

	# Finish install
	invoke_once "CrossOver"
	local bottles=("$HOME/Library/Application Support/CrossOver/Bottles"/*)
	while true; do
		pids=$(pgrep -f "CrossOver")
		[ -z "$pids" ] && break
		kill -9 "$pids" >/dev/null 2>&1
		sleep 4
	done
	local configs="$HOME/Library/Preferences/com.codeweavers.CrossOver.plist"
	while /usr/libexec/PlistBuddy -c "Print :FirstRunDate" "$configs" &>/dev/null; do
		defaults delete com.codeweavers.CrossOver FirstRunDate
		plutil -remove FirstRunDate "$configs" &>/dev/null
		sleep 2
	done
	IFS=$'\n'
	find "$bottles" -type d -maxdepth 0 -print0 | while IFS= read -r -d '' i; do
		[ -d "$i" ] || continue
		while grep -q '\[Software\\\\CodeWeavers\\\\CrossOver\\\\cxoffice\]' "$i/system.reg"; do
			sed -i '' '/\[Software\\\\CodeWeavers\\\\CrossOver\\\\cxoffice\].*/,+5d' "$i/system.reg"
			sleep 1
		done
	done

	# Change appearance
	change_appicon "crossover" "/Applications/CrossOver.app"

}

# @define Update davinci-resolve
update_davinci_resolve() {

	# Handle dependencies
	update_brew mas

	# Update package
	mas install 571213070
	mas upgrade 571213070

	# Change appearance
	local address="https://github.com/olankens/machogen/raw/HEAD/.assets/icons/davinci-resolve.icns"
	local picture="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$picture"
	sudo fileicon set "/Applications/DaVinci Resolve.app" "$picture"

}

# @define Update discord
update_discord() {

	# Update package
	update_cask discord

	# Change appearance
	change_appicon "discord" "/Applications/Discord.app"

}

# @define Update docker
update_docker() {

	# Handle dependencies
	update_brew colima docker-buildx docker-compose jq sponge

	# Update package
	update_brew docker

	# Finish install
	colima start && colima stop

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

	# Change appearance
	change_appicon "figma" "/Applications/Figma.app"

}

# @define Update flutter
update_flutter() {

	# Update dependencies
	update_brew dart

	# Update package
	update_cask flutter

	# Finish install
	flutter precache && flutter upgrade
	dart --disable-analytics
	flutter config --no-analytics
	yes | flutter doctor --android-licenses

	# Change environment
	local altered="$(grep -q "CHROME_EXECUTABLE" "$HOME/.zshrc" >/dev/null 2>&1 && echo "true" || echo "false")"
	local present="$([[ -d "/Applications/Chromium.app" ]] && echo "true" || echo "false")"
	if [[ "$altered" == "false" && "$present" == "true" ]]; then
		[[ -s "$HOME/.zshrc" ]] || printf "#!/bin/zsh" >"$HOME/.zshrc"
		perl -i -0777 -pe "s/\n*\z/\n/s" "$HOME/.zshrc" 2>/dev/null || true
		printf "\n%s" "# Assign chromium as chrome executable for flutter" >>"$HOME/.zshrc"
		printf "\n%s\n" 'export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"' >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

}

# @define Update fork
update_fork() {

	# Update package
	update_cask fork

	# Change appearance
	change_appicon "fork" "/Applications/Fork.app"

}

# @define Update frame0
update_frame0() {

	# Update package
	update_cask frame0

	# Change association
	local address="https://api.github.com/repos/jdek/openwith/releases/latest"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
	local address="https://github.com/jdek/openwith/releases/download/v$version/openwith-v$version.tar.xz"
	local archive=$(mktemp -d)/$(basename "$address") && curl -LA "mozilla/5.0" "$address" -o "$archive"
	local deposit=$(mktemp -d)
	expand_archive "$archive" "$deposit"
	"$deposit/openwith" com.electron.frame0 f0

	# Change appearance
	change_appicon "frame0" "/Applications/Frame0.app"

}

# @define Update git
update_git() {

	# Handle parameters
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	# Update package
	update_brew gh git

	# Change settings
	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail"
	[[ -n "$gituser" ]] && git config --global user.name "$gituser"
	git config --global checkout.workers 0
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global push.autoSetupRemote true

}

# @define Update google-chrome
update_google_chrome() {

	# Update package
	local present="$([[ -d "/Applications/Google Chrome.app" ]] && echo "true" || echo "false")"
	update_cask google-chrome
	killall Chrome || true

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "Google Chrome"; fi

	# Change settings
	# INFO: https://github.com/yashgorana/chrome-debloat
	local configs="$HOME/Library/Preferences/com.google.Chrome.plist"
	local program="/usr/libexec/PlistBuddy"
	sudo rm "$configs" && sleep 5
	sudo "$program" -c "Save" "$configs"
	sudo "$program" -c "Add :AlternateErrorPagesEnabled bool false" "$configs"
	sudo "$program" -c "Add :AutofillCreditCardEnabled bool false" "$configs"
	sudo "$program" -c "Add :BackgroundModeEnabled bool false" "$configs"
	sudo "$program" -c "Add :BrowserGuestModeEnabled bool false" "$configs"
	sudo "$program" -c "Add :BrowserSignin integer 0" "$configs"
	sudo "$program" -c "Add :BuiltInDnsClientEnabled bool false" "$configs"
	sudo "$program" -c "Add :CloudReportingEnabled bool false" "$configs"
	sudo "$program" -c "Add :DefaultBrowserSettingEnabled bool false" "$configs"
	sudo "$program" -c "Add :DefaultGeolocationSetting integer 2" "$configs"
	sudo "$program" -c "Add :DefaultLocalFontsSetting integer 2" "$configs"
	sudo "$program" -c "Add :DefaultNotificationsSetting integer 2" "$configs"
	sudo "$program" -c "Add :DefaultSensorsSetting integer 2" "$configs"
	sudo "$program" -c "Add :DefaultSerialGuardSetting integer 2" "$configs"
	sudo "$program" -c "Add :DeviceActivityHeartbeatEnabled bool false" "$configs"
	sudo "$program" -c "Add :DeviceMetricsReportingEnabled bool false" "$configs"
	sudo "$program" -c "Add :DriveDisabled bool true" "$configs"
	sudo "$program" -c "Add :ExtensionManifestV2Availability integer 2" "$configs"
	sudo "$program" -c "Add :HeartbeatEnabled bool false" "$configs"
	sudo "$program" -c "Add :LogUploadEnabled bool false" "$configs"
	sudo "$program" -c "Add :MetricsReportingEnabled bool false" "$configs"
	sudo "$program" -c "Add :ParcelTrackingEnabled bool false" "$configs"
	sudo "$program" -c "Add :PasswordLeakDetectionEnabled bool false" "$configs"
	sudo "$program" -c "Add :PasswordManagerEnabled bool false" "$configs"
	sudo "$program" -c "Add :PasswordSharingEnabled bool false" "$configs"
	sudo "$program" -c "Add :QuickAnswersEnabled bool false" "$configs"
	sudo "$program" -c "Add :RelatedWebsiteSetsEnabled bool false" "$configs"
	sudo "$program" -c "Add :ReportAppInventory array" "$configs"
	sudo "$program" -c "Add :ReportDeviceActivityTimes bool false" "$configs"
	sudo "$program" -c "Add :ReportDeviceAppInfo bool false" "$configs"
	sudo "$program" -c "Add :ReportDeviceSystemInfo bool false" "$configs"
	sudo "$program" -c "Add :ReportDeviceUsers bool false" "$configs"
	sudo "$program" -c "Add :ReportWebsiteTelemetry array" "$configs"
	sudo "$program" -c "Add :SafeBrowsingDeepScanningEnabled bool false" "$configs"
	sudo "$program" -c "Add :SafeBrowsingExtendedReportingEnabled bool false" "$configs"
	sudo "$program" -c "Add :SafeBrowsingSurveysEnabled bool false" "$configs"
	sudo "$program" -c "Add :ShoppingListEnabled bool false" "$configs"
	sudo "$program" -c "Add :SyncDisabled bool true" "$configs"

	# Change extensions
	sudo "$program" -c "Delete :ExtensionInstallForcelist" "$configs"
	sudo "$program" -c "Add :ExtensionInstallForcelist array" "$configs"
	sudo "$program" -c "Add :ExtensionInstallForcelist:0 string 'ddkjiahejlhfcafbddmgiahcphecmpfh'" "$configs" # ublock-origin-lite

	# Change appearance
	change_appicon "google-chrome" "/Applications/Google Chrome.app"

}

# @define Update handy
update_handy() {

	# Handle parameters
	local autoload=${1:-true}

	# Update package
	local present="$([[ -d "/Applications/Handy.app" ]] && echo "true" || echo "false")"
	update_cask handy

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "Handy"; fi

	# Change settings
	local configs="$HOME/Library/Application Support/com.pais.handy/settings_store.json"
	[[ "$autoload" == "true" ]] && jq '.settings.autostart_enabled = true' "$configs" | sponge "$configs"
	jq '.settings.overlay_position = "top"' "$configs" | sponge "$configs"
	jq '.settings.push_to_talk = false' "$configs" | sponge "$configs"
	jq '.settings.start_hidden = true' "$configs" | sponge "$configs"

}

# @define Update homebrew
update_homebrew() {

	# Update package
	local command=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
	CI=1 /bin/bash -c "$command" &>/dev/null

	# Change environment
	local configs="$HOME/.zprofile"
	if ! grep -q "/opt/homebrew/bin/brew shellenv" "$configs" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || printf "#!/bin/zsh" >"$HOME/.zshrc"
		perl -i -0777 -pe "s/\n*\z/\n/s" "$HOME/.zshrc" 2>/dev/null || true
		printf "\n%s" "# Invoke homebrew environment" >>"$configs"
		printf "\n%s\n" 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$configs"
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi

	# Change settings
	brew analytics off

}

# @define Update hoppscotch
update_hoppscotch() {

	# Update package
	update_cask hoppscotch

	# Change appearance
	change_appicon "hoppscotch" "/Applications/Hoppscotch.app"

}

# @define Update ibkr
update_ibkr_desktop() {

	# Update package
	update_cask ibkr

	# Change appearance
	change_appicon "ibkr-desktop" "/Applications/IBKR Desktop.app"

}

# @define Update icon-composer
update_icon_composer() {

	# Update package
	update_cask icon-composer

}

# @define Update iina
update_iina() {

	# Update dependencies
	update_brew curl jq

	# Update package
	local present=$([[ -d "/Applications/IINA.app" ]] && echo "true" || echo "false")
	update_cask iina

	# Finish install
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

	# Change appearance
	change_appicon "iina" "/Applications/IINA.app"

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

	# Change theme
	local configs=$(find "$HOME/Library/Application Support/JetBrains/IntelliJIdea"*/options -name "laf.xml" 2>/dev/null | sort -r | head -1)
	if [[ -f "$configs" ]]; then
		xmlstarlet ed -L -u "//component[@name='LafManager']/laf/@themeId" -v "Islands Dark" "$configs" 2>/dev/null ||
			xmlstarlet ed -L -s "//application" -t elem -n "component" -v "" \
				-i "//component[not(@name)]" -t attr -n "name" -v "LafManager" \
				-s "//component[@name='LafManager']" -t elem -n "laf" -v "" \
				-i "//laf[not(@themeId)]" -t attr -n "themeId" -v "Islands Dark" \
				"$configs" 2>/dev/null
	fi

	# Change scheme
	local configs=$(find "$HOME/Library/Application Support/JetBrains/IntelliJIdea"*/options -name "colors.scheme.xml" 2>/dev/null | sort -r | head -1)
	if [[ -f "$configs" ]]; then
		xmlstarlet ed -L -u "//component[@name='EditorColorsManagerImpl']/global_color_scheme/@name" -v "Islands Dark" "$configs" 2>/dev/null ||
			xmlstarlet ed -L -s "//application" -t elem -n "component" -v "" \
				-i "//component[not(@name)]" -t attr -n "name" -v "EditorColorsManagerImpl" \
				-s "//component[@name='EditorColorsManagerImpl']" -t elem -n "global_color_scheme" -v "" \
				-i "//global_color_scheme" -t attr -n "name" -v "Islands Dark" \
				"$configs" 2>/dev/null
	fi

	# Change appearance
	change_appicon "intellij-idea" "/Applications/IntelliJ IDEA.app"

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
	# Dummy true as jdownloader is resetting its settings sporadically
	if [[ "$present" == "false" ]] || true; then
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
	local address="https://github.com/olankens/machogen/raw/HEAD/.assets/icons/jdownloader.icns"
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
	brew install curl grep jq
	brew upgrade curl grep jq

	# Update package
	local present="$([[ -d "/Applications/Joal Desktop.app" ]] && echo "true" || echo "false")"
	local address="https://api.github.com/repos/anthonyraymond/joal-desktop/releases/latest"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
	local current=$(gather_version "/*ppl*/*oal*esk*")
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
	mkdir -p "$(dirname "$configs")"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."minUploadRate" = 300' "$configs" | sponge "$configs"
	jq '."maxUploadRate" = 450' "$configs" | sponge "$configs"
	jq '."simultaneousSeed" = 200' "$configs" | sponge "$configs"
	jq '."client" = "transmission-3.00.client"' "$configs" | sponge "$configs"
	jq '."keepTorrentWithZeroLeechers" = true' "$configs" | sponge "$configs"
	jq '."uploadRatioTarget" = -1' "$configs" | sponge "$configs"

	# Change appearance
	change_appicon "joal-desktop" "/Applications/JoalDesktop.app"

}

# @define Update keepingyouawake
update_keepingyouawake() {

	# Update package
	update_cask keepingyouawake

}

# @define Update keka
update_keka() {

	# Update package
	update_cask keka kekaexternalhelper

	# Finish install
	/Applications/KekaExternalHelper.app/Contents/MacOS/KekaExternalHelper --set-as-default

	# Change appearance
	change_appicon "keka" "/Applications/Keka.app"

}

# @define Update miniforge
update_miniforge() {

	# Update package
	update_cask miniforge

	# Change settings
	conda init zsh
	conda config --set auto_activate_base false

}

# @define Update mqttx
update_mqttx() {

	# Update package
	update_cask mqttx

	# Change appearance
	change_appicon "mqttx" "/Applications/MQTTX.app"

}

# @define Update netnewswire
update_netnewswire() {

	# Update package
	update_cask netnewswire

	# Change appearance
	change_appicon "netnewswire" "/Applications/NetNewsWire.app"

}

# @define Update nightlight
update_nightlight() {

	# Handle parameters
	local percent=${1:-60}
	local forever=${2:-true}

	# Update package
	update_brew smudge/smudge/nightlight

	# Change settings
	[[ "$forever" == "true" ]] && nightlight schedule 3:00 2:59
	nightlight temp "$percent" && nightlight on

}

# @define Update nodejs
update_nodejs() {

	# Handle dependencies
	update_brew curl grep jq

	# Update package
	local address="https://raw.githubusercontent.com/scoopinstaller/main/master/bucket/nodejs-lts.json"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq '.version' | ggrep -oP "[\d]+" | head -1)
	update_brew node@"$version"

	# Change environment
	if ! grep -q "/opt/homebrew/opt/node" "$HOME/.zshrc" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || printf "#!/bin/zsh" >"$HOME/.zshrc"
		perl -i -0777 -pe "s/\n*\z/\n/s" "$HOME/.zshrc" 2>/dev/null || true
		printf "\n%s" "# Append node bin directory to path" >>"$HOME/.zshrc"
		printf "\n%s\n" "export PATH=\"\$PATH:/opt/homebrew/opt/node@$version/bin\"" >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	else
		sed -i "" -e "s#/opt/homebrew/opt/node.*/bin#/opt/homebrew/opt/node@$version/bin#" "$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

}

# @define Update notion
update_notion() {

	# Handle dependencies
	update_brew coreutils jq

	# Update package
	local present="$([[ -d "/Applications/Notion.app" ]] && echo "true" || echo "false")"
	update_cask notion

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "Notion"; fi

	# Change settings
	local configs="$HOME/Library/Application Support/Notion/state.json"
	mkdir -p "$(dirname "$configs")"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '.appState.preferences.isMenuBarIconEnabled = false' "$configs" | sponge "$configs"
	jq '.appState.preferences.isAutoUpdaterDisabled = true' "$configs" | sponge "$configs"

	# Change appearance
	change_appicon "notion" "/Applications/Notion.app"

}

# @define Update obs
update_obs() {

	# Update package
	update_cask obs

	# Change appearance
	change_appicon "obs" "/Applications/OBS.app"

}

# @define Update pearcleaner
update_pearcleaner() {

	# Update package
	update_cask pearcleaner

	# Change appearance
	change_appicon "pearcleaner" "/Applications/Pearcleaner.app"

}

# @define Update postgresql
update_postgresql() {

	# Handle parameters
	local version=${1:-17}

	# Update package
	update_brew postgresql@"$version"

	# Launch service
	# INFO: Default credentials are $USER with empty password
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
	defaults -currentHost write -globalDomain NSStatusItemSpacing -int 5

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

	# Remove last login message
	touch ~/.hushlogin

	# Remove remnants
	find ~ -name ".DS_Store" -delete

	# Remove chime
	sudo nvram StartupMute=%01

	# Update rosetta
	/usr/sbin/softwareupdate --install-rosetta --agree-to-license &>/dev/null

	# Update system
	# sudo softwareupdate --download --all --force --agree-to-license --verbose

}

# @define Update telegram
update_telegram() {

	# Update package
	update_cask telegram

	# Change appearance
	change_appicon "telegram" "/Applications/Telegram.app"

}

# @define Update temurin
update_temurin() {

	# Handle dependencies
	update_brew curl jq

	# Update package
	update_cask temurin

}

# @define Update transmission
update_transmission() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/P2P}
	local seeding=${2:-0.1}

	# Update package
	update_cask transmission

	# Change settings
	mkdir -p "$deposit/Incompleted"
	defaults write org.m0k.transmission DownloadFolder -string "$deposit"
	defaults write org.m0k.transmission DownloadLocationConstant -int "1"
	defaults write org.m0k.transmission IncompleteDownloadFolder -string "$deposit/Incompleted"
	defaults write org.m0k.transmission RatioCheck -bool true
	defaults write org.m0k.transmission RatioLimit -int "$seeding"
	defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
	defaults write org.m0k.transmission WarningDonate -bool false
	defaults write org.m0k.transmission WarningLegal -bool false

	# Change appearance
	change_appicon "transmission" "/Applications/Transmission.app"

}

# @define Update utm
update_utm() {

	# Update package
	update_cask utm

	# Change appearance
	change_appicon "utm" "/Applications/UTM.app"

}

# @define Update vscodium
update_vscodium() {

	# Handle dependencies
	update_brew font-jetbrains-mono jq sponge

	# Update package
	update_cask vscodium

	# Change settings
	codium --install-extension "gitHub.github-vscode-theme"
	local configs="$HOME/Library/Application Support/VSCodium/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.fontFamily" = "JetBrains Mono, monospace"' "$configs" | sponge "$configs"
	jq '."editor.fontSize" = 13' "$configs" | sponge "$configs"
	jq '."editor.guides.bracketPairs" = "active"' "$configs" | sponge "$configs"
	jq '."editor.lineHeight" = 1.8' "$configs" | sponge "$configs"
	jq '."editor.minimap.enabled" = false' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"

}

# @define Update xcode
update_xcode() {

	# Handle dependencies
	update_brew cocoapods mas

	# Update package
	mas install 497799835
	mas upgrade 497799835

	# Finish install
	sudo xcode-select --switch "/Applications/Xcode.app/Contents/Developer"
	sudo xcodebuild -runFirstLaunch
	sudo xcodebuild -license accept

}

# @define Update youtube-music
update_youtube_music() {

	# Handle dependencies
	update_brew jq sponge

	# Update package
	local present="$([[ -d "/Applications/YouTube Music.app" ]] && echo "true" || echo "false")"
	update_cask th-ch/youtube-music/youtube-music

	# Finish install
	if [[ "$present" == "false" ]]; then invoke_once "YouTube Music"; fi

	# Change settings
	local configs="$HOME/Library/Application Support/YouTube Music/config.json"
	jq '.plugins."quality-changer".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."sponsorblock".enabled = true' "$configs" | sponge "$configs"
	jq '.plugins."synced-lyrics".enabled = true' "$configs" | sponge "$configs"
	# jq '.plugins."no-google-login".enabled = true' "$configs" | sponge "$configs"

	# Change appearance
	change_appicon "youtube-music" "/Applications/YouTube Music.app"

}

# @define Update zed
update_zed() {

	# Handle dependencies
	update_brew font-jetbrains-mono jq sponge

	# Update package
	update_cask zed

	# Change settings
	local configs="$HOME/.config/zed/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '.agent_ui_font_size = 14.0' "$configs" | sponge "$configs"
	jq '.buffer_font_family = "JetBrains Mono"' "$configs" | sponge "$configs"
	jq '.buffer_font_size = 13.0' "$configs" | sponge "$configs"
	jq '.buffer_line_height = {"custom": 1.8}' "$configs" | sponge "$configs"
	jq '.rounded_selection = true' "$configs" | sponge "$configs"
	jq '.title_bar.show_sign_in = false' "$configs" | sponge "$configs"
	jq '.ui_font_size = 15.0' "$configs" | sponge "$configs"

}

# endregion

# region devtools

# @define Update android devtools
update_android_devtools() {

	# Handle parameters
	local version=${1:-36}

	# Handle dependencies
	update_android_cmdline
	update_android_studio

	# Update sdks
	yes | sdkmanager "cmdline-tools;latest"
	yes | sdkmanager "build-tools;${version}.0.0"
	yes | sdkmanager "emulator"
	yes | sdkmanager "platform-tools"
	yes | sdkmanager "platforms;android-${version}"
	yes | sdkmanager "sources;android-${version}"
	yes | sdkmanager "system-images;android-${version};google_apis;arm64-v8a"
	yes | sdkmanager --licenses
	yes | sdkmanager --update

	# Create emulators
	avdmanager create avd -n "Pixel_7a_API_${version}" -d "pixel_7a" -k "system-images;android-${version};google_apis;arm64-v8a" -f

}

# @define Update angular devtools
update_angular_devtools() {

	# Handle parameters
	local datadir=${1:-$HOME/Library/Application Support/Chromium/Developer}

	# Handle dependencies
	update_chromium_developer
	update_intellij_idea
	update_nodejs
	update_vscodium

	# Update angular
	export NG_CLI_ANALYTICS="ci" && npm i -g @angular/cli
	ng analytics off

	# Change environment
	if ! grep -q "ng completion script" "$HOME/.zshrc" 2>/dev/null; then
		[[ -s "$HOME/.zshrc" ]] || printf "#!/bin/zsh" >"$HOME/.zshrc"
		perl -i -0777 -pe "s/\n*\z/\n/s" "$HOME/.zshrc" 2>/dev/null || true
		printf "\n%s" "# Enable angular cli completion" >>"$HOME/.zshrc"
		printf "\n%s" "autoload -Uz compinit && compinit" >>"$HOME/.zshrc"
		printf "\n%s\n" "source <(ng completion script)" >>"$HOME/.zshrc"
		source "$HOME/.zshrc"
	fi

	# Update chromium extensions
	update_chromium_extension "ienfalfjdbdpebioblfackkekamfmbnh" "$datadir" # angular-devtools
	update_chromium_extension "kgpbgfjgjanmdcoefmofbmlhhkmeipng" "$datadir" # angulariad

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "angular.ng-template"
		codium --install-extension "bradlc.vscode-tailwindcss"
		codium --install-extension "dbaeumer.vscode-eslint"
		codium --install-extension "mikestead.dotenv"
		codium --install-extension "usernamehw.errorlens"
		codium --install-extension "yoavbls.pretty-ts-errors"
	fi

	# Update intellij plugins
	if command -v idea &>/dev/null; then
		idea installPlugins AngularJS
		idea installPlugins com.github.dinbtechit.ngxs
	fi

}

# @define Update apple devtools
update_apple_devtools() {

	# Handle dependencies
	update_xcode

	# Update platforms
	xcodebuild -downloadPlatform iOS

}

# @define Update claude code devtools
update_claude_code_devtools() {

	# Handle parameters
	local withzai=${1:-false}

	# Handle dependencies
	update_claude_code
	update_conductor
	update_brew ccusage

	# Change settings
	claude config set -g theme dark
	claude config set defaultMode "acceptEdits"
	claude config set includeCoAuthoredBy false
	if [[ "$withzai" == "true" ]]; then
		local configs="$HOME/.claude/settings.json"
		jq '.env = {
			ANTHROPIC_AUTH_TOKEN: (.env.ANTHROPIC_AUTH_TOKEN // "your_zai_api_key"),
			ANTHROPIC_BASE_URL: "https://api.z.ai/api/anthropic",
			API_TIMEOUT_MS: "3000000"
		}' "$configs" | sponge "$configs"
	fi

}

# @define Update flutter devtools
update_flutter_devtools() {

	# Handle dependencies
	update_android_devtools
	update_apple_devtools
	update_flutter
	update_vscodium

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "alexisvt.flutter-snippets"
		codium --install-extension "dart-code.flutter"
		codium --install-extension "pflannery.vscode-versionlens"
		# codium --install-extension "RichardCoutts.mvvm-plus"
		# codium --install-extension "robert-brunhage.flutter-riverpod-snippets"
		codium --install-extension "usernamehw.errorlens"
	fi

	# Update studio plugins
	if command -v studio &>/dev/null; then
		local program="/Applications/Android Studio.app/Contents/MacOS/studio"
		"$program" installPlugins Dart
		"$program" installPlugins io.flutter
		# "$program" installPlugins com.localizely.flutter-intl
		# "$program" installPlugins org.tbm98.flutter-riverpod-snippets
	fi

	# TODO: Add `readlink -f $(which flutter)` to studio
	# NOTE: /opt/homebrew/share/flutter should work

}

# @define Update git devtools
update_git_devtools() {

	# Handle dependencies
	update_brew gh git
	update_nodejs

	# Create global commitlint
	npm install -g @commitlint/{config-conventional,cli}
	{
		echo "module.exports = {"
		echo "  extends: ['@commitlint/config-conventional'],"
		echo "  rules: {"
		echo "    'header-max-length': [2, 'always', 40],"
		echo "    'header-min-length': [2, 'always', 10],"
		echo "  },"
		echo "};"
	} >"$HOME/.commitlintrc.js"
	mkdir -p "$HOME/.githooks"
	git config --global core.hooksPath "$HOME/.githooks"
	echo -e "#!/bin/sh\ncommitlint --edit \$1" >"$HOME/.githooks/commit-msg"
	chmod +x "$HOME/.githooks/commit-msg"

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension GitHub.vscode-pull-request-github
		codium --install-extension streetsidesoftware.code-spell-checker
	fi

}

# @define Update ionic devtools
update_ionic_devtools() {

	# Handle dependencies
	update_android_devtools
	update_angular_devtools
	update_apple_devtools

	# Update codium extensions
	# if command -v codium &>/dev/null; then
	# 	codium --install-extension "WebNative.webnative"
	# fi

}

# @define Update nestjs devtools
update_nestjs_devtools() {

	# Handle dependencies
	update_intellij_idea
	update_nodejs
	update_vscodium

	# Update codium extensions
	# if command -v codium &>/dev/null; then
	# 	codium --install-extension "WebNative.webnative"
	# fi

	# Update intellij plugins
	if command -v idea &>/dev/null; then
		idea installPlugins com.github.dinbtechit.jetbrainsnestjs
	fi

}

# @define Update react devtools
update_react_devtools() {

	# Handle parameters
	local datadir=${1:-$HOME/Library/Application Support/Chromium/Developer}

	# Update dependencies
	update_chromium_developer
	update_intellij_idea
	update_nodejs
	update_vscodium

	# Update chromium extensions
	update_chromium_extension "fmkadmapgofadopljbjfkapdkoienihi" "$datadir" # react-developer-tools
	update_chromium_extension "lmhkpmbekcpmknklioeibfkpmmfibljd" "$datadir" # redux-devtools

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "bradlc.vscode-tailwindcss"
		codium --install-extension "dbaeumer.vscode-eslint"
		codium --install-extension "esbenp.prettier-vscode"
		codium --install-extension "usernamehw.errorlens"
		codium --install-extension "yoavbls.pretty-ts-errors"
	fi

	# Change codium settings
	if command -v codium &>/dev/null; then
		local configs="$HOME/Library/Application Support/VSCodium/User/settings.json"
		[[ -s "$configs" ]] || echo "{}" >"$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."editor.codeActionsOnSave"."source.fixAll" = "explicit"' "$configs" | sponge "$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."editor.defaultFormatter" = "esbenp.prettier-vscode"' "$configs" | sponge "$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."editor.formatOnSave" = true' "$configs" | sponge "$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."editor.linkedEditing" = true' "$configs" | sponge "$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."editor.tabSize" = 2' "$configs" | sponge "$configs"
		jq '."[css][javascript][javascriptreact][json][html][md][typescript][typescriptreact][vue]"."prettier.printWidth" = 100' "$configs" | sponge "$configs"
	fi

}

# @define Update react-native devtools
update_react_native_devtools() {

	# Handle dependencies
	update_android_devtools
	update_apple_devtools
	update_react_devtools
	update_brew oven-sh/bun/bun watchman

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "expo.vscode-expo-tools"
		codium --install-extension "msjsdiag.vscode-react-native"
	fi

}

# @define Update shell devtools
update_shell_devtools() {

	# Handle dependencies
	update_vscodium
	update_brew shfmt

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "mkhl.shfmt"
		codium --install-extension "timonwong.shellcheck"
	fi

	# Update intellij plugins
	if command -v idea &>/dev/null; then
		idea installPlugins pro.bashsupport
	fi

}

# @define Update spring devtools
update_spring_devtools() {

	# Handle dependencies
	update_docker
	update_intellij_idea
	update_postgresql
	update_temurin
	update_vscodium
	update_brew gradle maven

	# Update codium extensions
	if command -v codium &>/dev/null; then
		codium --install-extension "vmware.vscode-spring-boot"
	fi

	# Change codium settings
	local configs="$HOME/Library/Application Support/VSCodium/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."redhat.telemetry.enabled" = false' "$configs" | sponge "$configs"

	# Update intellij plugins
	if command -v idea &>/dev/null; then
		idea installPlugins com.intellij.spring.debugger
	fi

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

	country="Europe/Brussels"
	machine="macintosh"
	members=(
		"update_homebrew"
		"update_system"

		"update_android_studio"
		"update_chromium"
		"update_chromium_developer"
		"update_intellij_idea"
		"update_vscodium"
		"update_xcode"

		"update_calibre"
		"update_capcut"
		"update_claude_code"
		"update_comfyui"
		"update_conductor"
		"update_crossover"
		"update_davinci_resolve"
		"update_discord"
		"update_docker"
		"update_figma"
		"update_flutter"
		"update_fork"
		"update_frame0"
		"update_git 'main' 'olankens' '173156207+olankens@users.noreply.github.com'"
		"update_google_chrome"
		"update_handy"
		"update_hoppscotch"
		"update_icon_composer"
		"update_iina"
		"update_jdownloader"
		"update_joal_desktop"
		"update_keepingyouawake"
		"update_keka"
		"update_miniforge"
		"update_mqttx"
		"update_netnewswire"
		"update_nightlight"
		"update_nodejs"
		"update_notion"
		"update_obs"
		"update_pearcleaner"
		"update_postgresql"
		"update_telegram"
		"update_temurin"
		"update_transmission"
		"update_utm"
		"update_youtube_music"

		"update_android_devtools"
		"update_angular_devtools"
		"update_apple_devtools"
		"update_claude_code_devtools"
		"update_flutter_devtools"
		"update_git_devtools"
		"update_ionic_devtools"
		"update_react_devtools"
		"update_react_native_devtools"
		"update_shell_devtools"
		"update_spring_devtools"

		"update_appearance"
	)

	invoke_wrapper "$welcome" "$country" "$machine" "${members[@]}"

fi
