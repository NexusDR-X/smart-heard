#!/bin/bash

#turn line numbers on with CTRL+3 then SHIFT+3
###############################################################
# Smart List for fsq
# Budd Churchward WB7FHC
# email: wb7fhc@arrl.net
V_DATE="02/03/22.1"
#
# Run this script in a terminal window while Flidigi FSQ is also
# running. Make sure that you have enabled the Heard Log in FSQ
#     Configure > Rig Control
#       Modems > FSQ
#         Heard log fsq_heard_log.txt [Enable]
#
# To include your own transmissons in the list you also must
# turn on Text Capture in Flidigi File menu
#
# If you have a copy of fsq_names.csv,
# put it in /home/pi/WB7FHC/
#
# Your Smart Heard List is stored as a file so you can shut down
# your station and bring it up later with the data maintained.
# All times will be recalculated and then updated as stations are
# heard again.
#
# This version does not use a GPIO pin to tell when the station has 
# transmitted. That approach fails with the Rpi4. Instead we watch for
# a change to the date stamped log file in the .fldigi-left (or right)
# folder. If the last line begins with 'TX' we know the users has
# transmitted.
#
#
# KEYBOARD COMMANDS:
#   [Escape] ... stop running script
#   [Insert] ... add new call and name to fsq_names.csv
#            ... can also be done with [^] if your kbrd has no [Insert]
#   [Delete] ... remove a call from your heard list
#   [PgDwn]  ... show more stations heard
#   [PgUp]   ... show fewer stations heard
#   [RT Arrow] ... show dates and time on the display
#   [LT Arrow] ... hide dates and time on the display
#   [UP Arrow] ... increase the update interval in steps of 5 seconds
#   [DN Arrow] ... decrease the update interval to minimum of 5 seconds
#
# SMART LIST FILES:
#   When using the AG7GN image and support files, there are two sets of directories
#   for Fldigi files. In the comments that follow you can substitute .fldigi-right
#   for .fldigi-left as needed depending on whether your radio is using the left
#   or right audio channel
#
#  Support files found in the WB7FHC directory are shared by both the left and right
#  configurations.
#
#   smart_heard.sh
#     this file
#     located @ /home/pi/WB7FHC/smart_heard.sh
#     use: 'chmod 755 smart_heard.sh' to make executable
#     use: './smart_heard.sh' to launch in term. window
#
#   fsq_heard_log.txt ... $heardFile
#     list of all stations heard with UTC and SNR
#     created by Fldigi
#     located @ /home/pi/.fldigi-left/temp/fsq_heard_log.txt
#
#   fldigi<date>.log ... $skimmerFile
#     list of all text sent to the receive window in fldigi
#     created by Fldigi if RX/TX logging is on
#     located @ /home/pi/.fldigi-left/fldigi<date>.log
#     or
#     located @ /home/pi/.fldigi-right/fldigi<date>.log
#     <date> will be date that log is started. We use newest log.
#
#   smart_heard.list ... $ourFile
#     working file for this script
#     contains:
#         call,epoch time,op name
#     located @ ~/WB7FHC/smart_heard.list
#
#   hold.dat ... $tempFile
#     temporary file built from smart_heard.list
#     will become smart_heard.list
#     located @ ~/WB7FHC/hold.dat
#     this file is short lived and is normally
#     not seen in the directory ... script will delete
#     file if it exists at wrong time
#
#   fsq_names.csv ... $OPS_NAMES
#     lookup table to match callsign and op's name
#     located @ ~/WB7FHC/fsq_names.csv
#     If a call sign appears more than once in the list
#     the latest entry will be used.
#
#  fldigi_def.xml ... $CONFIG_FILE
#     contains the Fldigi configuration settings
#     created by Fldigi
#     located @  /home/pi/.fidigi-left/fldigi_def.xml
#
#  seed.names     ... $seedNames
#     optional file to import local calls and names
#     located @  /home/pi/WB7FHC/seed.names
#     if this file exists user will be asked to import it
#     this file will copied to fsq_names.csv if user says yes
#     if user says either yes or no it becomes seed.namesx
#
#  seed.namesx  (no variable)
#     we rename this file after dialog box entry so that
#     we are not asked again.
#     if fsq_names.csv becomes corrupted user can remove
#     the x from the file name and recover the list
##############################################################


#############################################################
#
# DEFAULT TEXT COLORS:
#    YELLOW ... station heard less than 10 minutes ago
#    GREEN  ... station heard less than 1 hour ago
#    WHITE  ... station heard within last 24 hours
#    PUTTY  ... station not heard in last 24 hours
#
####################################################
# The following feature is not implemented in this version
SHOW_RADIO=false    # if true heard list will show L and R s
SHOW_RADIO=$2       # if true heard list will show L and R s
####################################################

