#!/bin/bash

vDate="02-01-22"

#############################################
# FSQ SMART_HEARD CONFIGURATION UTILITY
# THIS OPTIONAL SCRIPT ALLOWS YOU TO CHOOSE
# YOUR OWN COLORS FOR THE FSQ SMART_HEARD LIST
# WB7FHC
# Budd Churchward
# email: budd@wb7fhc.com
############################################

###################################################################
# FILES:
# color_picker.sh
#      This utility
#      Location: ~\WB7FHC\color_picker.sh
#      Use: sudo chmod 755 *.sh
#          to make the script executable
#
# smart_heard.conf
#      stores your settings
#      Location: ~\WB7FHC\smart_heard.conf
#      If this file does not exist, this utility or
#      smart_heard.sh will create it using default values
#      the first time either of them is run
#
# smart_heard_config.changed
#      tells smart_heard.sh to load settings because they have changed
#      Location: ~\WB7FHC\smart_heard_config.changed
#      This file is just a marker. smart_heard.sh simply checks to see
#      if it exists. It deletes if it finds it and reloads the color
#      settings. The contents of the file are never read.
#
# *.skin
#      templates for smart_heard.conf
#      Location: ~\WB7FHC\*.skin
#      These files will appear in the 'Skin List' for smart_heard.sh
#      Using the form: <skinName>.skin the list will only contain the
#      names. Users can edit the skins and save them. When chosen
#      the template is copied to: ~\WB7FHC\smart_heard.conf and the
#      following, short lived, file is written.
#
# smart_heard_config.changed
#      flag that tells smart_heard.sh that there are a new set of colors to load
#      Location: ~\WB7FHC\smart_heard_config.changed
#      This file is very short lived. As soon as smart_heard.sh sees that
#      it exists, it deletes it and then updates it's color set.
#
# 0.custom-<n>.skin
#      user defined templates for smart_heard.conf
#      Location: ~\WB7FHC\0.custom-<n>
#      These files are just like the *.skin files listed above but these
#      are skins defined by the user. 
#      <n> is a number that is incremented each time a new file is saved.
#      The file name begins with '0.' so that these files will appear first
#      in alphabetical order and that the <n> numbers in the name will match
#      the list numbers on the screen.
#
# hold.me
#      created at start-up, this temporary file is a copy of smart_heard.conf
#      Location: ~\WB7FHC\hold.me
#      This file exists so that the user can cancel changes made during a session
#      allowing the config file to roll back to its original state if necessary.
#      This file is deleted when the script quits.
###################################################################


# note to self:
# turn line numbers on with CTRL+3 then SHIFT+3


# SET UP SOME BACKGROUND AND FOREGROUND COLORS
# TO EXPERIMENT WITH ... MOST OF THESE ARE NOT USED
# THESE ARE THE COLORS THAT WERE USED BY THE BUSTER OS
    FG_BLACK="$(tput setaf 0)"
    BG_BLACK="$(tput setab 0)"
    FG_RED="$(tput setaf 31)"
    BG_RED="$(tput setab 41)"
    FG_GREEN="$(tput setaf 42)"
    BG_GREEN="$(tput setab 42)"
    FG_YELLOW="$(tput setaf 11)"
    BG_YELLOW="$(tput setab 43)"
    FG_BLUE="$(tput setaf 34)"
    BG_BLUE="$(tput setab 17)"
    FG_MAGENTA="$(tput setaf 35)"
    BG_MAGENTA="$(tput setab 45)"
    BG_WHITE="$(tput setab 15)"
    FG_WHITE="$(tput setaf 7)"
    FG_CYAN="$(tput setaf 36)"
    BG_CYAN="$(tput setab 46)"
    FG_WHITE="$(tput setaf 37)"
    BG_WHITE="$(tput setab 37)"
    BG_GRAY="$(tput setab 237)"


# DEFAULT COLORS ... THESE WILL BE WRITTEN
# TO smart_heard.conf IF THE FILE DOES
# NOT EXIST

defaultBG=17         #BACKGROUND
defaultHOT=11        #LESS THAN 10 MINUTE & USER PROMPTS
defaultWARM=10       #LESS THAN 60 MINUTES
defaultCOLD=15       #LESS THAN 24 HOURS
defaultSTALE=24      #MORE THAN 24 HOURS
blink_newGuy=0       #BLINK JUST HEARD FOR 5 SEC.  0=NO/1=YES

COMMON_DIR=~/WB7FHC
configFile="$COMMON_DIR/smart_heard.conf"
configChanged="$COMMON_DIR/smart_heard_config.changed"
holdFile="$COMMON_DIR/hold.me"


globalChange=0   # =1 if any thing is changed

