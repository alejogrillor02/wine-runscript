#!/bin/bash
#
# About: Game start script (Native/Wine).
# Author: alejo.grillor02
# License: GNU GPLv3

# To Do:
#	- VDesktop Support
#	- More Wine enviroment vars
#	- Check if two games running at the same time kill each other while killing gamemoded
#	- Improve help message

## Exit if root
if [[ "$EUID" = 0 ]]
  then echo "Do not run this script as root!"
  exit
fi

SCRVER="v2.0.1"
SCRDIR=$(realpath "$(dirname "$0")")

clear
echo "Welcome on Game Start Script $SCRVER"

print_help() {
	echo "Usage:"
	echo "  $0 <game> [...]"
	echo "Operations:"
	echo "  --exec <exec>:        override game config executable file"
	echo "  --winecfg:            launches winecfg (if not native)"
	echo "  --regedit:            opens registry editor (if not native)"
	echo "  --winetricks:         launches winetricks (if not native)"
	echo "  --args <args>:        override game config arguments"
	echo "  --configpath <path>:  override default configuration path"
	echo "  --debug:              print additional information"
	echo "  --help|-h:            echoes this message"
	echo ""
	echo "This script receives an existing config in \$CONFIGPATH (default to \$(dirname \$0)/games),"
	echo "or an existing path, the config file has to be in the following format:"
	echo ""
	echo "  NATIVE=INT"
	echo "  GAMENAME=string"
	echo "  GAMEDIR=string"
	echo "  EXEC=string"
	echo "  ARGS=string"
	echo "  GAMEMODE=INT"
	echo "  GAMESCOPE=INT"
	echo "  GAMESCOPE_ARGS=string"
	echo "  MANGOHUD=INT"
	echo ""
	echo "If NATIVE is equal to 0, then the following variables are needed:"
	echo ""
	echo "  RUNNER=string"
	echo "  WINEPREFIX=string"
	echo "  WINEARCH=string"
	echo "  WINEDLLOVERRIDES=string"
	echo "  WINEESYNC=INT"
	echo "  WINEFSYNC=INT"
	echo "  WINE_FULLSCREEN_FSR=INT"
	echo "  WINE_LARGE_ADDRESS_AWARE=INT"
	echo ""
	echo "With each INT being 0 or 1, the descriptions of each parameter are self-explanatory"
	echo "Order or extra variables doesn't matter in the config file."
	echo "The following ones are optional"
	echo ""
	echo "  DXVK_HUD=INT"
	echo "  DXVK_ASYNC=INT"
}

## Get gameinfo

CONFIGPATH="${SCRDIR}/games"

if [ $1 = "--help" ] || [ $1 = "-h" ];then
	print_help
	exit 0
elif [[ -f "$CONFIGPATH/$1" ]]; then
	CONFIG="$CONFIGPATH/$1"
	## Workaround for SC1091 and SC1090
	# shellcheck source=/dev/null
	source "$CONFIG"
elif [[ -f "$1" ]]; then
    source $1
else
    echo "Error: The given config doesn't exist nor is a real file path: $1"
	exit 1
fi

## Checks gameinfo

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

# WDIR=$(realpath "$(dirname "$EXEC")")
# cd "$WDIR" || exit

echo "Running $GAMENAME ($1)"
shift

## Helpful vars
CACHEDIR="${HOME}/.cache"
WINEDEBUG="-all"

## Check permissions (not neccesary for the moment)
# if ! touch "${SCRDIR}/write_test"; then
# 	echo "You have no write permissions on this directory!"
# 	exit
# fi
# rm -f "${GAMEDIR}/write_test"

## Get flags/options
while [[ $# -gt 0 ]]; do
	case "$1" in
		--exec)
			EXEC="$2"
			shift 2;;
		--winecfg)
			if [ "$NATIVE" = "1" ]; then
				EXEC="${RUNNER}/bin/winecfg"
			fi
			shift;;
		--regedit)
			if [ "$NATIVE" = "1" ]; then
				EXEC="${RUNNER}/bin/regedit"
			fi
			shift;;
		--winetricks)
			if [ "$NATIVE" = "1" ]; then
				EXEC="$(command -v winetricks)"
			fi
			shift;;
		--args)
			ARGS="$2"
			shift 2;;
		--debug)
			WINEDEBUG="fps,err+all,fixme-all"
			shift;;
		-h | --help)
			print_help
			exit 0;;
		*)
			echo "Unknown option: $1"
			print_help
			exit 1;;
	esac
done
 
## Default Enviroment vars
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="${CACHEDIR}"

export XDG_CACHE_HOME="${CACHEDIR}"
export DXVK_LOG_PATH="${CACHEDIR}/dxvk"
export DXVK_STATE_CACHE_PATH="${CACHEDIR}/dxvk"

## Get Env vars from flags
export MANGOHUD
export DXVK_HUD
export DXVK_ASYNC

if [ "${NATIVE}" = 0 ]; then
	WINE="${RUNNER}/bin/wine"
	# WINE64="${RUNNER}/bin/wine64"
	WINESERVER="${RUNNER}/bin/wineserver"
	# MSIEXEC="${RUNNER}/bin/msiexec"
	
	export WINEPREFIX
	export WINEARCH
	export WINEDEBUG

	export WINEDLLOVERRIDES
	export WINEESYNC
	export WINEFSYNC
	export WINE_FULLSCREEN_FSR
	export WINE_LARGE_ADDRESS_AWARE

	## Unknown Env vars
	# export DXVK_HDR=0
	# export DXVK_FRAME_RATE=0

	CMD_PREFIX="${WINE}"
else
	CMD_PREFIX=""
fi

## Vars (For script use)
if [ "${GAMEMODE}" = 1 ]; then
	if [ ! "$(command -v gamemoderun)" ] > /dev/null 2>&1; then
		echo -ne "\nexit 1 GameMode is not installed\n"
		exit 1
	fi
	GAMEMODE_RUN="$(command -v gamemoderun)"
fi

if [ "${GAMESCOPE}" = 1 ]; then
	if [ ! "$(command -v gamescope)" ] > /dev/null 2>&1; then
		echo -ne "\nexit 1 Gamescope is not installed\n"
		exit 1
	fi
	GAMESCOPE_RUN="$(command -v gamescope)  $GAMESCOPE_ARGS --"
fi

## Run the game

## This thing works if the unused ones are blank, but is better using "" and {},
## just cause directories with spaces, so LOL
# $GAMESCOPE_RUN $GAMEMODE_RUN $WINE "${EXEC}" $ARGS

if [ "${GAMESCOPE}" = 1 ] && [ "${GAMEMODE}" = 1 ]; then
	"${GAMESCOPE_RUN}" $GAMESCOPE_ARGS -- "${GAMEMODE_RUN}" $CMD_PREFIX "${EXEC}" $ARGS
elif [ "${GAMESCOPE}" = 1 ]; then
	"${GAMESCOPE_RUN}" $GAMESCOPE_ARGS -- $CMD_PREFIX "${EXEC}" $ARGS
elif [ "${GAMEMODE}" = 1 ]; then
	"${GAMEMODE_RUN}" $CMD_PREFIX "${EXEC}" $ARGS
else
	$CMD_PREFIX "${EXEC}" $ARGS
fi

if [ "${NATIVE}" = 0 ]; then
	"${WINESERVER}" -w
fi

if [ "${GAMEMODE}" = 1 ]; then
	pkill gamemoded
fi