LR_CHANNEL=$1       # left or right from startup argument

SHOW_HOW_HOT=false  # if true CPU temp will show in title bar

if [[ $LR_CHANNEL == "right" ]]; then
  #PTTpin=4
  RADIO=R
  LOG_FOLDER="/home/pi/.fldigi-right"
else
  #PTTpin=26
  RADIO=L
  LR_CHANNEL='left' # will always default to left if not specified
  LOG_FOLDER="/home/pi/.fldigi-left"
fi

 # WE NEED TO FIND THE MOST RECENT FLDIGI LOG FILE
  age_check=0
  file_counter=0
  for file_name in $LOG_FOLDER/fldigi*.log; do

    time_stamp=$(stat $file_name -c %Y)
    # echo $file_name $time_stamp
    file_counter=$((file_counter+1))
    if (( $time_stamp > $age_check )); then
      age_check=$time_stamp
      SKIMMER_FILE=$file_name
    fi
  done


 # IF WE HAVE MORE THAN 3 LOG FILES WE WILL REMOVE EXTRAS
  if [[ $file_counter -gt 3 ]];then
    for file_name2 in $LOG_FOLDER/fldigi*.log; do
      time_stamp=$(stat $file_name2 -c %Y)
      if [[ $time_stamp -lt $age_check ]]; then
        if [[ $file_counter -gt 3 ]];then
          #echo "rm "$file_name2
          rm $file_name2
          file_counter=$((file_counter-1))
        fi
      fi
    done
  fi 
#sleep 5

COMMON_DIR=~/WB7FHC
ourFile=$COMMON_DIR/smart_heard.list
  if [[ ! -f $ourFile ]]; then
    touch $ourFile    # create the file if it doesn't exist
  fi


#Let's back up the current smart_heard.list
if [ ! -d $COMMON_DIR/bkp ]; then
  mkdir $COMMON_DIR/bkp
fi
TIMESTAMP=`date +%Y%m%d.%H%M%S`
cd $COMMON_DIR
cp "$ourFile" "bkp/smart_heard."$TIMESTAMP".list"

