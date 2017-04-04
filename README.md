Linux backdoor script for CCDC. Tested on latest stock Debian, CentOS, and Fedora

you should run this as root

this script: 
* adds your key to to root's authorized_keys
  * adds an ADDITIONAL authorized_keys file somehwereon the filesystem, and sets sshd_config AuthorizedKeysFile to that location. 
* transfers an executable of your choice to to a location of your choice, and sets an hourly crontab to run the executable
  * executable also runs whenever a user logs in or when a new user is created
* adds PHP webshell to the given directory. Will find the webroot as long as apache's config is in /etc/apache2
 sets setuid bit on the following binaries for easy root
  * nano, vi, vim, emacs
  * more, less
  * mv, cp
  * cat, echo, awk, find
  * python, perl, ruby
* adds a new user and attempts to give it sudo access
* chmod 777 on /etc/shadow, /etc/passwd, /etc/group, /etc/sudoers, as well as the /root and /etc directories
* TODO: Add some methods of reinserting backdoors as they are discovered and removed by the blue team
* EVIL MODE: Corrupts some binaries, uninstalls some
  * Have a cool way of fucking with a Linux box? I'd love to hear it
  
additional features
* chattr +i all of the things!
* timestomps everything it touches
* attempts curl, wget (TODO: ftp/scp) to transfer files