colorToChange=0      #FLAG FOR CASE STATEMENTS

# WRITE NEW SETTINGS TO CONFIG FILE
function writeConfigFile {
  echo 'background,'$defaultBG >> $configFile
  echo 'listed_hot,'$defaultHOT >> $configFile
  echo 'listed_warm,'$defaultWARM >> $configFile
  echo 'listed_cold,'$defaultCOLD >> $configFile
  echo 'listed_stale,'$defaultSTALE >> $configFile
  echo 'blink_newGuy,'$blink_newGuy >> $configFile
  #echo 'config changed' >> $configChanged
  touch $configChanged
}

# IF CONFIG FILE DOESN'T EXIST, CREATE ONE
  if [[ ! -f $configFile ]]; then
    echo 'Writing default config file...'
    writeConfigFile
    sleep 2
  fi

# SAVE A COPY OF THE CURRENT CONFIG FILE SO WE CAN
# PUT STUFF BACK IF THE USER CANCELS
  cp $configFile $holdFile

# READ ALL THE SETTINGS IN CONFIG FILE
  while IFS=, read -r tag thisColor; do
    #echo $tag' '$thisColor
    case $tag in
      'background')
#         echo 'background='$thisColor
          defaultBG=$thisColor
          BG_COLOR="$(tput setaf $thisColor)"
          ;;

      'listed_hot')
#         echo 'listed_hot='$thisColor
          defaultHOT=$thisColor
          HOT_COLOR="$(tput setaf $thisColor)"
          ;;

      'listed_warm')
#         echo 'listed_warm='$thisColor
          defaultWARM=$thisColor
          WARM_COLOR="$(tput setaf $thisColor)"
          ;;

      'listed_cold')
#         echo 'listed_cold='$thisColor
          defaultCOLD=$thisColor
          COLD_COLOR="$(tput setaf $thisColor)"
          ;;

      'listed_stale')
#         echo 'listed_stale='$thisColor
          defaultSTALE=$thisColor
          STALE_COLOR="$(tput setaf $thisColor)"
          ;;

      'blink_newGuy')
#         echo 'blink_newGuy='$thisColor
          blink_newGuy=$thisColor
          ;;
   esac

  done <$configFile

# SET UP THE BACKGROUND FOR THE SPASH SCREEN
thisColor=$defaultBG
BG_COLOR="$(tput setab $thisColor)"


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
    echo -n ${BG_GRAY}' '
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
    echo -n ${BG_COLOR}${FG_WHITE}'  '
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
    echo -n ${BG_COLOR}' '
    counter=0
    while [ $counter -lt $indentCount ]
    do
      echo -n ':'
      counter=$((counter+1))
    done
   echo
}