#Now let's delete the oldest backup
age_check=`date +" %s"` #current epoch time
file_counter=0
for file_name in $COMMON_DIR/bkp/*; do
  time_stamp=$(stat $file_name -c %Y)
  if (( time_stamp < age_check )); then
    age_check=$time_stamp
    oldest_file=$file_name
 fi
    file_counter=$((file_counter+1))

done
  if (( file_counter > 5 )); then
    rm $oldest_file
  fi

FSQ_PATH=~/.fldigi-$LR_CHANNEL/temp
cd $FSQ_PATH

lastGuy='nobody'

includeDT=0        # to toggle between showing dates
                   # and times on the display use RT Arrow
                   # to show D&T use LT Arrow to hide D&T

fullList=1         # to switch between short, medium & long lists
                   # default is medium list
                   # 0 = short list is the last 24 hours
                   # 1 = medium list is the last 20 stations
                   # 2 = full list is all stations up to 99
max=21             # default show only last 20

refreshInterval=15 # default is 15 seconds can be increased
                   # or decreased in steps of 5 with the
                   # Up and Down Arrows ... minimum of 5 sec.
		   # when list gets longer refresh becomes distracting
                   # always refreshes when new station is heard


OPS_NAMES=$COMMON_DIR/fsq_names.csv   # look up table

# if this file does not exist we create it and include a dummy entry
if [[ ! -f $OPS_NAMES ]]; then
  # init the table
  echo 'nocall,noname' >> $OPS_NAMES
fi

# LET'S MAKE SURE WE HAVE OUR fsq_heard_log
# THIS FILE WILL BE .txt unless my net control
# SOFTWARE IS RUNNING. IF IT IS, IT WILL BE .text 
#
# THERE MAY BE AN ISSUE WITH THIS IF YOU ARE RUNNING
# THE NET CONTROL SOFTWARE AT THE SAME TIME AS THIS ONE
# 01-08-22

heardSwap=fsq_heard_log.txt

#if [[ -f $heardSwap ]]; then
#  clear
#  mv $heardSwap fsq_heard_log.text
#fi

  heardFile=fsq_heard_log.txt        #01-07-22
  if [[ -f $heardFile ]]; then
    clear
  else
    # USER NEEDS TO  ENABLE FSQ LOGGING 
    tput sgr0     # restore term. settings
    tput cnorm    # normal cursor
    echo
    echo Use Fldigi FSQ Config to enable the heard log.
    echo Then restart Fldigi
    sleep 10
    exit
  fi
  #heardFile=fsq_heard_log.*

# WE ARE GOING TO GO GRAB THIS STATION'S CALLSIGN
# FROM THE FLDIGI CONFIG FILE
CONFIG_FILE=~/.fldigi-$LR_CHANNEL/fldigi_def.xml
while read line; do
  if [[ $line == '<'MYCALL'>'* ]];then
    myCall=$line
    myCall=${myCall#*>} # everything after the first >
    myCall=${myCall%<*} # everything before the first <
  fi
done <$CONFIG_FILE

# RENAME THE TERMINAL WINDOW
echo -ne '\033]0;'Smart List 'for' fsq_$myCall' ['$LR_CHANNEL' radio]\007'

function showTemp {
cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
echo -ne '\033]0;CP: '$((cpu/1000)) 'c ['$LR_CHANNEL' radio]\007'
}



# SET UP SOME BACKGROUND AND FOREGROUND COLORS
# TO EXPERIMENT WITH ... SOME OF THESE WE DON'T USE
    FG_BLACK="$(tput setaf 0)"
    BG_BLACK="$(tput setab 0)"
    FG_RED="$(tput setaf 52)"
    BG_RED="$(tput setab 52)"
    FG_GREEN="$(tput setaf 47)"
    BG_GREEN="$(tput setab 42)"
    BG_GRAY="$(tput setab 237)"
    FG_YELLOW="$(tput setaf 11)"
#    FG_YELLOW='\033[1;33m'
    BG_YELLOW="$(tput setab 11)"
    FG_BLUE="$(tput setaf 244)"
    BG_BLUE="$(tput setab 17)"
#    BG_BLUE="$(tput setab 101)"
    FG_MAGENTA="$(tput setaf 5)"
    BG_MAGENTA="$(tput setab 5)"
    BG_WHITE="$(tput setab 47)"
    FG_CYAN="$(tput setaf 36)"
    BG_CYAN="$(tput setab 46)"
    FG_WHITE="$(tput setaf 15)"
    BG_WHITE="$(tput setab 37)"
#    FG_PUTTY="$(tput setaf 24)" # found this one by trial and error
    FG_PUTTY="$(tput setaf 244)" # found this one by trial and error


defaultBG=17         #BACKGROUND
defaultHOT=11        #LESS THAN 10 MINUTE & USER PROMPTS
defaultWARM=10       #LESS THAN 60 MINUTES
defaultCOLD=15       #LESS THAN 24 HOURS
defaultSTALE=24      #MORE THAN 24 HOURS
blink_newGuy=0       #BLINK JUST HEARD FOR 5 SEC.  0=NO/1=YES

configFile="$COMMON_DIR/smart_heard.conf"
configChanged="$COMMON_DIR/smart_heard_config.changed"

colorToChange=0
#rm $configFile
function writeConfigFile {
  echo 'background,'$defaultBG >> $configFile
  echo 'listed_hot,'$defaultHOT >> $configFile
  echo 'listed_warm,'$defaultWARM >> $configFile
  echo 'listed_cold,'$defaultCOLD >> $configFile
  echo 'listed_stale,'$defaultSTALE >> $configFile
  echo 'blink_newGuy,'$blink_newGuy >> $configFile
}

  if [[ ! -f $configFile ]]; then
    echo 'Writing default config file...'
    writeConfigFile
    sleep 2
  fi

function readConfigFile {
  while IFS=, read -r temp thisColor; do
    #echo $temp' '$thisColor
    case $temp in
      'background')
#         echo 'BG='$thisColor
          defaultBG=$thisColor
          BG_COLOR="$(tput setaf $thisColor)"

          ;;
      'listed_hot')
#         echo 'listed_hot='$thisColor
          defaultHOT=$thisColor
          HOT_COLOR="$(tput setaf $thisColor)"
          ;;
      'listed_warm')
#          echo 'listed_warm='$thisColor
          defaultWARM=$thisColor
          WARM_COLOR="$(tput setaf $thisColor)"
          ;;

      'listed_cold')
#         echo 'listed_cold='$thisColor
          defaultCOLD=$thisColor
          COLD_COLOR="$(tput setaf $thisColor)"
          ;;
      'listed_stale')
#          echo 'listed_stale='$thisColor
          defaultSTALE=$thisColor
          STALE_COLOR="$(tput setaf $thisColor)"
          ;;
      'blink_newGuy')
#          echo 'blink_newGuy='$thisColor
          blink_newGuy=$thisColor
          ;;
   esac

  done <$configFile
#sleep 4
thisColor=$defaultBG
BG_COLOR="$(tput setab $thisColor)"

}

readConfigFile



#####################################################################
# Although 'Clear' appears to clear the screen, it does not
# clear the terminal window buffer and the scroll bar rolls
# back the old data. This function clears the buffer and prevents that
#
function setScreen {
#exit
    printf "\033c"       # clear terminal window buffer
    echo -n ${BG_COLOR}   # back ground color
    tput civis           # turn off the cursor
    tput bold
    tput clear
    numCols=$COLUMNS
    halfCols=$((numCols/2))
    halfCols=$((halfCols-2))
    numCols=$((numCols-2))
    showSplash
}


##############################################
# THESE NEXT THREE FUNCTIONS ALLOW THE USER
# TO CHANGE THE WIDTH OF THE WINDOW AND STILL
# HAVE A NICE SPASH SCREEN AND TOP HEADING
##############################################

# PAD REST OF LINE TO EDGE OF WINDOW
# WE PASS THE NUMBER OF CHARACTERS
# JUST PRINTED TO THIS FUNCTION SO
# WE CAN PAD OUT THE LINE WITH A GRAY
# BACKGROUND COLOR INSTEAD OF THE DEFAULT
# COLOR

function padLine() {
    endSpot=$1
    echo -n ${BG_BLACK}' '
    while [ $endSpot -le $numCols ]
    do
      echo -n ' '
      endSpot=$((endSpot+1))
    done
   
}


# PAD THE LINE WITH DOTS  ::::  FOR THE SPLASH BAR
# NUMBER OF CHARACTERS IS DETERMINED BY HALF OF THE NUMBER
# OF COLUMNS IN THE WINDOW. WE COUNT THEM HERE SO WE CAN
# PRINT THEM AGAIN AT THE END OF THE LINE WITH zipLine.
indentCount=0 #defined here to make it global

function indent() {
    endSpot=$1
    echo -n ${FG_WHITE}${BG_GRAY}' '
    counter=0
    while [ $endSpot -le $halfCols ]
    do
      echo -n ':'
      endSpot=$((endSpot+1))
      counter=$((counter+1))
    done
    echo -n ' '
    indentCount=$counter
}

# JUST LIKE INDENT BUT THIS TIME WE PUT THE DOTS
# AT THE END OF THE LINE. WE COUNTED THEM WHEN
# THEY WERE PRINTED IN FRONT OF THE TEXT.

function zipLine() {
    endSpot=$1
    echo -n ${BG_COLOR}${BG_GRAY}' '
    counter=0
    while [ $counter -lt $indentCount ]
    do
      echo -n ':'
      counter=$((counter+1))
    done
   echo ' '
}

homeOK=false # too many lines to show this prompt
function showSplash {

    indent 13
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '  FSQ Smart Heard List  '
    zipLine
    homeOK=true
  if [ $secondTime == true ]; then
    # title splash is shown for only 3 seconds
    refreshCount=$((refreshInterval-3))

    homeOK=false
    indent 13
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '        by WB7FHC       '
    zipLine
    indent 13
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '  Version Date '$V_DATE' '
    zipLine
    if [ $firstTime == false ]; then
      secondTime=false
    fi
    firstTime=false
  fi
 echo ${BG_COLOR}

seedNames=$COMMON_DIR/seed.names
  if [[ -f $seedNames ]]; then
yad --image dialog-question\
    --title Alert\
    --button=YES:0\
    --button=NO:1\
    --posy=200\
    --posx=200\
    --text "We found a local hams look-up table for your area. Would you like to import it?"
  choice=$?
  case $choice in
    0) cp $seedNames $OPS_NAMES
       i=0
       while IFS=, read -r thisCall thisName; do
         let i++
       done < $seedNames
       echo $i "names imported."
       ;;
    1) echo "No names imported."
       ;;
  esac
  mv $seedNames $seedNames'x'
fi
}

# THE FOLLOWING LOGIC ALLOWS US TO PUT UP A SPASH SCREEN
# THE FIRST TIME WE LAUNCH AND THEN SWITCH TO A SIMPLE
# ONE LINER AFTER THAT
firstTime=true
secondTime=true
setScreen # clears screen and window buffer

  tempFile=hold.dat  # allows us to put newest entries on top of list

  # jump start on refresh cycle so header isn't only thing in window.
  refreshCount=$((refreshInterval-1))

  # find out the last time the heard log was changed
  # we check it later to see if the file has been updated

  thisStamp=$(stat $heardFile -c %Y)
  lastStamp=$thisStamp # when these two don't match
                       # we know something has happened

  # now we do the same thing with the skimmer file
  currentSkimmerStamp=$(stat $SKIMMER_FILE -c %Y)
  lastSkimmerStamp=$currentSkimmerStamp 


########################################################
# LOOK UP THE OP'S NAME IN OUR CSV FILE
# (APPOLOGIES TO OTHER GENDERS)
#
function findHisName {
  hisName="....." # this string will be used when the name is unknown

 # we keep reading the whole list even after the name is found
  # this means we can correct a name by simply adding it again
  # later in the list ... we will use the last match found
  while IFS=, read -r thisCall thisName; do
    if [[ $thisCall == $lastGuy ]]; then
       hisName=$thisName
       if [[ $SHOW_RADIO == 'show' ]]; then
         hisName=$RADIO' '$thisName
       fi
      # we will show this user's name as "me"
      if [[ $thisCall == $myCall ]]; then
        hisName='me'
        if [[ $SHOW_RADIO == 'show' ]]; then
          hisName=$RADIO' me'
        fi
      fi
    fi
  done <$OPS_NAMES
  if [[ $SHOW_RADIO == 'show' ]]; then
    hisName=$RADIO' '$thisName
  fi


}

function doTheInsert {
         stty echo     # restore echo
         tput el       # clear this line if needed
         # user must type line exactly as it will appear in csv file
         # currently this version does not support a backspace !!!
         echo
         echo -n ${WARM_COLOR}" Enter <Callsign>,<Name> "
         read hisName

         if [[ $hisName > ' ' ]]; then
           echo $hisName >>  $OPS_NAMES
         fi
         echo -n ${COLD_COLOR}
         echo 'added '$hisName # note this string is actually
                               # a call and a name separted
                               # by a comma!
         refreshList
}

###############################################
# CONFIRM THE ESCAPE KEY
# Only quit on Y or y
# If no key is pressed program continues in 5 seconds

function confirmQuit {
        tput clear
	echo ${HOT_COLOR}
	echo " Are you sure?"
	echo " Touch [y] to quit, any key to continue"
        read -s -n1 -t 5  key  # 5 seconds to do it
        if [ "$key" == 'Y' ] || [ "$key" == 'y' ]; then
         tput sgr0     # restore term. settings
         tput clear    # clear window
         tput cnorm    # normal cursor
         echo bye-bye
	 sleep 1
         exit    # bye-bye we're outa here
        fi
}

function skinsDialog {
counter=0
echo "  0 <<< CANCEL >>>"

# List our skin files
  for file_name in $COMMON_DIR/*.skin; do
	thisSkin=${file_name##/*/}
	thisSkin=${thisSkin%.*}
        counter=$((counter+1))
        if [[ $counter -lt 10 ]];then
	   echo -n ' '
	fi
	echo ' '$counter' '$thisSkin
  done
        counter=$((counter+1))
        if [[ $counter -lt 10 ]];then
	   echo -n ' '
	fi
	echo ' '$counter' Pick your own colors!'


