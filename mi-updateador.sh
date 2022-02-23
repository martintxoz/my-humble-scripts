#!/bin/bash

#Script to update a system with APT. 
#Ideas from Sparky Aptus Update and MXLinux Apt-Notifier.
#GPL-v3 license.

#Needs the following apps (and package name if needed) installed (as well as the standard ones in a Debian SO): 
# xdotool, wmctrl, pkexec (policykit-1), yad, pkill (procps), notify-send (libnotify-bin)

#For this script to work the "apt update" action must be configured 
# for example in /etc/apt/apt.conf.d/02periodic file. 
#See: https://wiki.debian.org/UnattendedUpgrades#Automatic_call_via_.2Fetc.2Fapt.2Fapt.conf.d.2F02periodic
#The only 2 settings needed are:
#APT::Periodic::Enable "1";
#APT::Periodic::Update-Package-Lists "1";

#Later, you have to run this script at the start of your Desktop Environment (Gnome, KDE, Xfce...),
# or through cron, for example in the /etc/cron.daily folder, or in another cron setting.

#Turn on script debugging:
#set -x

### CONFIGURATION:
### Start of user configurations
#Configuration: application for the PC logout or reboot:
export reboot_app="/usr/local/bin/obshutdown"
#Configuration: seconds to wait for the desktop to full start. For no wait put 0:
export wait="10s"
#Configuration: if desktop notification app is "Dunst", there are problems if the icon file is not fully specified 
# in other cases you can surely put here "system-software-update" for the icon
export notification_icon="/usr/share/icons/Tango/scalable/apps/system-software-update.svg"

### Config of APT comands for package instalation:
#1. To do or not the "apt update" prior to installation, for look at new packages.
# Choices: "yes" or "no" (without quotes). Yes if usefull in case of a rare use of the machine, 
#  where there is a long time from the last apt update to the package installation
export apt_update=no
#2. To do an "apt upgrade" or an "apt full-upgrade" for the new packages installation:
# "apt upgrade": only install a package if no other installed package need to be removed, is safer
# "apt full-upgrade": performs too installed packages removes, so the installation is complete
# Choices: "apt-upgrade" or "apt-full-upgrade" (how is written but without the quotes).
export apt_installation=apt-full-upgrade
#3. To do or not the "apt autoremove" after the installation, for remove automatically 
# installed packages only for satisfy dependencies, and are now no longer needed.
# Choices: "yes" or "no" (without quotes). No is safer...
export apt_autoremove=yes
### End of configurations

#See if there are updates of pending packages and create a list of updatable packages, if any:
LC_ALL=C apt-get -o Debug::NoLocking=true --trivial-only -V dist-upgrade 2>/dev/null > /tmp/mi-updateador
#Count how many packages updatable are. Save the number in variable:
export NUPGRADEABLE=$(cat /tmp/mi-updateador | sed -n '/will be upgraded:/,$p' | grep ^'  ' | awk '{ print $1 }' | wc -l)
#If $NUPGRADEABLE not 0, see if there are packages to be installed that have processes running...
# only find some, those whose package name = process name
if [ "$NUPGRADEABLE" -gt "0" ]; then
  export PAKETESCORRIENDO=$(for i in `cat /tmp/mi-updateador | sed -n '/will be upgraded:/,$p' | grep ^'  ' | awk '{ print $1 }'`; do pgrep -i -l "$i" | awk '{ print $2 }'; done | sort -u | tr '\n' ' ')
fi

### Localization start:
		# Default: english
		export software_update="Software_update"
		export no_updates="No software updates available"
		export yes_updates1="There are "$NUPGRADEABLE" software update(s) available."
		export yes_updates2="View icon in taskbar..."
		export yes_updates3="There are "$NUPGRADEABLE" updates (left click on icon to view updates, right click for options)"
		export yad_update_title1="Update "$NUPGRADEABLE" package(s)?"
		export yad_update_text1="\nDo you want to update <b>"$NUPGRADEABLE" software package(s)</b>?\nThey are the following:"
		export yad_update_title2="Update "$NUPGRADEABLE" package(s)? Some are IN USE!!"
		export yad_update_text2="\nDo you want to update <b>"$NUPGRADEABLE" software package(s)</b>?\n \nThe following applications seems to be <b>currently RUNNING</b>: "$PAKETESCORRIENDO".\n \nI think it is important that <b>AFTER THE UPDATE</b>:\n - You turn off and run these applications again, if you know what they are.\n - If you do not know them, exit from the session or reboot the PC.\nIf you update, I will leave an icon for you to remember, if you click on it, you can turn off...\n \nThe "$NUPGRADEABLE" package(s) that are going to be updated are the following:"
		export reboot_text="AT THE END OF THE UPDATE, remember to turn off applications started:"$PAKETESCORRIENDO", or logout or reboot computer (left click on icon to logout/reboot, right click for kill icon)"
		export upgrade_completed="Full upgrade complete (or was canceled)."
		export terminal_close="This terminal window can now be closed."
		export key_close="Press any key to close window"