######################################################
#Let's show them what we got!
function updateScreen {
    printf "\033c"  # clear terminal window buffer
    if (( $colorToChange == 0 )) ;then
      BG_COLOR="$(tput setab $thisColor)"
    fi
    FG_WHITE="$(tput setaf 15)"
    echo -n ${BG_COLOR}
    tput civis # turn off the cursor
    tput bold
    tput clear

    numCols=$COLUMNS
    halfCols=$((numCols/2))
    halfCols=$((halfCols-2))
    numCols=$((numCols-2))
    echo #$halfCols $numCols

# PRINT THE FULL SPASH WHEN WERE WORKING THE BACKGROUND COLOR
  if (( $colorToChange == 0 )) ;then
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '                          '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n ' smart_heard Color Picker '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '  Version Date: '$vDate'  '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n ' Budd Churchward - WB7FHC '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '                          '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '  CHANGE DEFAULT COLORS   '
    zipLine
    indent 15
    echo -n ${FG_WHITE}${BG_GRAY}
    echo -n '                          '
    zipLine
    echo
    padLine 0
    echo -n ' Background Color [ '$thisColor' ]'
    endSpot=23

    #bump up counter if the number is two digits or more
    if (( $thisColor > 9 )); then
      endSpot=$((endSpot+1))
    fi
    #bump it up again if it is three drigits
    if (( $thisColor > 99 )); then
      endSpot=$((endSpot+1))
    fi
    padLine $endSpot
 
    echo -n ' Use UP & DOWN arrows to change colors'
    padLine 38    #38 characters in text above
    echo -n ' Use RIGHT arrow to set background color'
    padLine 40
    echo -n ${BG_COLOR}
    padLine 0     #pads out a blank line
  fi

  # DIFFERENT HEADING WITH NO SPLASH FOR ALL THE REST
  if (( $colorToChange > 0 )) ;then
    echo -n ${FG_WHITE}${BG_BLACK}
    padLine 0
    echo -n ' Background [ Color: '$defaultBG' ]'
    endSpot=24
    if (( $defaultBG > 9 )); then
      endSpot=$((endSpot+1))
    fi
    if (( $defaultBG > 99 )); then
      endSpot=$((endSpot+1))
    fi
    padLine $endSpot
    echo -n ' Use UP & DOWN arrows to change text color'
    padLine 42
    echo -n ' Use RIGHT arrow to set next text color'
    padLine 39
    echo -n ' Use LEFT arrow to set prev. text color'
    padLine 39
    padLine 0
    echo ${BG_COLOR}
    echo ' '
    case $colorToChange in
      1)
       echo -n ${BG_BLACK}${FG_WHITE}' [COLOR: '$thisColor'] '
       echo -n ${HOT_COLOR}${BG_COLOR}
       echo ' >>> Text for less than 10 minutes'
       ;;

      2)
       echo -n ${HOT_COLOR}${BG_COLOR}
       echo 'Color '$defaultHOT' Text for less than 10 minutes'
       echo -n ${BG_BLACK}${FG_WHITE}'[ COLOR: '$thisColor' ]'
       echo -n ${HOT_COLOR}${BG_COLOR}
       echo -n ${WARM_COLOR}
       echo ' >>> Text for less than 1 hour'
       ;;

      3)
       echo -n ${HOT_COLOR}${BG_COLOR}
       echo 'Color '$defaultHOT' Text for less than 10 minutes'
       echo -n ${WARM_COLOR}
       echo 'Color '$defaultWARM' Text for less than 1 hour'
       echo -n ${BG_BLACK}${FG_WHITE}'[ COLOR: '$thisColor' ]'
       echo -n ${COLD_COLOR}${BG_COLOR}
       echo ' >>> Text for less than 24 hours'
       ;;

      4)
       echo -n ${HOT_COLOR}${BG_COLOR}
       echo 'Color '$defaultHOT' Text for less than 10 minutes'
       echo -n ${WARM_COLOR}
       echo 'Color '$defaultWARM' Text for less than 1 hour'
       echo -n ${COLD_COLOR}
       echo 'Color '$defaultCOLD' Text for less than 24 hours'
       echo -n ${BG_BLACK}${FG_WHITE}'[ COLOR: '$thisColor' ]'
       echo -n ${STALE_COLOR}${BG_COLOR}
       echo ' >>> Text for more than 24 hours'
       ;;

    esac
  fi

}

updateScreen

# THE NEXT TWO FUNCTIONS ARE CALLED WHEN THE
# USER TAPS THE UP AND DOWN ARROWS TO CHANGE
# THE FOCUSED COLOR
function bumpUp {
    thisColor=$((thisColor+1))
    if (( $thisColor > 255 )); then
        thisColor=0
    fi
    case $colorToChange in
      1)
        HOT_COLOR="$(tput setaf $thisColor)"
        ;;
 
      2)
        WARM_COLOR="$(tput setaf $thisColor)"
        ;;

      3)
        COLD_COLOR="$(tput setaf $thisColor)"
        ;;

      4)
        STALE_COLOR="$(tput setaf $thisColor)"
        ;;

   esac
    updateScreen
}

function bumpDown {
    thisColor=$((thisColor-1))
    if (( $thisColor < 0 )); then
        thisColor=255
    fi
    case $colorToChange in
      1)
        HOT_COLOR="$(tput setaf $thisColor)"
        ;;
      2)
        WARM_COLOR="$(tput setaf $thisColor)"
        ;;

      3)
        COLD_COLOR="$(tput setaf $thisColor)"
        ;;

      4)
        STALE_COLOR="$(tput setaf $thisColor)"
        ;;

 
    esac
    updateScreen
}


# THE FOLLOWING FUNCTION IS CALLED WHEN THE
# USER TAPS THE RIGHT ARROW ... WE STORE THE
# CURRENT COLOR AND SWITCH UP TO THE NEXT ITEM
 function setNewColor {
      rm $configFile
      case $colorToChange in
         0)
           defaultBG=$thisColor
           thisColor=$defaultHOT #set us up for the next color
           HOT_COLOR="$(tput setaf $thisColor)"
           colorToChange=1
           updateScreen
           ;;
         1)
           defaultHOT=$thisColor
           HOT_COLOR="$(tput setaf $thisColor)"
           colorToChange=2
           thisColor=$defaultWARM
           WARM_COLOR="$(tput setaf $thisColor)"
           updateScreen
           ;;
         2)
           defaultWARM=$thisColor
           WARM_COLOR="$(tput setaf $thisColor)"
           updateScreen
           colorToChange=3
           thisColor=$defaultCOLD
           updateScreen
           ;;
         3)
           defaultCOLD=$thisColor
           COLD_COLOR="$(tput setaf $thisColor)"
           updateScreen
           colorToChange=4
           thisColor=$defaultSTALE
           updateScreen
           ;;
         4)
           defaultSTALE=$thisColor
           STALE_COLOR="$(tput setaf $thisColor)"
           updateScreen
           colorToChange=5
           thisColor=$defaultBG
           tput clear
           echo -n ${HOT_COLOR}
           echo "we're done"
           echo "press [escape] to exit"
           echo
           echo "......................................"
           echo
           echo ${HOT_COLOR}'HOT sations last heard in 10 minutes'
           echo ${WARM_COLOR}'WARM sations last heard in 60 minutes'
           echo ${COLD_COLOR}'COLD sations last heard in 24 hours'
           echo ${STALE_COLOR}'STALE sations last heard in over 24 hours'
           echo ${HOT_COLOR}'KEYBOARD PROMPTS'
           echo
           echo "......................................"
           echo
           thisColor=5 #pick blink setting

           echo " Blink the new guy's call sign for 5 seconds? y/n"

           ;;
      esac
   writeConfigFile
}

