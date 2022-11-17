#!/bin/bash

# Author: Toroyteach
# Description: This script is going to split a large
## mp3 file into smaller ones such that (for my usecase)
## in my application i can download smaller chunks of the
## mix item itself to play it and save bandwith incase of users
## who login and leave

##check if script was run with su priviledge
if [[ $(id -u) -ne 0 ]]; then
	echo "You need Super User priviledges to run this script!!!"
	exit 1
fi

## create a function to store spinner/proggres animation
spin() {
	spinner="/|\\-/|\\-"
	while :; do
		for i in $(seq 0 7); do
			echo -n "${spinner:$i:1}"
			echo -en "\010"
			sleep 1
		done
	done
}

##check if FFMPEG and LAME packages are installed
FFMPEG_PACKAGE='dpkg-query -l | grep ffmpeg'
LAME='dpkg-query -l | grep lame'

if [ -z "$FFMPEG_PACKAGE" ]; then
	echo "FFMPEG is not installed. Please instal this package to continue"
	echo "Requesting download persission"

	read -p "Would you like to download FFMPEG? " -n 1 -r
	echo # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	else

		## turn the cursor back on
		tput civis

		spin &
		SPIN_PID=$!

		trap "kill -9 $SPIN_PID" $(seq 0 15)

		apt install ffmpeg -y

		kill -9 $SPIN_PID

		## turn the cursor back on
		tput cvvis

	fi

fi

if [ -z "$LAME" ]; then
	echo "LAME is not installed. Please instal this package to continue"
	echo "exiting...."

	read -p "Would you like to download LAME? " -n 1 -r
	echo # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	else

		## turn the cursor back on
		tput civis

		spin &
		SPIN_PID=$!

		trap "kill -9 $SPIN_PID" $(seq 0 15)

		apt install libmp3lame0 -y

		kill -9 $SPIN_PID

		## turn the cursor back on
		tput cvvis
	fi
fi

##check if output music folder for mp3 exist and create or empty it
MUSIC_OUTPUT_DIR='musicChunkOutput'
CURRENT_DIR='pwd'

if [ ! -d "$MUSIC_OUTPUT_DIR" ]; then
	echo "Music Chunk output folder does not exist"
	echo "Creating folder..."

	mkdir "$MUSIC_OUTPUT_DIR"
else
	echo "Opps there is a folder named musicChunkOutput"

	## Prompt to ask user for response before deleting
	echo "About to Delete all files inside musicChunkOutput Directory"
	read -p "Are you sure you a have back up? " -n 1 -r
	echo # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	else
		rm "$MUSIC_OUTPUT_DIR"/*.mp3
		echo "Done deleted everything"
	fi

fi


##check if time folder exist and abort
TIME_FILE=outputRefTime

if [ ! -f "$TIME_FILE" ]; then
	echo "The outputRefTime range file is Required and Missing!!!!"
	echo "Please create this file and place it in same directory"
	echo "exiting..."
	exit 0
fi

##check if the mp3 file to be split exists
SRC_MP3_FILE=stay.mp3

if [ ! -f "$SRC_MP3_FILE" ]; then
	echo "The mp3 file to be split is Required and Missing!!!"
	echo "Please include it to continue"
	exit 0
fi

#start the process

echo "Starting.."

## turn the cursor back on
tput civis

spin &
SPIN_PID=$!

trap "kill -9 $SPIN_PID" $(seq 0 15)

x="00:00:00"
z=1

filename=$(basename -- "$SRC_MP3_FILE")
ext="${filename##*.}"
filename="${filename%.*}"
initcmd="ffmpeg  -nostdin -hide_banner -loglevel error -i $SRC_MP3_FILE"

while read y; do
	OUTPUT_DIR="$MUSIC_OUTPUT_DIR/$z"
	initcmd+=" -ss $x -to $y -c:v copy -c:a copy $OUTPUT_DIR.$ext"
	let "z=z+1"
	x=$y
done <`echo "$TIME_FILE"`

$initcmd

#kill -9 $SPIN_PID

## turn the cursor back on
tput cvvis

echo "Finished succesfully"

exit 0