#Other languages:		
case $LANG in
    #Spanish
	es* )
		export software_update="Actualizar_software"
		export no_updates="NO hay actualizaciones de software disponibles"
		export yes_updates1="Hay "$NUPGRADEABLE" actualizacion(es) de software disponible(s)."
		export yes_updates2="Ver icono en barra de tareas..."
		export yes_updates3="Hay "$NUPGRADEABLE" actualizaciones (click izquierdo en icono para ver actualizaciones, click derecho para opciones)"
		export yad_update_title1="¿Actualizar "$NUPGRADEABLE" paquete(s)?"
		export yad_update_text1="\n¿Quieres actualizar <b>"$NUPGRADEABLE" paquete(s)</b> de software?\nSon los siguientes:"
		export yad_update_title2="¿Actualizar "$NUPGRADEABLE" paquete(s)? Algunos EN USO!!"
		export yad_update_text2="\n¿Quieres actualizar <b>"$NUPGRADEABLE" paquete(s)</b> de software?\n \nDe esos programas los siguientes parece que <b>estan ARRANCADOS</b> actualmente:\n"$PAKETESCORRIENDO"\n \nCreo que es importante que <b>DESPUES DE la actualización</b>:\n - Apagues y vuelvas a arrancar esos programas, si sabes cuales son.\n - Si no los conoces, sal de la sesion o reinicia el ordendador.\nSi actualizas, dejare un icono para que te acuerdes, si lo pinchas puedes apagar...\n \nLos "$NUPGRADEABLE" paquete(s) que se van a actualizar son los siguientes:"
		export reboot_text="AL ACABAR LA ACTUALIZACION, acuerdate de apagar programas arrancados: "$PAKETESCORRIENDO", o de salir o reiniciar ordenador (click izquierdo en icono para salir/reiniciar, click derecho para quitar icono)"
		export upgrade_completed="Se realizó la actualización completa (o fue cancelada)."
		export terminal_close="Esta ventana de terminal ya puede cerrarse."
		export key_close="Oprima cualquier tecla para cerrar esta ventana"
		#;;
esac
### Localization end