function sayGoodBye {
   i=1 #counter for incrementing file name
   customFile=$COMMON_DIR/0.custom  # 0. puts file name at top of list

   # only do this if a setting has changed
   if [[ $globalChange == 1 ]] ; then
       while [[ -e $customFile-$i.skin || -L $customFile-$i.skin ]] ; do
         let i++
       done
       customFile=$COMMON_DIR/0.custom-$i.skin

       echo ' '
       echo " Save skin as: "0.custom-$i"?"
       echo " Touch [y] to save"
       echo " Any other key to quit without saving."

       read -s -n1 -t 15  key  # 15 seconds to do it
       if [ "$key" == 'Y' ] || [ "$key" == 'y' ]; then
           # store this as a custom skin
           cp $configFile $customFile
       else
           # restore the original config file
           cp $holdFile $configFile
       fi

       # tell smart_heard.sh to update its colors
       touch $configChanged

       # removed the roll back file
       rm $holdFile

   fi

   tput sgr0     # restore term. settings
   tput clear    # clear window
   tput cnorm    # normal cursor
   echo bye-bye
   exit          # bye-bye we're outa here
}

################################################
# WE SCAN THE KEYBOARD LOOKING FOR STROKES WITH
# ESCAPE KEY SEQUENCES THESE ARE THE NAV KEYS
#
function scanKeyboard { 
  navKey=''
   read -s -n1 -t 1  key  # 1 second to do it

   # When we are asking about blink we test
   # for yYnN
   if [ $thisColor == 5 ]; then
     if [ "$key" == 'y' ] || [ "$key" == 'Y' ]; then
       echo 'blink ON'
       blink_newGuy=1
       setNewColor
     fi
     if [ "$key" == 'n' ] || [ "$key" == 'N' ]; then
       echo 'blink OFF'
       blink_newGuy=0
       setNewColor
     fi
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

      # use right arrow to store the value for permanent use
       if [ "$navKey" == "[C" ]; then  # 'Right Arrow'
         read -sN1 -t  0.0001 a2  # strip off the ~
          if (( $colorToChange > 5 )); then
            sayGoodBye
          fi

          globalChange=1
          setNewColor
       fi

      # use left arrow to back up to the previous color to change
       if [ "$navKey" == "[D" ]; then  # 'Left Arrow'
         read -sN1 -t  0.0001 a2  # strip off the ~
         if (( $colorToChange == 0 )); then
            colorToChange=5
         fi
         colorToChange=$((colorToChange-1))
           case $colorToChange in
             0)
              thisColor=$defaultBG
              ;;

             1)
              thisColor=$defaultHOT
              ;;

             2)
              thisColor=$defaultWARM
              ;;

             3)
              thisColor=$defaultCOLD
              ;;

             4)
              thisColor=$defaultSTALE
              ;;

           esac

         updateScreen
       fi

      # use up arrow to increase color number
       if [ "$navKey" == "[A" ]; then  #'Up Arrow'
         read -sN1 -t  0.0001 a2  # strip off the ~
          if (( $colorToChange < 5 )); then
             bumpUp
          fi
       fi

      # use down arrow to decrease color number
       if [ "$navKey" == "[B" ]; then  #'Down Arrow'
         read -sN1 -t  0.0001 a2  # strip off the ~
          if (( $colorToChange < 5 )); then
             bumpDown
          fi

       fi

   fi
   # if only the [Esc] key was pressed we shut down the script
   if (( yesEscape == 1 )); then
      sayGoodBye
   fi 

}

# LOOP HERE FOREVER
# GO DO STUFF WHEN THERE IS A KEYBOARD EVENT
while true; do
  scanKeyboard
done

