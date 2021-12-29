#!/bin/bash
# Adds/Removes icons to the IceWM desktop toolbar- antiX Linux (adding icons is done using the info from the app's .desktop file) 
# V. 2.4 By PPC, 3/11/2021 adapted from many, many on-line examples
# GPL licence - feel free to improve/adapt this script - but keep the lines about the license and author
# localisation and minor changes added by anticapitalista - 10-12-2020

## My 3 main improvements:
## - The app has not slow start, the big loop through all .desktop files is in the add_icon() function
## - The apps icons are not scalled in several sizes (icons with path have troubles in yad...)
## - The line put in icewm's toolbar file is taken from the icewm's menu

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=icewm-toolbar-icon-manager
#window_icon="/usr/share/icons/papirus-antix/48x48/apps/icewm_editor.png"

###Check if the current desktop is IceWM, if not, exit
desktop=$(wmctrl -m)
if [[ $desktop == *"icewm"* ]]; then
  echo $"You are running an IceWM desktop"
    else 
   yad --title=$"Warning" --text=$"This script is meant to be run only in an IceWM desktop" --timeout=10 --no-buttons --center
 exit
fi

#Get system language (to allow localization):
lang=$(locale | grep LANG | cut -d= -f2 | cut -d. -f1) #To test localization to another language, like french, use: lang=fr
#hack to fix languages that are identified in .desktop files by only 2 characters, and not 4 (5 counting the _)
#comparing text that's before the "_" to the text that after that, converted to lower case, if it matches, use only the leters before the "_"
l1=$(echo $lang |cut -d_ -f1)
l2=$(echo $lang |cut -d_ -f2)
l2_converted=$(echo "${l2,,}")
if [ $l1 = $l2_converted ]; then lang=$l1; fi

help()
{
		###Function to display help
		yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --center --form --title=$"Toolbar Icon Manager" --field=$"Help::TXT" $"What is this?\nThis utility adds and removes application icons to IceWm's toolbar.\nThe toolbar application icons are created from an application's .desktop file.\nWhat are .desktop files?\nUsually a .desktop file is created during an application's installation process to allow the system easy access to relevant information, such as the app's full name, commands to be executed, icon to be used, where it should be placed in the OS menu, etc.\nA .desktop file name usually refers to the app's name, which makes it very easy to find the intended .desktop file (ex: Firefox ESR's .desktop file is 'firefox-esr.desktop').\nWhen adding a new icon to the toolbar, the user can click the field presented in the main window and a list of all the .desktop files of the installed applications will be shown.\nThat, in fact, is a list of (almost) all installed applications that can be added to the toolbar.\nNote: some of antiX's applications are found in the sub-folder 'antiX'.\n
TIM buttons:\n 'ADD ICON' - select, from the list, the .desktop file of the application you want to add to your toolbar and it instantly shows up on the toolbar.\nIf, for some reason, TIM fails to find the correct icon for your application, it will still create a toolbar icon using the default 'gears' image so that you can still click to access the application.\nYou can click the 'Advanced' button to manually edit the relevant entry and change the application's icon.\n'UNDO LAST STEP' - every time an icon is added or removed from the toolbar, TIM creates a backup file. If you click this button, the toolbar is instantly restored from that backup file, without any confirmation.\n'REMOVE ICON' - this shows a list of all applications that have icons on the toolbar. Double left click any application to remove its icon from the toolbar\n'MOVE ICON' - this shows a list of all applications that have icons on the toolbar. Double left click any application to select it and then move it to the left or to the right\n'ADVANCED' - allows for editing the text configuration file that has all of your desktop's toolbar icon's configurations. Manually editing this file allows the user to rearrange the order of the icons and delete or add any icon. A brief explanation about the inner workings of the text configuration file is displayed before the file is opened for editing.\n Warnings: only manually edit a configuration file if you are sure of what you are doing! Always make a back up copy before editing a configuration file!"  --center --width=600 --height=700 --button=gtk-quit:1
		###END of Function to display help
}

