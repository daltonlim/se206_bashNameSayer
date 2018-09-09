#!/bin/bash
#Script ensures that a folder for the creations are present
setup(){
	if [ ! -d "VideoFiles" ]; then
		mkdir VideoFiles
	fi
	cd VideoFiles
	clearTempFiles
	menu
}

#Ensures that no temp files are present.
clearTempFiles(){
	rm temp.wav &> /dev/null
	rm temp.mp4 &> /dev/null
}

#The welcome screen which prompts users
menu(){
	clear
	echo "=============================================================="
	echo "Welcome to NameSayer"
	echo "=============================================================="
	echo "Please select from one of the following options:"
	echo "(l)ist existing creations"
	echo "(p)lay an existing creation"
	echo "(d)elete an existing creation"
	echo "(c)reate a new creation"
	echo "(q)uit authoring tool"
	read -p "Enter a selection [l/p/d/c/q]:" menuselection

	case $menuselection in
		l) listCreationsMenu;;
		p) playCreations;;
		d) deleteCreations;;
		c) createCreation;;
		q) exit;;
		*) menu;;
	esac
}

#Function which lists all the creations created by this program
listCreations(){
	totalVideos=0
	clear
	
	#Iterate through all video files. The second if function ensures
	#that the file generated is actually an mkv and not the first for loop
	for fname in *.mkv; do
		if [ -f "$fname" ]; then
			totalVideos=$((totalVideos+1))
		else
			break
		fi
	done
	
	#Test to check the total videos present
	if  (("$totalVideos" == 0));	then
		echo "No videos were found"
	else
		echo "Here are the existing creations:"
		echo ""
		fileNum=0
		for fname in *.mkv;  
		do
			fileNum=$((fileNum+1))
			echo "[$fileNum] "${fname%%.*}
		done
		echo ""
	fi
}

# List the creations menu so that other functions can call the list
# creations without returning to menu.
listCreationsMenu(){
	listCreations	
	returnToMenu
}

# Function to show prompt and return to menu
returnToMenu(){
	read -n 1 -s -r -p "Press any key to return to the main menu"
	menu
}

# Show the playable creations (if any).
playCreations(){
	listCreations;
	if  (("$totalVideos" != 0));	then	
		playCreationsMessage
	fi
	returnToMenu
}

# Function to prompt the user to find a file to play
playCreationsMessage(){
	read -p "Please enter the name of the file which you want to play: " wantedFile

	if  [ -f "$wantedFile.mkv" ]
	then
		ffplay -autoexit "$wantedFile.mkv" &> /dev/null
	else
		echo "Creation $wantedFile could not be found. Please try again."
		playCreationsMessage
	fi
}

# Function to delete message. Separate from the prompt below as this may be called multiple 
# times.
deleteMessage(){
	read -p "Please enter the name of the file you wish to delete: " wantedFile
	if  [ -f "$wantedFile.mkv" ];
	then
		read -p "Are you sure you want to delete $wantedFile? (y/n)" userAns
		deletePrompt $userAns $wantedFile
	else
		echo "File $wantedFile could not be found. Please try again."
		deleteMessage
	fi
}

# Function to carry out the delete. Separate from the function from above as this can be 
# repeated many times.
deletePrompt(){
	case $1 in
		y)	rm "$2.mkv" &> /dev/null
			echo "Removal successful";;
		n)  returnToMenu;;
		*)  echo "Invalid key"
			read -p "Are you sure you want to delete $wantedFile? (y/n)" userAns
			deletePrompt $userAns;;
	esac
}

# Function to show the videos and then parse the deletions
deleteCreations(){
	listCreations;
	echo ""
	if  (("$totalVideos" != 0));
	then
		deleteMessage
	fi
	returnToMenu
}

# Function to ensure a correct key is pressed for the overwritting of a 
# creation.
deleteFile(){
	read -p "Do you wish to overwrite the recording? (y/n)" entry
	case $entry in
		y)  echo "File overwritten."
			rm "$1";;
		n)  createFile;;
		*)  echo "Invalid key pressed."
			deleteFile;;
	esac
}

# Function to ensure no duplicates are found during a file creation. Separate 
# from the createCreationg function as this may be called multiple times.
createFile(){
	read -p "Please enter a name for the creation: " fileName
	if [ -f "$fileName.mkv" ]
	then
		echo "File $fileName is already present" 
		deleteFile "$fileName.mkv"
	else
		echo "No duplicate found."
	fi
}

# Function to set up the creation of a file. 
createCreation(){
	clear
	echo "You have chosen to create a new creation"
	createFile
	record
}

record(){
	#create video wirth text
	ffmpeg -f lavfi -i color=c=0x2f343f:s=1920x240:d=5 -vf "drawtext=fontfile \
	=/path/to/font.ttf:fontsize=30:fontcolor=0xdfdfdf :text='$fileName'" \
	"temp.mp4" &> /dev/null

	read -n 1 -s -r -p "Press any key to start recording..."
	echo ""
	echo "Recording has started"

	ffmpeg -f alsa -i hw:0 -t 00:00:05 "temp.wav" &> /dev/null

	echo "Recording finished"
	playRecordingMessage
}

# Funtion to allow the user to play back a recently recorded message.
playRecordingMessage(){
	read -p "Do you wish to listen to the recording? (y/n)" entry
	case $entry in 
		y) 	ffplay -autoexit "temp.wav" &> /dev/null
			recordPrompt;;
		n)	recordPrompt;;
		*)	echo "Invalid key pressed."
			playRecordingMessage;;
	esac
}

# Function to check whether the user wants to keep or redo the audio. Separate 
# from above as it may be called multiple times in teh event of invalid keys
recordPrompt(){
	read -p "Do you wish to (k)eep it or (r)edo the audio?" entry
	case $entry in 
		r)	clearTempFiles
			record;;
		k)	createVisualComponent;;
		*)	echo "Invalid key pressed."
			recordPrompt
	esac
}

# Function to generate the mkv file from the temp files.
createVisualComponent(){
	ffmpeg -i temp.mp4 -i temp.wav -c copy "$fileName.mkv" &> /dev/null
	clearTempFiles
	echo "Creation successful"
	returnToMenu
}

setup
