#!/bin/bash
#
# About: Game installer for run.sh
# Author: alejo.grillor02
# License: GNU GPLv3

# To Do:
#	- Improve help message (LITERALLY MAKE IT LOL)

## Exit if root
if [[ "$EUID" = 0 ]]
  then echo "Do not run this script as root!"
  exit
fi

SCRVER="v1.0.2"
SCRDIR=$(realpath "$(dirname "$0")")

echo "Welcome on Game Install Script $SCRVER"

print_help() {
	echo "Usage:"
	echo "  $0 <cinfig> [...]"
	echo "Operations:"
	echo "  --exec <exec>:        override game config executable file"
	echo "  --args <args>:        override game config arguments"
	echo "  --configpath <path>:  override default configuration path"
	echo "  --debug:              print additional information"
	echo "  --help|-h:            echoes this message"
}



## Checks gameinfo

if [[ -f "$1" ]]; then
	## Workaround for SC1091 and SC1090
	# shellcheck source=/dev/null
    source $1
else
    echo "The given config isn't a real file path: $1"
	exit 1
fi

# Define a regex pattern for integer variables (0 or 1) and string variables (non-empty)
int_regex='^(0|1)$'
str_regex='^.*$'

## Check for the presence and type of each variable
if ! [[ $GAMENAME =~ $str_regex && $GAMEDIR =~ $str_regex && $EXEC =~ $str_regex ]]; then
	echo "Error: String variables are not set correctly."
	exit 2
fi

if ! [[ $NATIVE =~ $int_regex && $GAMEMODE =~ $int_regex && $GAMESCOPE =~ $int_regex && $MANGOHUD =~ $int_regex ]]; then
	echo "Error: Integer variables are not set correctly."
	exit 2
fi

## If NATIVE is 0, check additional variables
if [[ $NATIVE = 0 ]]; then
	if ! [[ $RUNNER =~ $str_regex && $WINEPREFIX =~ $str_regex && $WINEARCH =~ $str_regex && $WINEDLLOVERRIDES =~ $str_regex ]]; then
		echo "Error: Additional string variables for non NATIVE mode are not set correctly."
		exit 2
	fi

	if ! [[ $WINEESYNC =~ $int_regex && $WINEFSYNC =~ $int_regex && $WINE_FULLSCREEN_FSR =~ $int_regex && $WINE_LARGE_ADDRESS_AWARE =~ $int_regex ]]; then
		echo "Error: Integer variables for non NATIVE mode are not set correctly."
		exit 2
	fi
fi

echo "Do you want to use a custom icon path? (y/n)"
read answer

if [[ $answer == "y" ]]; then
    echo "Please write your path here"
    read ICONPATH
elif [[ $answer == "n" ]]; then
	dir="$1"
	file_extensions=("svg" "png" "jpg" "jpeg" "xpm" "svgz" "webp")
	found_file=""

	# Search for files with specific names and extensions
	for name in "folder" ".folder"; do
		for ext in "${file_extensions[@]}"; do
			file="$GAMEDIR/$name.$ext"
			if [[ -f "$file" ]]; then
				found_file="$file"
				ICONPATH=$(realpath "$found_file")
				echo "Found Icon at: $ICONPATH"
				break
			fi
		done
		[[ -n "$found_file" ]] && break
	done
else
    echo "Invalid input. Please enter 'y' or 'n'."
fi

echo "Do you want to use a custom comment? (y/n)"
read answer

if [[ $answer == "y" ]]; then
    echo "Please write your comment here, press Return when finished"
    read COMMENT
elif [[ $answer == "n" ]]; then
	COMMENT="Play this game"
else
    echo "Invalid input. Please enter 'y' or 'n'."
fi

echo "Do you want to use a custom keywords? (y/n)"
read answer

if [[ $answer == "y" ]]; then
    echo "Please write your Keywords here, separated by semicolons (Remember to put one at the end too);"
	echo "Press Return when finished"
    read keys
	KEYWORDS="Game;$keys"
elif [[ $answer == "n" ]]; then
	KEYWORDS="Game;"
else
    echo "Invalid input. Please enter 'y' or 'n'."
fi

## Moves the config script

CONFIGPATH="${SCRDIR}/games"

if [ -e "${CONFIGPATH}/$1" ]; then
    echo "Error: This config name already exists."
    exit 1
else
    mv "$1" "${CONFIGPATH}/$1"
fi

## Makes a .desktop file

FILENAME=$(basename "$1" | cut -d. -f1)
DEST="${HOME}/.local/share/applications/${FILENAME}.desktop"

cat <<EOF >"${DEST}"
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Exec=${SCRDIR}/run.sh $FILENAME
Name=$GAMENAME
Comment=$COMMENT
Icon=$ICONPATH
GenericName=Game
Categories=Game;
Keywords=$KEYWORDS
Path=$GAMEDIR
StartupNotify=false
EOF