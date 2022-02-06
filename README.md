# WB7FHC's FSQ Smart Heard

## Installation
Pick either the Easy or Manual Installation.

### Easy Installation (for Nexus DR-X users)
- Make sure your Pi is connected to the Internet.
- Click __Raspberry > Hamradio > Update Pi and Ham Apps__.
- Check __smart-heard__, click __OK__.

### Manual Installation (for Nexus DR-X users who are testing Smart Heard)
- Make sure your Pi is connected to the Internet.
- Open a Terminal and run these commands:

		cd /usr/local/src/nexus
		rm -rf smart-heard
		git clone https://github.com/NexusDR-X/smart-heard
		smart-heard/nexus-install

Installing __FSQ Smart Heard__ by the Easy or Manual installation methods above will automatically make 3 changes in each in instance of Fldigi (left, right) if the changes have not been already made:

- RX/TX logging is enabled

	This setting is in Fldigi __File > Text Capture >  Log all RX/TX text [checked]__
	
- FSQ Heard logging is enabled

	This setting is in Fldigi __Configure > Config Dialog > Modem > FSQ__
	
- Smart Heard autostart added

	This setting is in Fldigi __Configure > Config Dialog > Misc > Autostart__

## Running the script

If installed as per the instructions above, __smart_heard.sh__ will automatically start when you run Fldigi. You can start it manually from a Terminal by running this command:

	~/WB7FHC/smart_heard.sh

Only one instance of `smart_heard.sh` will run at a time.

### KEYBOARD COMMANDS

- __[Escape]__ … stop running script

- __[Insert]__ … add new call and name to fsq_names.csv. This can also be done with __[^]__ if your keyboard has no __[Insert]__

- __[Delete]__ … remove a call from your heard list

- __[PgDwn]__ … show more stations heard

- __[PgUp]__ … show fewer stations heard

- __[RT Arrow]__ … show dates and time on the display

- __[LT Arrow]__ … hide dates and time on the display

- __[UP Arrow]__ … increase the update interval in steps of 5 seconds

- __[DN Arrow]__ … decrease the update interval to minimum of 5 seconds

- __[Home]__ … change skins (colors)

### DEFAULT TEXT COLORS:

- __YELLOW__ ... station heard less than 10 minutes ago

- __GREEN__  ... station heard less than 1 hour ago

- __WHITE__  ... station heard within last 24 hours

- __PUTTY__   ... station not heard in last 24 hours

### SMART LIST FILES

- __fsq_heard_log.txt__ ... $heardFile
     
     list of all stations heard with UTC and SNR
     created by Fldigi
     located @ /home/pi/.fldigi-left/temp/fsq_heard_log.txt

- __fldigi<date>.log__ ... $skimmerFile
     
     list of all text sent to the receive window in fldigi
     created by Fldigi if RX/TX logging is on
     located @ /home/pi/.fldigi-left/fldigi<date>.log
     or
     located @ /home/pi/.fldigi-right/fldigi<date>.log
     <date> will be date that log is started. We use newest log.

- __smart_heard.list__ ... $ourFile
     
     working file for this script
     contains:
     
         call,epoch time,op name
         
     located @ ~/WB7FHC/smart_heard.list

- __hold.dat__ ... $tempFile
     
     temporary file built from smart_heard.list
     will become smart_heard.list
     located @ ~/WB7FHC/hold.dat
     this file is short lived and is normally
     not seen in the directory ... script will delete
     file if it exists at wrong time

- __fsq_names.csv__ ... $OPS_NAMES
     
     lookup table to match callsign and op's name
     located @ ~/WB7FHC/fsq_names.csv
     If a call sign appears more than once in the list
     the latest entry will be used.

- __fldigi_def.xml__ ... $CONFIG_FILE
     
     contains the Fldigi configuration settings
     created by Fldigi
     located @  /home/pi/.fidigi-left/fldigi_def.xml

- __seed.names__     ... $seedNames
     
     optional file to import local calls and names
     located @  /home/pi/WB7FHC/seed.names
     If this file exists, user will be given choice to import it.
     If user says yes, this file will copied to fsq_names.csv .
     When user says either yes or no, it is renamed: seed.namesx

- __seed.namesx__  (no variable)
     
     we rename this file after dialog box entry so that
     we are not asked again.
     if fsq_names.csv becomes corrupted user can remove
     the x from the file name and recover the list

