# WB7FHC's FSQ Smart Heard

## Installation
Pick either Easy or Manual Installation.

### Easy Installation (for Nexus DR-X users)
- Make sure your Pi is connected to the Internet.
- Click __Raspberry > Hamradio > Update Pi and Ham Apps__.
- Check __smart-heard__, click __OK__.

### Manual Installation
- Make sure your Pi is connected to the Internet.
- Open a Terminal and run these commands:

		cd ~
		rm -rf smart-heard/
		mkdir -p ~/WB7FHC
		git clone https://github.com/NexusDR-X/smart-heard
		cp smart-heard/*.sh WB7FHC/

	If this is your first time installing smart-heard, or if you want to overwrite your existing callsign-to-names mapping file and use the downloaded file instead, then also run this command:
	
		cp smart-heard/*.csv WB7FHC/

### Configure Fldigi

1. Run Fldigi (right or left)
1. Select __Configure > Config Dialog > Modem > FSQ__
1. Click __Enable__ next to the __Heard log fsq_heard_log.txt__ field.
1. Click __Save__, click __Close__.
1. Repeat this procedure for the other Fldigi (right or left) instances as desired.

#### OPTIONAL: Autostart the smart-heard script when Fldigi starts

If you want to automatically run smart-heard whenever Fldigi starts, follow these steps.

1. In Fldigi: __Configure > Config Dialog > Misc > Autostart__

	You'll notice 3 fields, labeled __Prog 1:__, __Prog 2:__, __Prog 3:__. Pick one of those fields that is empty, and add this text into the field:
	
		/home/pi/WB7FHC/smart_heard.sh

1. Check the __Enable__ box.
1. Click the __Test__ button and make sure the script launches. If it works, close the smart-heard script.
1. Click __Save__, then __Close__.

## Running the script

If you configured Fldigi autostart in the previous step, launch Fldigi and smart-heard should start. Otherwise, select __Smart Heard__ from the __Raspberry > Hamradio__ menu.

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

### TEXT COLORS:
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


