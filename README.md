# WB7FHC's FSQ Smart Heard

## Installation
Pick either Easy or Manual Installation.

### Easy Installation (for Nexus DR-X users)
- Make sure your Pi is connected to the Internet.
- Click __Raspberry > Hamradio > Update Pi and Ham Apps__.
- Check __smart-heard__, click __OK__.

### Manual Installation (for Nexus DR-X beta testers)
- Make sure your Pi is connected to the Internet.
- Open a Terminal and run these commands:

		cd /usr/local/src/nexus
		git clone https://github.com/NexusDR-X/smart-heard
		smart-heard/nexus-install

### Configure Fldigi

Installing FSQ Smart Heard by the Easy or Manual installation methods above will automatically make 3 changes in each in instance of Fldigi (left, right) if those changes have not been already made:

- RX/TX logging is enabled

	This setting is in Fldigi __File > Text Capture >  Log all RX/TX text [checked]__
	
- FSQ Heard logging is enabled

	This setting is in Fldigi __Configure > Config Dialog > Modem > FSQ__
	
- Smart Heard autostart added

	This setting is in Fldigi __Configure > Config Dialog > Misc > Autostart__

## Running the script

If installed as per previous instructions, smart_heard will automatically start when you run Fldigi. You can start it manually from a Terminal by running this command:

	WB7FHC/smart_heard.sh

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

### DEFAULT TEXT COLORS:

- __YELLOW__ ... station heard less than 10 minutes ago

- __GREEN__  ... station heard less than 1 hour ago

- __WHITE__  ... station heard within last 24 hours

- __BLUE__   ... station not heard in last 24 hours

### SMART LIST FILES

- __smart_heard.sh__
     
	The shell script. Located @ /home/pi/WB7FHC/smart_heard.sh

- __fsq_heard_log.txt__

	List of all stations heard with UTC and SNR created by Fldigi located @ /home/pi/.fldigi/temp/fsq_heard_log.txt

- __fldigi<date>.log__
     
	List of all text sent to the receive window in fldigi created by Fldigi if RX/TX logging is on located @ /home/pi/fldigi-left/fldigi<date>.log or located @ /home/pi/fldigi-right/fldigi<date>.log. <date> will be date that log is started we use newest log

- __smart_heard.list__

	Working file for this script contains:

		call,epoch time,op name
   
   Located @ ~/WB7FHC/smart_heard.list

- __temp.dat__
     
   Temporary file built from smart_heard.list will become smart_heard.list. Located @ ~/WB7FHC/temp.dat

	This file is short lived and is normally not seen in directory. The script will delete file if it exists at wrong time

- __fsq_names.csv__

	Lookup table to match callsign and op's name located @ ~/WB7FHC/fsq_names.csv