echo "Enter the number of your choice"
read fileNum
	  if [[ $fileNum == $counter ]]; then
	    lxterminal -e $COMMON_DIR/color_picker.sh
	  fi


pickerFlag=$COMMON_DIR/custom.skin
counter=0
  for file_name in $COMMON_DIR/*.skin; do
        counter=$((counter+1))
       if [[ $counter == $fileNum ]]; then
	  cp $file_name $configFile
	  readConfigFile
       fi
  done
  refreshList
#	sleep 6
}


################################################
# WE SCAN THE KEYBOARD LOOKING FOR STROKES WITH
# ESCAPE KEY SEQUENCES THESE ARE THE NAV KEYS
#

function scanKeyboard { 
  navKey=''
   read -s -n1 -t 1  key  # 1 second to do it
   # if the keyboard doesn't have an [insert] use the ^
   if [ "$key" == '^' ]; then
     doTheInsert
   fi

# THE ARROW KEYS BEGIN WITH AN ESCAPE
   if [ "$key" == $'\e' ]; then
       yesEscape=1
       read -sN2 -t 0.0002 a2 a3
       navKey+=${a2}${a3} # catch the next two characters in the sequence
       if [[ $a2 == '['* ]]; then
         yesEscape=0
       fi
       #echo $navKey

       # [Home] key is used to open Skins Dialog
       if [ "$navKey" == "[H" ]; then  # insert
         read -sN1 -t  0.0001 a2  # strip off the ~
         tput clear
         echo "Opening Skins Dialog"
	 skinsDialog
         sleep 3
       fi

       # [Insert] key is used to add new calls and names to csv list
       if [ "$navKey" == "[2" ]; then  # insert
         read -sN1 -t  0.0001 a2  # strip off the ~
         doTheInsert
       fi

      if [ "$navKey" == "[3" ]; then #delete
         read -sN1 -t  0.0001 a2  # strip off the ~
         stty echo     # restore echo
         tput el       # clear this line if needed
         echo -e ${WARM_COLOR}"\n Enter the number of the line"
         echo -n ${WARM_COLOR}" you want to delete: "
         read delNum
         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it happens to exist
         fi
         j=0
         while IFS=, read thisGuy hisStamp hisDate hisTime hisName; do
           j=$((j+1))
          # count them and write them to the temp file
           # skipping the number the user entered
           if [[ $j != $delNum ]]; then
             echo $thisGuy','$hisStamp','$hisDate','$hisTime','$hisName >> $tempFile
           fi
         done <$ourFile
         mv $tempFile $ourFile  # rename the temp file
         refreshList
      fi

      # use up arrow to increase refresh interval
       if [ "$navKey" == "[A" ]; then  #Up Arrow
         read -sN1 -t  0.0001 a2  # strip off the ~
         refreshInterval=$((refreshInterval+5))

         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it exists
         fi
         refreshList
         echo -e "\n refreshInterval: "$refreshInterval" seconds"
       fi

      # use down arrow to decrease refresh interval
       if [ "$navKey" == "[B" ]; then  #Down Arrow
         read -sN1 -t  0.0001 a2  # strip off the ~
         if ((refreshInterval>5)); then
            refreshInterval=$((refreshInterval-5))
         fi

         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it exists
         fi
         refreshList
         echo -e "\n refreshInterval: "$refreshInterval" seconds"
       fi

      # use right arrow to show dates and times
       if [ "$navKey" == "[C" ]; then  # Right Arrow
         read -sN1 -t  0.0001 a2  # strip off the ~
         includeDT=1

         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it exists
         fi
         refreshList
       fi

      # use left arrow to hide dates and times
       if [ "$navKey" == "[D" ]; then  # Left Arrow
         read -sN1 -t  0.0001 a2  # strip off the ~
         includeDT=0
         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it exists
         fi
         refreshList
       fi

       # [PgUp] key is used to switch to shorter list of stations
       if [ "$navKey" == "[5" ]; then  # page up
          read -sN1 -t  0.0001 a2  # strip off the ~
          if (( fullList > 0 )); then
            fullList=$((fullList-1))
          fi

          if [[ -f $tempFile ]]; then
            rm $tempFile # delete this file if it exists
          fi
          refreshList
       fi

       # [PgDown] key is used to switch to longer list of stations
       if [ "$navKey" == "[6" ]; then  # page down
         read -sN1 -t  0.0001 a2  # strip off the ~
         if (( fullList < 2 )); then
           fullList=$((fullList+1))
         fi
         if [[ -f $tempFile ]]; then
           rm $tempFile # delete this file if it exists
         fi
         refreshList
       fi
     fi

   # if only the [Esc] key was pressed we shut down the script
   if (( yesEscape == 1 )); then
     confirmQuit
     # we don't come back if they confirm the quit
     # if we do come back we clear the escape and continue
     yesEscape=0
     refreshList
   fi 

}

##################################################################
function check4OutGoing {
  #WE USED TO USE THE GPIO PINS TO TELL WHEN WE XMIT
  #THAT DOES NOT WORK ON THE PI4 ... SO NOW WE ARE GOING
  #TO SKIM THE FLDIGI LOG FILE. IF WE HAVE JUST XMITED
  #THE LAST LINE IN THE FILE WILL BEGIN WITH 'TX'

  currentSkimmerStamp=$(stat $SKIMMER_FILE -c %Y)
  if [[ currentSkimmerStamp -gt lastSkimmerStamp ]]; then
      #echo file changed
      lastSkimmerStamp=$currentSkimmerStamp
      thisStamp=$lastSkimmerStamp
      checkTX
  fi
#sleep 5

}

#check to see if the log file has been stopped and restarted
# CURRENT VERSION DOES NOT USE THIS FUNCTION
function checkHeardSwap {
#  if [[ -f $heardSwap ]]; then
#    clear
##    echo -n ${WARM_COLOR}
#    echo '     Log file has been restarted'
#    sleep 3
#    mv $heardSwap fsq_heard_log.text
#  fi
echo checkHeardSwap
}

# IF THE CONFIG CHANGED FILE EXISTS
# READ THE NEW COLORS AND DELETE IT
function check4ConfigChange {
  #HAS THE CONFIG FILE CHANGED?
  if [[ -f $configChanged ]]; then
    readConfigFile
    rm $configChanged
    #echo 'change file removed'
    #sleep 3
    refreshList
  fi

}

#############################################
# WE REPEATEDLY CHECK FLDIGI'S HEARD LOG TO
# SEE IF ANYTHING NEW HAS BEEN WRITTEN TO IT
# WE ALSO SCAN THE KEYBOARD AND CHECK THE
# FOR TX ONCE EACH SECOND. IF NONE OF THESE
# THINGS HAPPEN WE REFRESH THE LIST
# AT THE END OF THE INTERVAL TO UPDATE THE TIMES.
#
function waitForOne {
  # Loop here until the file's time stamp changes
#echo waiting
#sleep 5
while [[ $thisStamp == $lastStamp ]]
    do
      #checkHeardSwap
      check4OutGoing   #GO SEE IF WE XMITTED
      check4ConfigChange

      thisStamp=$(stat $heardFile -c %Y)
      scanKeyboard
      refreshCount=$((refreshCount+1))
      if ((refreshCount>=refreshInterval)); then
        if [[ -f $tempFile ]]; then
          rm $tempFile # remove this file if it exists
        fi
        refreshList
      fi
      if [[ $SHOW_HOW_HOT == "true" ]]; then
        tempCount=$((tempCount+1))
        if ((tempCount==60)); then
	  showTemp
	  tempCount=0
        fi
      fi
    done
    lastStamp=$thisStamp

}

################################################
# WE KNOW THE LOG FILE HAS CHANGED SO WE
# GO COLLECT THE CALLSIGN OF THE LAST ENTRY
# .... to the hackers: this function also
# .... reads the signal rpt (snr) but we
# .... never use it. If you want to, have at it!
#

function checkTX {
 input=$SKIMMER_FILE
 counter=0

 while IFS= read -r line
 do
   counter=$((counter+1))
   last_line=$line
#   echo "$counter $last_line"
 done <"$input"
# echo "----------------------------"
#GRAB THE FIRST TWO CHARACTERS
 tx=$(echo $last_line | cut -d' ' -f1)
#  echo "$tx"

 if [[ $tx == "TX" ]]
  then
   lastGuy=$myCall
   hisName="me"
   echo -n ${HOT_COLOR}
   justHeardSomeone
   counter=0

   spotNewGuy
   sleep 3
 fi
}





function findLastLine {
#sleep 4
  while IFS=, read -r thisDate thisTime thisCall snr; do
    #echo $thisDate' '$thisTime' '$thisCall' '$snr
    lastGuy=$thisCall
  done <$heardFile

}


##########################################
# TEXT CLUE TO SHOW SHORT LIST OPTION
#
function shortListPrompt {
  echo -n ${HOT_COLOR}
  if [[ $fullList == 0 ]]; then
    echo  " [PgDwn] to show last 20"
  fi

  if [[ $fullList == 1 ]]; then
    echo  " [PgDwn] to show all "$lineNum
    echo  " [PgUp] to show last 24hrs"
  fi

  if [[ $fullList == 2 ]]; then
    echo  " [PgUp] to show last 20"
  fi


  if [[ $includeDT == 1 ]]; then
    echo -n " [LF Arrow] to hide dates & times"
  else
    echo -n " [RT Arrow] to show dates & times"
  fi

if [ $homeOK == true ]; then

  if [[ $insert == 'name found' ]]; then
    echo
    echo ' [Home] to change skins '
  fi
fi

  # LET USER KNOW HOW TO ADD A MISSING NAME
  if [[ $insert != 'name found' ]]; then
    echo
    echo ' Press [INSERT] to Enter Name for '$insert
  fi
}

#######################################
# CALCULATE THE TIMES AND TEXT COLORS
#
function calculateTimes {
  #calculate current time segments
  duration=$((currentStamp - hisStamp))
  mins=$(($duration / 60))
  secs=$(($duration % 60))
  hours=$(($mins / 60))
  mins=$(($mins % 60))
  days=$(($hours / 24))
  lineNum=$((lineNum+1))
  if [[ $fullList == 0 ]]; then
    if (( days > 0 )); then
      max=$lineNum
    fi
  else
    max=99
    if [[ $fullList == 1 ]]; then
       max=21
    fi

  fi

  # Determine text color based on times
  # Color is already Yellow
  if  ((mins > 9)); then
    echo -n ${WARM_COLOR} # less than 1 hour
  fi
  if  ((hours > 0)); then
    echo -n ${COLD_COLOR} # less than 24 hours
  fi
  if ((days > 0)); then
    hours=$(($hours % 24))
    echo -n ${STALE_COLOR}  # one day or more
  fi
}


#######################################
# WE UPDATE THE LIST ON THE SCREEN
# AT THE END OF EACH REFRESH INTERVAL,
# SOONER IF A STATION IS HEARD OR A
# KEY IS PRESSED
#
function refreshList {

  refreshCount=0
  insert="name found"
  if [ $firstTime == true ]; then
    showSplash
    firstTime=false
    refreshCount=$((refreshInterval-4))

  fi


  setScreen
  lineNum=0
  echo -n  ${HOT_COLOR} # for heard less than 10 mins
  currentStamp=`date +" %s"` # epoch time (seconds since Jan. 1, 1970)

  if [[ $lastGuy != 'nobody' ]]; then
    justHeardSomeone
  fi

  while IFS=, read thisGuy hisStamp hisDate hisTime hisName; do
    # We don't reprint the last one found he is already there
    # This test will also eliminate duplicates in list that might
    # occur if user aborts script at an awkward moment
    if [[ $thisGuy != $lastGuy ]]; then
      # stuff to do if we didn't find a name
      if [[ $hisName == '.....' ]]; then
        # check again to see if his name has since been added
        holdOne=$lastGuy  # we need to hang on to this call sign
        lastGuy=$thisGuy
        findHisName
        lastGuy='nobody'
        insert='name found'
        if [[ $hisName == '.....' ]]; then
          # name is still not there
          insert=$thisGuy
        fi
        lastGuy=$holdOne # restore the call sign that we hung on to
      fi

      # write data to temp file
      if [[ $thisGuy>'' ]]; then
        echo $thisGuy','$hisStamp','$hisDate','$hisTime','$hisName >> $tempFile
      fi

      calculateTimes

      if ((lineNum < max )); then
        printData
      fi
    fi
  done <$ourFile


  shortListPrompt

  # rename temp file to the working version
  if [[ -f $tempFile ]]; then
    mv $tempFile $ourFile
  fi
}



###########################################
# NOW WE SHOW THE LISTING ON THE SCREEN
#
function printData {
    echo -n ' '
    if ((lineNum < 10)); then
      echo -n ' '
    fi
    echo -n $lineNum' '

    # USER HAS THE CHOICE OF WHETHER TO SHOW
    # DATES AND TIMES IN THE LISTING.  USE
    # LEFT AND RIGHT ARROWS TO TOGGLE ON AND OFF.
    if ((includeDT == 1)); then
      echo -n $hisDate' '$hisTime
    fi

    echo -n ' '$thisGuy
    echo -n -e "\t" # tab
    if ((days>0)); then
      if ((days<10)); then
        echo -n ' '
      fi
      echo -n $days'd '
    fi

    if ((hours <10)); then
      if ((days >0)); then
        echo -n '0'
      else
        echo -n ' '
      fi
    fi
    echo -n $hours'h '
    if ((mins <10)); then
      echo -n '0'
    fi
    echo -n $mins'm '
    if ((days <1)); then
      if ((secs <10)); then
        echo -n '0'
      fi
      echo -n $secs's '
    fi
    echo  $hisName
}

#############################################################
# FIND OUT WHEN WE HEARD THIS STATION THE LAST TIME
#

function lastTimeHeard {
  while IFS=, read thisGuy hisStamp hisDate hisTime hisName; do
    if [[ $thisGuy == $lastGuy ]]; then
      calculateTimes
    fi
  done <$ourFile
}

###############################################################
# A STATION JUST APPEARED AT THE END OF THE MONITOR LOG
# LET'S GO SHOW WHO IT WAS AT THE TOP OF THE WINDOW
#

function justHeardSomeone {
  # Check to see if this is a new station
  # newStation=1 ... he is on the list
  # newStation=0 ... he is not on list
    newStation="$(grep -c -w $lastGuy $ourFile)"
    clear
    showSplash
    echo -n ${HOT_COLOR}
    if [ "$newStation" = '0' ]; then
      echo  '  1  '$lastGuy' '$hisName' first time on our list'
    else
      if [ "$blink_newGuy" == '1' ]; then
        #Blink the guy's call sign for a few seconds
        echo -n -e '  1  \e[5m'$lastGuy'\e[25m '$hisName' after '
      else
      echo  -n "  1  "$lastGuy" "$hisName" after "
      fi

      lastTimeHeard
      echo -n ${HOT_COLOR}
      if ((days>0)); then
        echo  -n $days' day'
        if ((days>1)); then
          echo -n 's'
        fi
        echo
      else
        if ((hours>0)); then
          echo -n $hours' h '
          if ((mins>0)); then
           echo $mins' m '
          else
           echo
          fi
        else
          if ((mins<1)); then
            echo 'less than 1 minute'
          else
            echo  -n $mins' minute'
            if ((mins>1)); then
              echo 's'
            else
              echo
            fi
          fi
        fi
      fi
    fi
    refreshCount=$((refreshInterval-5)) # show this line for only 5 seconds
    lineNum=1
}


###########################
# FIND OUT WHO JUST XMITTED
# AND WRITE HIM AT THE TOP
# OF OUR TEMP FILE
#
function spotNewGuy {
  #clear
  findHisName
  echo -n $lastGuy','$thisStamp',' >> $tempFile
  echo -n `date -d @$thisStamp +"%m-%d,%R,"` >> $tempFile
  echo $hisName >> $tempFile

  refreshList
  lastGuy="nobody"
}

#############################
# CHECK IF AN INSTANCE OF
# THIS SCRIPT IS ALREADY
# RUNNING
function checkAlreadyRunning () {
	if pidof -o %PPID -x $(basename "$0") >/dev/null
	then
		# An instance is already running. Give it focus.
		wmctrl -R "$(basename "$0")"
		exit 0
	fi
}

#############################
# MAIN PROGRAM
#
# Ensure only one instance of this script is running.
checkAlreadyRunning

#############################
# OUR MAIN LOOP RUNS FOREVER
#
while true; do
  waitForOne
  findLastLine
  spotNewGuy
done