advanced()
{
		###Function to manually manage icons (ADVANCED management)
		cp ~/.icewm/toolbar ~/.icewm/toolbar.bak &&	
		yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --center --form --title=$"Toolbar Icon Manager" --field=$"Warning::TXT" $"If you click 'Yes', the toolbar configuration file will be opened for manual editing.\n
How-to:\nEach toolbar icon is identified by a line starting with 'prog' followed by the application name, icon and the application executable file.\n Move, edit or delete the entire line referring to each toolbar icon entry.\nNote: Lines starting with # are comments only and will be ignored.\nThere can be empty lines.\nSave any changes and then restart IceWM.\nYou can undo the last change from TIMs UNDO LAST STEP button." --width=400 --height=360 --button=gtk-quit:1 --button=gtk-yes:0 && leafpad ~/.icewm/toolbar && icewm --restart
		###END of Function to manually arrange icons
}		

delete_icon()
{
		###Function to delete  icon
		#create backup file before changes
		cp ~/.icewm/toolbar ~/.icewm/toolbar.bak

#Sanitize de toolbar file, keep only the lines that stars with "prog", no comments, no separator...
# and If there are spaces before "prog", remove!!
egrep -i '^[[:blank:]]*prog' ~/.icewm/toolbar | awk '{$1=$1};1' > /tmp/toolbar-icewm-tmp.txt

		### Select any application whose icon you want to remove from the toolbar:
#generate list of icons (and the respective app name) from available from the toolbar file:
cat /tmp/toolbar-icewm-tmp.txt | cut -d' ' -f2- | sed 's/\.png.*/.png/' | sed 's/^.\{1\}//' > /tmp/icons_in_toolbar.txt
#now make one field (separated by " on each line)
while IFS=\"  read name icon; do
    #If the searched icon is a path, replace it with the file name only, no extension, no path
    # this is because the icon files aren't scaled, the yad autor said:
    #  "yad forced to scale image only if icon specified by name. a full path to file means that image shows without changes"
    #https://github.com/v1cont/yad/issues/129#issuecomment-823784624
    if [[ $(echo $icon | grep '/') != "" ]]; then 
      icon=$(basename "$icon" | cut -d. -f1)
    fi
    echo $icon
    echo $name
done < /tmp/icons_in_toolbar.txt > "/tmp/parsed_icons_in_toolbar.txt"
# remove empty lines:
sed -i '/^[[:space:]]*$/d' /tmp/parsed_icons_in_toolbar.txt
# Use a Yad window to select file to be added to the menu
selection=$(yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --center --height=600 --width=450 --title=$"Toolbar Icon Manager" --list --column=:IMG --column=$"Double click any Application to remove its icon:" --button=$"Remove":4 --button=gtk-quit < /tmp/parsed_icons_in_toolbar.txt)		
#get line number(s) where the choosen application is
selection_parsed=$(echo $selection |cut -d\| -f2)
		x=$(echo $selection_parsed)
		 Line=$(sed -n "/$x/=" ~/.icewm/toolbar)
		 ## NOTE: to be on the safe side, in order to use $Line to delete the line(s) that match the selection, first extract it's first number, to avoid errors in case more than one line matchs the selection (there's more that one icon for the same app on the toolbar), TIM should only delete the first occorrence!!! Also: changed the sed command so it directly deletes line number $Line (solves the bug of not deleting paterns with spaces)...
		 firstx=$(echo $Line | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')
		# remove the first line that matchs the user selection and save that into a temporary file
		sed ${firstx}d ~/.icewm/toolbar > ~/.tempo
        # copy that temp file to antiX's icewm toolbar file, delete the temp file and restart to see changes BUT only if "toolbar" file is not rendered completly empty after changes (fail safe to avoid deleting the entire toolbar icon's content, in case a icon has a description with \|/*, etc.)
         if [[ -s ~/.tempo ]];
     then echo $"file has something";
     #file is not empty
					cp ~/.tempo ~/.icewm/toolbar ;
					rm ~/.tempo ;
					icewm --restart ;
					exit
      else echo $"file is empty";
      #file is empty
		yad --title=$"Warning" --text=$"No changes were made!\nTIP: you can always try the Advanced buttton." --timeout=3 --no-buttons --center
		 fi
        	exit
		###END of Function to delete last icon
}		

move_icon()
{

#Sanitize de toolbar file, keep only the lines that stars with "prog", no comments, no separator...
# and If there are spaces before "prog", remove!!
egrep -i '^[[:blank:]]*prog' ~/.icewm/toolbar | awk '{$1=$1};1' > /tmp/toolbar-icewm-tmp.txt

		#generate list of icons (and the respective app name) from available from the toolbar file:
cat /tmp/toolbar-icewm-tmp.txt | cut -d' ' -f2- | sed 's/\.png.*/.png/' | sed 's/^.\{1\}//' > /tmp/icons_in_toolbar.txt
#now make one field (separated by " on each line)
while IFS=\"  read name icon; do
    #If the searched icon is a path, replace it with the file name only, no extension, no path
    # this is because the icon files aren't scaled, the yad autor said:
    #  "yad forced to scale image only if icon specified by name. a full path to file means that image shows without changes"
    #https://github.com/v1cont/yad/issues/129#issuecomment-823784624
    if [[ $(echo $icon | grep '/') != "" ]]; then 
      icon=$(basename "$icon" | cut -d. -f1)
    fi
    echo $icon
    echo $name
done < /tmp/icons_in_toolbar.txt > "/tmp/parsed_icons_in_toolbar.txt"
# remove empty lines:
sed -i '/^[[:space:]]*$/d' /tmp/parsed_icons_in_toolbar.txt
# Use a Yad window to select file to be added to the menu
selection=$(yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --center --height=600 --width=450 --title=$"Toolbar Icon Manager" --list --column=:IMG --column=$"Double click any Application to move its icon:" --button=$"Move":4 --button=gtk-quit < /tmp/parsed_icons_in_toolbar.txt)	
#get line number(s) where the choosen application is
selection_parsed=$(echo $selection |cut -d\| -f2)
		x=$(echo $selection_parsed)
		 Line=$(sed -n "/$x/=" ~/.icewm/toolbar)
		 #get number of lines in file
		 number_of_lines=$(wc -l < $file)

#only do something if a icon was selected :
if test -z "$x" 
then
      echo $"nothing was selected"
else

file_name=~/.icewm/toolbar
a=$Line

#this performs an infinite loop, so the Move window is ALWAYS open unless the user clicks "Cancel"
	while :
	do
EXEC=$x #just to keep the localization on the next line working...
yad --center --undecorated --title=$"Toolbar Icon Manager" --text=$"Choose what do to with $EXEC icon" \
--button=gtk-quit:1 \
--button=$"Move left":2 \
--button=$"Move right":3 

foo=$?
Line_to_the_left=line_number=$((line_number-1))
line_number=$a

if [[ $foo -eq 1 ]]; then exit
fi

#move icon to the left:
if [[ $foo -eq 2 ]]; then
b=$(($a-1))
	if [ $b -gt 0 ]; then
sed -n "$b{h; :a; n; $a{p;x;bb}; H; ba}; :b; p" ${file_name} > test2.txt
#create backup file before changes
cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
 cp test2.txt  ~/.icewm/toolbar
 sleep .3
 rm -f test2.txt
icewm --restart
a=$(($a-1))   # update selected icon's position, just in case the user wants to move it again
	fi
fi

#move icon to the right
if [[ $foo -eq 3 ]]; then
a=$(($a+1))
number_of_lines=$(wc -l < ~/.icewm/toolbar)
b=$(($a-1))
    if [[ $line_number -ge  $number_of_lines ]]; then 
  exit 
  else
  sed -n "$b{h; :a; n; $a{p;x;bb}; H; ba}; :b; p" ${file_name} > test2.txt
#create backup file before changes 
cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
    cp test2.txt  ~/.icewm/toolbar
    sleep .3
    rm -f test2.txt
icewm --restart
# There's no need to update selected icon's position, just in case the user wants to move it again, because moving right just moves the icon to the right of the select icon to the left, so, it updates instantly the selected icon's position
  fi
fi

	done

fi ### ends if cicle that checks if user selected icon to move in the main Move icon window

	}	

restore_icon()
{
		###Function to restore last backup
cp ~/.icewm/toolbar.bak ~/.icewm/toolbar
icewm --restart
		###END Function to restore last backup
}

add_icon()
{

#This loop was at the script start, but slows down a lot its start in my computer
# and it is'nt always needed, so I move this code to here...

###Create list of availables apps, with localized names- this takes a few seconds on low powered devices:

#Loop through all .desktop files in the applications folders and extract name and save that to a .txt file 
cd /usr/share/applications/
find ~+ -type f -name "*.desktop" > ~/.apps-antix-0.txt
cd ~/.local/share/applications/
find ~+ -type f -name "*.desktop" > ~/.apps-antix-1.txt
###NOTE: repeat the last 2 lines, changing the first, the "cd" one, to change to the folder where your .desktop files are
cat ~/.apps-antix-0.txt ~/.apps-antix-1.txt > ~/.apps-antix.txt
cd ~

for file in $(cat ~/.apps-antix.txt)
do
 #Search for icons in the desktop file:
 icon=$(grep -o -m 1 '^Icon=.*' $file)
 icon=$(echo $icon | sed 's/.*\=//')
  #If the searched icon is a path, replace it with the file name only, no extension, no path
  # this is because the icon files aren't scaled, the yad autor said:
  #  "yad forced to scale image only if icon specified by name. a full path to file means that image shows without changes"
  #https://github.com/v1cont/yad/issues/129#issuecomment-823784624
  if [[ $(echo $icon | grep '/') != "" ]]; then 
    icon=$(basename "$icon" | cut -d. -f1)
  #If the searched thing is nothing, replace it with "-", only for no confuse the user and the program
  elif [[ "$icon" = "" ]]; then 
    icon="-"
  fi
  #Search for app name in the desktop file:
  name1=$(grep -o -m 1 '^Name=.*' $file)
  ### localized menu entries generator (slows the script down, but produces nearly perfectly localized menus):
    name2=$name1
	translated_name1=$(grep -o -m 1 "^Name\[$lang\]=.*" $file)
	[ -z "$translated_name1" ] && note=$"No localized name found, using the original one" || name2=$translated_name1
	#if the desktop file has the string "Desktop Action" simply use the original untranslated name, to avoid risking using a translation that's not the name of the app
	grep -q "Desktop Action" $file && name2=$name1
	name1=$name2
 ### end of localized menu entries generator	 
 name=$(echo $name1 | sed 's/.*\=//') 
  if [[ "$name" = "" ]]; then 
    name="-"
  fi
 #Search for the exec file in the desktop file
 exec0=$(grep -o -m 1 '^Exec=.*' $file)
 exec=$(echo $exec0 | cut -d= -f2)
  if [[ "$exec" = "" ]]; then 
    coment="-"
  fi
 #Search for the comment in the desktop file
 coment=$(grep -o -m 1 '^Comment=.*' $file)
 coment=$(echo $coment | sed 's/.*\=//')
  if [[ "$coment" = "" ]]; then 
    coment="-"
  fi
#No use @ for separator, there are apps with @ in the name, comment...
echo "$name" ß "$icon" ß "$coment" ß "$file" ß "$exec"
done > /tmp/list.txt
sort /tmp/list.txt > ~/.apps.txt
###
###devide one file per line, starting with icon, then name of app, then .desktop file:
###
while IFS=ß  read name icon coment desktop_file exec; do
    echo $icon
    echo $name
    echo $coment
    echo $desktop_file
    echo $exec
done < "$HOME/.apps.txt" > "$HOME/.icon_apps.txt"
###

####begin infinite loop (is most fast than others approach...)
for (( ; ; ))
do

###clear selection	
selection=""

# Use a Yad window to select file to be added to the menu
selection=$(yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --wrap-width=500 --wrap-cols=3 --title=$"Choose application to add to the Toolbar" --height=500 --width=1100 --center --button=$"Add selected app's icon":2 --button="gtk-quit":1 --list --column="Icon":IMG --column="Application":TEXT --column="Comment":TEXT --column="Desktop file":TEXT --column="Exec":HD < $HOME/.icon_apps.txt)

#only do something if a icon was selected :
if test -z "$selection"; then
      echo $"nothing was selected"
      exit
else
  #create backup file before changes
  cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
  
  #Yad's output is a "|" separated array, we take the 5º field, the app's exec
  # and if it have a "%U" "%F"... after it, we remove it
  selection2=$(echo "$selection" | cut -d '|' -f 5 | gawk -F' %' '{ print $1 }')
  
  #We search this in the icewm application menu, and get the line needed for the icewm's toolbar file
  egrep -i '^[[:blank:]]*prog' ~/.icewm/application > ~/.menu-icewm-tmp.txt
  METERMENU=$(grep "$selection2" ~/.menu-icewm-tmp.txt)

  #If grep finds 2 or more lines?... See below, we show it to user...
  if [[ $(echo -e "$METERMENU" | wc -l) -eq 1 ]]; then 
      #If the finded line has a "none" icon, change it with a standar icon
      # (xdgmenumaker put it as "_none_" in it's menu)
      if [[ $(echo "$METERMENU" | grep '_none_') != "" ]]; then 
         METERMENU=$(echo "$METERMENU" | gawk '{ gsub (/_none_/, "/usr/share/icons/Tango/24x24/mimetypes/exec.png"); print }')
      fi
    #If we find something, put this new line in the toolbar file
    if [[ "$METERMENU" != "" ]]; then
      echo "$METERMENU" >> ~/.icewm/toolbar
     #instantly restart IceWm so the new icon appears
     icewm --restart
    #If there is nothing to put in the toolbar file, try searching by app's name
    else
      echo $"nothing was selected"
      # Yad's output is a "|" separated array, now we take the 2º field, the app's name
      selection2=$(echo "$selection" | cut -d '|' -f 2)
      #We search this app in the icewm application menu. We get the line needed for the icewm's toolbar file
      export LANGUAGE=es_ES && xdgmenumaker --no-submenu -i -f icewm | egrep -i '^[[:blank:]]*prog' > ~/.menu-icewm-tmp2.txt
      METERMENU=$(grep -m 1 "$selection2" ~/.menu-icewm-tmp2.txt)
        #If the searched line has a "none" icon, (xdgmenumaker put it as "_none_" in it's menu)
        # change it with a standar icon
        if [[ $(echo "$METERMENU" | grep '_none_') != "" ]]; then 
           METERMENU=$(echo "$METERMENU" | gawk '{ gsub (/_none_/, "/usr/share/icons/Tango/24x24/mimetypes/exec.png"); print }')
        fi
      #If we find something, put this new line in the toolbar file
      if [[ "$METERMENU" != "" ]]; then
        echo "$METERMENU" >> ~/.icewm/toolbar
        #instantly restart IceWm so the new icon appears
        icewm --restart
      #If there is nothing to put in the toolbar file, abort
      else
        echo $"nothing was selected"
        yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --title=$"Warning" --text="An error occurred and this icon could not be put." --button="gtk-quit" --center --image=dialog-warning --image-on-top
      fi
    fi
  else
  #There was more than one file to put in toolbar, let the user to chose it
  METERMENU2=$(echo "$METERMENU" | yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --title=$"Choose application to add to the Toolbar" --height=200 --width=800 --center --button=$"Add selected app's icon":2 --button="gtk-quit":1 --list --column="There was more than one application, chose one!!":TEXT)
    #only do something if a icon was selected :
    if test -z "$METERMENU2"; then
      echo $"nothing was selected"
      exit
    else
    #put this new line in the toolbar file
    echo "$METERMENU2" >> ~/.icewm/toolbar
    #instantly restart IceWm so the new icon appears
    icewm --restart
    fi
  fi
fi

###close infite loop
done
###END of Function to add a new icon		
}

export -f help delete_icon advanced restore_icon add_icon move_icon
DADOS=$(yad --window-icon="/usr/share/icons/hicolor/32x32/apps/icewm.xpm" --length=200 --width=280 \
--center --title=$"Toolbar Icon Manager" --form  \
--button=gtk-quit:1 \
--field=$"HELP!help:FBTN" "bash -c help" \
--field=$"ADD ICON!add:FBTN" "bash -c add_icon" \
--field=$"REMOVE ICON!remove:FBTN" "bash -c delete_icon" \
--field=$"MOVE ICON!gtk-go-back-rtl:FBTN" "bash -c move_icon" \
--field=$"UNDO LAST STEP!undo:FBTN" "bash -c restore_icon" \
--field=$"ADVANCED!accessories-text-editor:FBTN" "bash -c advanced" \
--wrap --text=$"Please select any option from the buttons below to manage Toolbar icons")

### wait for a button to be pressed then perform the selected function
foo=$?
[[ $foo -eq 1 ]] && exit 0