#Function showing the window that reports the packages that can be upgraded. 
# This function is called by icon in the taskbar, at script last lines: yadicono ... 
segundo-paso-ventana-y-upgrade()
{

#Another function for no to repeat this code in two places. Run "apt upgrade" in terminal.
crear-inline-script-y-ejecutar ()
{
#The following lines, until the last EOF, is the code for the update script in /tmp 
cat > /tmp/mi-updateador.sh << "EOF"
#!/bin/bash

#Turn on script debugging:
#set -x

#Without this, the commands to change window size do not work, or affect others, not this terminal...
sleep 0.25s

#To center the terminal window on the screen:
#Decrease the size of the window titled $software_update at 67% of the screen in the two dimensions 
xdotool windowsize $(xdotool search --onlyvisible --name "$software_update") 67% 67%

#This centers the window titled $software_update in the center of the screen
IFS='x' read sw sh < <(xdpyinfo | grep dimensions | grep -o '[0-9x]*' | head -n1)
read wx wy ww wh < <(wmctrl -lG | grep "$software_update" | sed 's/^[^ ]* *[^ ]* //;s/[^0-9 ].*//;')
wmctrl -r "$software_update" -e 0,$(($sw/2-$ww/2)),$(($sh/2-$wh/2)),$ww,$wh

#Compose the APT command line from the settings up in the original script
if [ "$apt_update" = "yes" ]; then
  export apt_update="echo ' ';echo 'Look for new packages/Buscamos nuevos paquetes:';echo '==============================================';echo ' ';apt update;"
else
  export apt_update="echo ' ';echo 'Dont look for new packages/No buscamos nuevos paquetes.';echo '==============================================';echo ' ';"
fi
if [ "$apt_installation" = "apt-full-upgrade" ]; then
  export apt_installation="echo ' ';echo 'Do complete installation/Hacemos instalacion completa:';echo '==============================================';echo ' ';apt -V full-upgrade;"
else
  export apt_installation="echo ' ';echo 'Dont do complete installation/No hacemos instalacion completa:';echo '==============================================';echo ' ';apt -V upgrade;"
fi
if [ "$apt_autoremove" = "yes" ]; then
  export apt_autoremove="echo ' ';echo 'Uninstall unneeded packages/Desinstalamos paquetes no necesarios:';echo '==============================================';echo ' ';apt -V autoremove --purge;"
else
  export apt_autoremove="echo ' ';echo 'Dont uninstall unneeded packages/No desinstalamos paquetes no necesarios.';echo '==============================================';echo ' ';"
fi

#The commands that really make the update (variables determined up) and:
# - pkexec (from polkit) for gain root
# - DISPLAY XAUTHORITY for apt-listchanges to come out in a separate window
# - bash -c "command_1;command_2" for not put the password 2 times
pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c "$apt_update$apt_installation$apt_autoremove"

#Terminal window remains open until any key is pressed and closes it 
echo
echo "$upgrade_completed"
echo
echo "$terminal_close"' '
#read -sn 1 -p '("$key_close")' -t 999999999
read -sn 1 -p '(Any key closes / Cualquier tecla cierra)' -t 999999999

#Turn off script debugging:
#set +x

EOF
chmod 755 /tmp/mi-updateador.sh
#Wait to write the script on disk and execute it in a terminal
sleep 0.1s
x-terminal-emulator -T $software_update -e /tmp/mi-updateador.sh

rm /tmp/mi-updateador*
}
#"Apt upgrade script" function end

#Turn on script debugging:
#set -x

#If there are no "packages to update and running", shows a window with only the packages list: 
if [ "$PAKETESCORRIENDO" = "" ]; then

#Window with the list of packages to update:
yad --window-icon=system-software-update \
        --width=700 --height=600 --center --fontname="Arial 12" \
        --image=system-software-update \
        --title "$yad_update_title1" \
        --text="$yad_update_text1" \
        --form --field :TXT "$(apt-get -o Debug::NoLocking=true --trivial-only -V dist-upgrade 2>/dev/null | tail -n +5)" \
        --button gtk-ok:0 --button gtk-cancel:1 >& /dev/null

  #If click in OK run the updater (function: crear-inline-script-y-ejecutar, above),
  # otherwise close the window and wait (icon in taskbar)
  #  (If something is modified here, it will also be modified below after "else")
  if [ "$?" = "0" ]; then

    #Remove the icon on the system tray (taskbar) 
    # The code here has to be the same as down, in $yadicono...
    pkill --full 'yad --notification --image=system-software-update --text=$yes_updates2 --command=bash -c segundo-paso-ventana-y-upgrade --menu=Update/Actualiza!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Quit/Salir!quit!back'

    #Execute the update function
    crear-inline-script-y-ejecutar
    exit 0
    
  fi

#If there are "packages to update and running", shows a window explaining the problem and with the packages list:
else

#Window with the list of packages to update and the notice of potential problems :
yad --window-icon=system-software-update \
        --width=700 --height=600 --center --fontname="Arial 12" \
        --image=software-update-urgent \
        --title "$yad_update_title2" \
        --text="$yad_update_text2" \
        --form --field :TXT "$(apt-get -o Debug::NoLocking=true --trivial-only -V dist-upgrade 2>/dev/null | tail -n +5)" \
        --button gtk-ok:0 --button gtk-cancel:1 >& /dev/null

  #If click in OK run the updater (function: crear-inline-script-y-ejecutar, above),
  # otherwise close the window and wait (icon in taskbar)
  #  (If something is modified here, it will also be modified above before "else")
  if [ "$?" = "0" ]; then

    #Remove the icon on the system tray (taskbar) 
    # The code here has to be the same as down, in $yadicono...
    pkill --full 'yad --notification --image=system-software-update --text=$yes_updates2 --command=bash -c segundo-paso-ventana-y-upgrade --menu=Update/Actualiza!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Quit/Salir!quit!back'

    #This puts an icon in system tray to remember reboot... if click on it starts the logout app (configured above)
    yad --notification --image=software-update-urgent --text="$reboot_text" --command="$reboot_app" --menu='Quit/Salir!quit!back' &
    
    #Execute the update function
    crear-inline-script-y-ejecutar
    exit 0
  fi

fi
rm /tmp/mi-updateador*
#Turn off script debugging:
#set +x
}
#"Packages to update list Window" function end

#Export the "Packages to update list Window" function so that the Yad icon can execute it 
export -f segundo-paso-ventana-y-upgrade

### HERE BEGINS THE RUN OF THE SCRIPT...

#Wait for the desktop to full start (configured above).
sleep "$wait"

# If there are 0 upgrades only show a notification and exit, if there are more, show icon in taskbar:
if [ "$NUPGRADEABLE" = "" ] || [ "$NUPGRADEABLE" = "0" ]; then

    notify-send --app-name="$software_update" --icon="$notification_icon" --urgency=low "$no_updates"
    rm /tmp/mi-updateador*
    exit 0

else

   notify-send --app-name="$software_update" --icon="$notification_icon" --urgency=low "$yes_updates1" "$yes_updates2"

   #Show icon on systemtray with Yad, if click run function: segundo-paso-ventana-y-upgrade
   # https://sourceforge.net/p/yad-dialog/wiki/NotificationIcon/ 
   yadicono=$(yad --notification --image=system-software-update --text="$yes_updates3" --command='bash -c segundo-paso-ventana-y-upgrade' --menu='Update/Actualiza!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Quit/Salir!quit!back')
   #If click in "Quit icon" of the icon contextual menu, exit script:
   if test -z "$yadicono"; then
      rm /tmp/mi-updateador*
      exit
   fi
fi

#Turn off script debugging:
#set +x

exit 0
