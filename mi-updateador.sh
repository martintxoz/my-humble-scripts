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
#Configuration: seconds to wait for the desktop to full start. For no wait put 0.
# Not used if user start de app himself, as 'mi-updateador.sh user'
export wait="10s"
#Configuration: if desktop notification app is "Dunst", there are problems if the icon file is not fully specified 
# in other cases you can surely put here "system-software-update" for the icon
export notification_icon="/usr/share/icons/Tango/scalable/apps/system-software-update.svg"

### Config of APT comands for package instalation:
#1. To do or not the "apt update" prior to installation, for look at new packages.
# Choices: "yes" or "no" (without quotes). Yes if usefull in case of a rare use of the machine, 
#  where there is a long time from the last apt update to the package installation
#  But see the "Buscar actualizaciones" icon menu option... You can start it yourself!!
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

#Si el script lo arranca el usuario desde menu de su escritorio, es que quiere ver icono en barra tareas
# con esta variable sabemos si ha sido arrancado exprofeso por user o arrancado automatico
#Pongo archivo desktop que se arranca como 'mi-updeteador.sh user'
USER="$1"

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
		export apt_update_text_yes="Look for new packages:"
		export apt_update_text_no="Don't look for new packages."
		export apt_installation_full_text="Do complete installation:"
		export apt_installation_text="Don't do complete installation:"
		export apt_autoremove_yes_text="Uninstall unneeded packages:"
		export apt_autoremove_no_text="Don't uninstall unneeded packages."
		export upgrade_completed="Full upgrade complete (or was canceled)."
		export terminal_close="This terminal window can now be closed."
		export key_close="Press any key to close window"
		export apt_history_window="This is the content of the /var/log/apt/history.log file.\nThe history of the last updates of Apt."
		export apt_history_title="Apt update history"
		export dpkg_history_window="This is part of the content of the /var/log/dpkg.log file.\nThe history of the last updates with Dpkg."
		export dpkg_history_title="Update history with Dpkg"
#Other languages:		
case $LANG in
    #Spanish
	eu* )
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
		export apt_update_text_yes="Buscamos nuevos paquetes:"
		export apt_update_text_no="No buscamos nuevos paquetes."
		export apt_installation_full_text="Hacemos instalacion completa:"
		export apt_installation_text="No hacemos instalacion completa:"
		export apt_autoremove_yes_text="Desinstalamos paquetes no necesarios:"
		export apt_autoremove_no_text="No desinstalamos paquetes no necesarios."
		export upgrade_completed="Se realizó la actualización completa (o fue cancelada)."
		export terminal_close="Esta ventana de terminal ya puede cerrarse."
		export key_close="Oprima cualquier tecla para cerrar esta ventana"
		export apt_history_window="Este es el contenido del archivo /var/log/apt/history.log.\nLa historia de las ultimas actualizaciones de Apt."
		export apt_history_title="Historia de actualizaciones de Apt"
		export dpkg_history_window="Este es parte del contenido del archivo /var/log/dpkg.log.\nLa historia de las ultimas actualizaciones con Dpkg."
		export dpkg_history_title="Historia de actualizaciones con Dpkg"
		#;;
esac
### Localization end

