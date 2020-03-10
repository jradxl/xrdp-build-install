# xrdp Build and Install
Xrdp source code build and install
<br>
<br>
xrdp installed by a package manager always seems out of date.
So here is a build and install script....
I noticed that Ubuntu/Debian install as an xrdp user, which seems more secure to me. I used the deb sources to get some ideas on how, and then worked out how it could be done.
<br>
<br>
**as-xrdp**  
Runs "xrdp" as the user xrdp, and xrdp-sesman as root.  
Based on work done in Debian package, with libtool change shown in AUR.
<br>
<br>
/var/run or /run?  
Since I've see error messages from systemd when using /var/run, i use /run
<br>
<br>
Home directory for user xrdp?  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;I use same as Debian as /run/xrdp,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Should it be /var/lib/xrdp or /home/xrdp?
<br>
<br>
Details about my install script:-  
&nbsp;&nbsp;&nbsp;/etc/default/xrdp -- not supported   
&nbsp;&nbsp;&nbsp;/etc/init.d/xrdp -- not supported  
&nbsp;&nbsp;&nbsp;/etc/pam.d/xrdp-sesman -- from Debian  
&nbsp;&nbsp;&nbsp;xorg.conf -- appears to be automatically generated and put in  /etc/X11/xrdp/xorg.conf  
&nbsp;&nbsp;&nbsp;startwm.sh -- simple one from Debian  
&nbsp;&nbsp;&nbsp;sesman.ini -- specifies following...  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LogFile=/var/log/xrdp/xrdp-sesman.log  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;param=/usr/lib/xorg/Xorg  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;PULSE_SCRIPT=/usr/local/etc/xrdp/pulse/default.pa  

&nbsp;&nbsp;&nbsp;xrdp.ini -- specifies following:-  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LogFile=/var/log/xrdp/xrdp.log

&nbsp;&nbsp;&nbsp;fix_perms.patch  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;changes socket permissions in os_call.c.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Taken from Debian. I apply it, but not tested what happens without

&nbsp;&nbsp;&nbsp;libtool.patch   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Taken from AUR versions. 

&nbsp;&nbsp;&nbsp;envvars  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;script to hold environment variables.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;There doesn't appear to any point in supporting passing environment variables to systemd service files.

&nbsp;&nbsp;&nbsp;prepare-environment  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;based on script from Debian.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Systemd service files run this to prepare socket, home and log directories.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Note that when xrdp terminates it removes /run/xrdp.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Sets correct permissions on the rsakey and certificate files

&nbsp;&nbsp;&nbsp;Systemd Service Files  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;both non-forking and forking are provided.   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Fedora uses --nodaemon, thus avoiding the PID issues.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;I don't use PIDFile= as it does not seem to be necessary and produces an error message.
<br>
<br>
Command-Line use  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if running "sudo - xrpd xrdp --nodaemon" on the command line, then prepare-environment must be run beforehand
<br>
<br>
**as-root**  
Very simple build and install from the github sources
<br>
<br>
**References**  
https://salsa.debian.org/debian-remote-team/xrdp.git  
https://aur.archlinux.org/packages/xrdp-devel-git/ (three versions)  
https://src.fedoraproject.org/rpms/xrdp  
<br>
<br>
March 2020