#Function showing the window that reports the packages that can be upgraded. 
# This function is called by icon in the taskbar, at script last lines: yadicono ... 
segundo-paso-ventana-y-upgrade ()
{

#Another function for no to repeat this code in two places. Run "apt upgrade" in terminal.
crear-inline-script-y-ejecutar ()
{
#The following lines, until the last EOF, is the code for the update script in /tmp 
# Primera parte del upgrade script...
cat > /tmp/mi-updateador.sh << "EOF"
#!/bin/bash

#Pequeño script temporal en /tmp/mi-updateador.sh para upgradear el sistema.
# Cuando todo el asunto termina se supone que este script se borra...
# Si no ha sido asi, algo ha ido mal...

#Turn on script debugging:
#set -x

#Variables establecidas en el script principal /usr/local/bin/mi-updateador.sh
EOF

#Enviar variables al inline script empezado a hacer en /tmp/mi-updateador.sh
echo "apt_update=\"$apt_update\"" >> /tmp/mi-updateador.sh
echo "apt_installation=\"$apt_installation\"" >> /tmp/mi-updateador.sh
echo "apt_autoremove=\"$apt_autoremove\"" >> /tmp/mi-updateador.sh
echo "software_update=\"$software_update\"" >> /tmp/mi-updateador.sh
echo "upgrade_completed=\"$upgrade_completed\"" >> /tmp/mi-updateador.sh
echo "terminal_close=\"$terminal_close\"" >> /tmp/mi-updateador.sh
echo "apt_update_text_yes=\"$apt_update_text_yes\"" >> /tmp/mi-updateador.sh
echo "apt_update_text_no=\"$apt_update_text_no\"" >> /tmp/mi-updateador.sh
echo "apt_installation_full_text=\"$apt_installation_full_text\"" >> /tmp/mi-updateador.sh
echo "apt_installation_text=\"$apt_installation_text\"" >> /tmp/mi-updateador.sh
echo "apt_autoremove_yes_text=\"$apt_autoremove_yes_text\"" >> /tmp/mi-updateador.sh
echo "apt_autoremove_no_text=\"$apt_autoremove_no_text\"" >> /tmp/mi-updateador.sh
echo "key_close=\"$key_close\"" >> /tmp/mi-updateador.sh

#2º parte del inline script, continuar con el inline script...
cat >> /tmp/mi-updateador.sh << "EOF"

#Without this, the commands to change window size do not work, or affect others, not this terminal...
sleep 0.25s

#To center the terminal window on the screen:
#Decrease the size of the window titled $software_update at 67% of the screen wide 
xdotool windowsize $(xdotool search --onlyvisible --name "$software_update") 67% 90%

#This centers the window titled $software_update in the center of the screen
IFS='x' read sw sh < <(xdpyinfo | grep dimensions | grep -o '[0-9x]*' | head -n1)
read wx wy ww wh < <(wmctrl -lG | grep "$software_update" | sed 's/^[^ ]* *[^ ]* //;s/[^0-9 ].*//;')
wmctrl -r "$software_update" -e 0,$(($sw/2-$ww/2)),$(($sh/2-$wh/2)),$ww,$wh

#Compose the APT command line from the settings up in the original script
if [ "$apt_update" = "yes" ]; then
  apt_update="echo ' ';echo '$apt_update_text_yes';echo '============================';echo ' ';apt update;"
else
  apt_update="echo ' ';echo '$apt_update_text_no';echo '============================';echo ' ';"
fi
if [ "$apt_installation" = "apt-full-upgrade" ]; then
  apt_installation="echo ' ';echo '$apt_installation_full_text';echo '=============================';echo ' ';apt -V full-upgrade;"
else
  apt_installation="echo ' ';echo '$apt_installation_text';echo '=============================';echo ' ';apt -V upgrade;"
fi
if [ "$apt_autoremove" = "yes" ]; then
  apt_autoremove="echo ' ';echo '$apt_autoremove_yes_text';echo '===================================';echo ' ';apt -V autoremove --purge;"
else
  apt_autoremove="echo ' ';echo '$apt_autoremove_no_text';echo '===================================';echo ' ';"
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
#read -sn 1 -p '($key_close)' -t 999999999
read -sn 1 -p '(Any key closes / Cualquier tecla cierra)' -t 999999999

#Turn off script debugging:
#set +x

EOF

chmod 755 /tmp/mi-updateador.sh
#Wait to write the script on disk and execute it in a terminal
sleep 0.5s
#x-terminal-emulator -T $software_update -e /tmp/mi-updateador.sh && wait $!
#Con mi roxterm no consigo que se espere a completar, con xterm si...
#xterm -fg white -fa 'Monospace' -fs 11 -T $software_update -e /tmp/mi-updateador.sh
termit --init /home/martintxo/.config/termit/rc.lua-NORMAL --title $software_update --name Informaciones -e /tmp/mi-updateador.sh

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
        --form --field :TXT "$(cat /tmp/mi-updateador | tail -n +5)" \
        --button=gtk-ok:0 --button=gtk-cancel:1 >& /dev/null

  #If click in OK run the updater (function: crear-inline-script-y-ejecutar, above),
  # otherwise close the window and wait (icon in taskbar)
  #  (If something is modified here, it will also be modified below after "else")
  if [ "$?" = "0" ]; then
    
    #Execute the update function, above
    crear-inline-script-y-ejecutar
    
    #Remove the icon on the system tray (taskbar) 
    # The code here has to be the same as down, in $yadicono...
    pkill --full 'yad --notification --image=system-software-update --text=$yes_updates3 --command=bash -c segundo-paso-ventana-y-upgrade --menu=Actualizar!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Buscar actualizaciones!bash -c user-apt-update!reload|Historia Dpkg!bash -c dpkg-history-window!emblem-debian|Historia Apt!bash -c apt-history-window!emblem-debian-symbolic|Salir!quit!back'

    rm /tmp/mi-updateador*
    exit

  fi

#If there are "packages to update and running", shows a window explaining the problem and with the packages list:
else

#Window with the list of packages to update and the notice of potential problems :
yad --window-icon=system-software-update \
        --width=700 --height=600 --center --fontname="Arial 12" \
        --image=software-update-urgent \
        --title "$yad_update_title2" \
        --text="$yad_update_text2" \
        --form --field :TXT "$(cat /tmp/mi-updateador | tail -n +5)" \
        --button=gtk-ok:0 --button=gtk-cancel:1 >& /dev/null

  #If click in OK run the updater (function: crear-inline-script-y-ejecutar, above),
  # otherwise close the window and wait (icon in taskbar)
  #  (If something is modified here, it will also be modified above before "else")
  if [ "$?" = "0" ]; then

    #Remove the icon on the system tray (taskbar) 
    # The code here has to be the same as down, in $yadicono...
    pkill --full 'yad --notification --image=system-software-update --text=$yes_updates3 --command=bash -c segundo-paso-ventana-y-upgrade --menu=Actualizar!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Buscar actualizaciones!bash -c user-apt-update!reload|Historia Dpkg!bash -c dpkg-history-window!emblem-debian|Historia Apt!bash -c apt-history-window!emblem-debian-symbolic|Salir!quit!back'

    #This puts an icon in system tray to remember reboot... if click on it starts the logout app (configured above)
    yad --notification --image=software-update-urgent --text="$reboot_text" --command="$reboot_app" --menu='Salir-Reiniciar!/usr/local/bin/obshutdown!software-update-urgent|Quitar-icono!quit!back' &
    
    #Execute the update function
    crear-inline-script-y-ejecutar

    rm /tmp/mi-updateador*
    exit

  fi

fi

#Turn off script debugging:
#set +x
}
#"Packages to update list Window" function end

#Export the "Packages to update list Window" function so that the Yad icon can execute it 
export -f segundo-paso-ventana-y-upgrade


#Function showing a window with de apt history, from the /var/log/apt/history.log file
# This function is called by icon in the taskbar, at script last lines: yadicono ... 
apt-history-window()
{
#Window with history:
if [ -s /var/log/apt/history.log ]; then
  cat /var/log/apt/history.log | yad --window-icon=system-software-update \
         --text-info --width=1000 --height=500 --center \
	     --button=gtk-cancel:1 \
         --image=system-software-update \
         --title "$apt_history_title" \
         --text="$apt_history_window" \
         --fontname="mono regular 11" --margins=5 --borders=1 >& /dev/null
else
  echo "El archivo de log está vacio / Log file is empty." | yad --window-icon=system-software-update \
         --text-info --width=1000 --height=500 --center \
	     --button=gtk-cancel:1 \
         --image=system-software-update \
         --title "$apt_history_title" \
         --text="$apt_history_window" \
         --fontname="mono regular 11" --margins=5 --borders=1 >& /dev/null
fi
}
#Export the "Apt history window" function so that the Yad icon can execute it 
export -f apt-history-window


#Function showing a window with de dpkg history, from the /var/log/dpkg.log file
# This function is called by icon in the taskbar, at script last lines: yadicono ... 
dpkg-history-window()
{
#Window with history:
if [ -s /var/log/dpkg.log ]; then
zgrep -EH ' install | upgrade | purge | remove ' /var/log/dpkg.log | cut -f2- -d: | sort -r | sed 's/ remove / remove  /;s/ purge / purge   /' | grep "^" | yad --window-icon=system-software-update \
         --text-info --width=1000 --height=500 --center \
	     --button=gtk-cancel:1 \
         --image=system-software-update \
         --title "$dpkg_history_title" \
         --text="$dpkg_history_window" \
         --fontname="mono regular 11" --margins=5 --borders=1 >& /dev/null
else
  echo "El archivo de log está vacio / Log file is empty." | yad --window-icon=system-software-update \
         --text-info --width=1000 --height=500 --center \
	     --button=gtk-cancel:1 \
         --image=system-software-update \
         --title "$dpkg_history_title" \
         --text="$dpkg_history_window" \
         --fontname="mono regular 11" --margins=5 --borders=1 >& /dev/null
fi
}
#Export the "Dpkg history window" function so that the Yad icon can execute it 
export -f dpkg-history-window


#Function for the user to make and "apt update"
# This function is called by icon in the taskbar, at script last lines: yadicono ... 
user-apt-update()
{
#The following lines, until the last EOF, is the code for the update script in /tmp 
# primera parte del update script...
cat > /tmp/user-apt-update.sh << "EOF"
#!/bin/bash

#Pequeño script temporal en /tmp para updatear la lista de paquetes del sistema.
# Cuando todo el asunto termina se supone que este script se borra...
# Si no ha sido asi, algo ha ido mal...

#Turn on script debugging:
#set -x

#Variables establecidas en el script principal /usr/local/bin/mi-updateador.sh
EOF

#Enviar variables al inline script empezado a hacer en /tmp/mi-updateador.sh
echo "software_update=\"$software_update\"" >> /tmp/user-apt-update.sh
echo "apt_update_text_yes=\"$apt_update_text_yes\"" >> /tmp/user-apt-update.sh
echo "terminal_close=\"$terminal_close\"" >> /tmp/user-apt-update.sh
echo "key_close=\"$key_close\"" >> /tmp/user-apt-update.sh

#2º parte del inline script, continuar con el inline script...
cat >> /tmp/user-apt-update.sh << "EOF"

#Without this, the commands to change window size do not work, or affect others, not this terminal...
sleep 0.25s

#To center the terminal window on the screen:
#Decrease the size of the window titled $software_update at 67% of the screen wide 
xdotool windowsize $(xdotool search --onlyvisible --name "$software_update") 67% 70%

#This centers the window titled $software_update in the center of the screen
IFS='x' read sw sh < <(xdpyinfo | grep dimensions | grep -o '[0-9x]*' | head -n1)
read wx wy ww wh < <(wmctrl -lG | grep "$software_update" | sed 's/^[^ ]* *[^ ]* //;s/[^0-9 ].*//;')
wmctrl -r "$software_update" -e 0,$(($sw/2-$ww/2)),$(($sh/2-$wh/2)),$ww,$wh

#Compose the APT command line for apt update
export apt_update_user="echo ' ';echo '$apt_update_text_yes';echo '=========================';echo ' ';apt update;"

#The commands that really make the update (variables determined up) and:
# - pkexec (from polkit) for gain root
# - DISPLAY XAUTHORITY for apt-listchanges to come out in a separate window
# - bash -c "command_1;command_2" for not put the password 2 times
pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c "$apt_update_user"

#Terminal window remains open until any key is pressed and closes it 
echo
echo "$terminal_close"' '
#read -sn 1 -p '($key_close)' -t 999999999
read -sn 1 -p '(Any key closes / Cualquier tecla cierra)' -t 999999999

#Turn off script debugging:
#set +x

exit

EOF
chmod 755 /tmp/user-apt-update.sh
#Wait to write the script on disk and execute it in a terminal
sleep 0.5s
#x-terminal-emulator -T $software_update -e /tmp/user-apt-update.sh
#xterm -fg white -fa 'Monospace' -fs 11 -T $software_update -e /tmp/user-apt-update.sh
termit --title $software_update --name Informaciones -e /tmp/user-apt-update.sh

rm /tmp/user-apt-update.sh
}
#Export the "User apt update" function so that the Yad icon can execute it 
export -f user-apt-update


### HERE BEGINS THE RUN OF THE SCRIPT...

#Wait for the desktop to full start (configured above), but only if script is not started by user.
if [ "$USER" = "" ]; then
  sleep "$wait"
fi

#If there are 0 upgrades AND script is NOT started by user, only show a notification and exit.
# If there are more upgrades OR user starts de script, show icon in taskbar:
if [ "$NUPGRADEABLE" = "" ] || [ "$NUPGRADEABLE" = "0" ] && [ "$USER" = "" ]; then

    notify-send --app-name="$software_update" --icon="$notification_icon" --urgency=low "$no_updates"
    rm /tmp/mi-updateador*

else

   notify-send --app-name="$software_update" --icon="$notification_icon" --urgency=low "$yes_updates1" "$yes_updates2"

   #Show icon on systemtray with Yad, if click run function: segundo-paso-ventana-y-upgrade
   # https://sourceforge.net/p/yad-dialog/wiki/NotificationIcon/ 
   yadicono=$(yad --notification --image=system-software-update --text="$yes_updates3" --command='bash -c segundo-paso-ventana-y-upgrade' --menu='Actualizar!bash -c segundo-paso-ventana-y-upgrade!system-software-update|Buscar actualizaciones!bash -c user-apt-update!reload|Historia Dpkg!bash -c dpkg-history-window!emblem-debian|Historia Apt!bash -c apt-history-window!emblem-debian-symbolic|Salir!quit!back')
   #If click in "Quit icon" of the icon contextual menu, exit script:
   if test -z "$yadicono"; then
      rm /tmp/mi-updateador*
      exit
   fi
fi

#Turn off script debugging:
#set +x
