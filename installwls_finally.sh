#!/bin/bash
# shell script to install jdk (default version jdk-6u45-linux-x64.bin)
# example : ./installwls_finally.sh 
# Before using, please upload your jdk&wls media to /tmp directory. and upload the shell script to /root dir
# version 1.0
# version 2.0 ***--add install jdk for rpm installer--**
# version 3.0 ***--add install jdk for tar installer--**
# version 3.0 ***--add install weblogic 12c adn create domain --**
# version 3.0 ***--add install weblogic 11g and create domain --**
# created by zhoulei091@126.com 2016/01/7
set -x
##############################################################################
# 1.set Parameters
# Before use, set the parameters
# Parameter Meaning
##############################################################################
 #install username 
 username="weblogic"
 
 #user home directory
 #userhomedir="/home/$username"
 userhomedir="/home/weblogic"
 
 #user home directory pre
 prehomedir="/weblogic"
 
 #jdk install media name
 jdkfilename="jdk-6u45-linux-x64.bin"
 
 #jdk install path
 jdkinstallpath="/usr/java/"
 
 #jdk unpacked name
 jdkunpackedname="jdk1.6.0_45"
 
 # wls&jdk install media upload directory 
 mediadir="/tmp/wls_install/"
 
 #wls install media name 
 #wlsfilename="fmw_12.1.3.0.0_wls.jar"
 wlsfilename="wls1036_generic.jar"
 
 #wls will install path
 wlsinstallpath="$prehomedir/bea/"
 
 # if 64bit Linux ,please set bit value -d64.if not please set ""
 bit=""
 
 #set Adminserver information
 #wls domain name
 domainname="sipo_domain"
 
 #wls domain will install directory 
 domainpath="${prehomedir}/domains/$domainname"
 
 #AdminServer name
 servername="AdminServer"

 #wls administrator password
 password="pubmanager9"
 
 #listen address
 listenaddress="10.78.0.61"
 
 #listen port
 listenport="7001"

##############################################################################
# 2.check JDK media is Eixst? 
# if it is not eixst，the shell will exit. 
# if is eixst,the shell will create user and move jdk&wls media to install path,then install jdk and wls.
##############################################################################

 ls -l $mediadir |grep $jdkfilename
 r=$?
if [ $r == 1 ]; then
        echo "Can not found jdk install media......"
        exit 1
else
        echo "JDK installation file exist,Ready to start creating the user......"
        ##############################################################################
        # 3.create user for weblogic 
        # if user home dir have /home,use "useradd -g username username -m" command
        # else ,use "useradd -g gid -u uid -m username" command 
        ##############################################################################
        groupadd -g 1100 bea && echo "Create $username group success......"
        if echo $userhomedir | grep -qe '^\/home' ;
                 then 
                         useradd -g bea $username -m && echo "Create $username success......"
                 else 
                         #redhat centos not need mkdir
                         mkdir -p $prehomedir
                         useradd -g 1100 -u 1100 -d $userhomedir -m $username && echo "Create $username success......222"
        fi
        
        ##############################################################################
        # 4.move install media for right directory
        # move jdk to jdkinstall path , and move wls to weblogic user home dir
        ##############################################################################
        ls -l "$jdkinstallpath$jdkunpackedname"
        re=$?
        if [ $re > 0 ]; then
                echo "Can not find jdk install path $jdkinstallpath$jdkunpackedname......"
                mkdir $jdkinstallpath
        fi
        mv "$mediadir$jdkfilename" $jdkinstallpath && echo "$jdkfilename has been moved to the  $jdkinstallpath directory......"
        mv "$mediadir$wlsfilename" $userhomedir && echo "$wlsfilename has been moved to the $userhomedir directory......"
       
       ##############################################################################
       #5 delete default rpm jdk,if use rpm installer....
       ##############################################################################
       if  [[ $jdkfilename == *rpm* ]];
           then
           for i in $(rpm -qa | grep jdk | grep -v grep)
           do
           echo "Deleting rpm ...... "$i
           rpm -e --nodeps $i
           done
       fi
       
       ##############################################################################
       #6 if remove rpm jdk successfully,then install jdk
       ##############################################################################
       if [[ ! -z $(rpm -qa | grep jdk | grep -v grep) ]];
           then 
           echo " Failed to remove the defult Jdk."
       else
                 ##############################################################################
                 # 6.install JDK         
                 # determine the type of jdk media --rpm or -- tar.gz -- or bin
                 ##############################################################################
                 if  [[ $jdkfilename == *rpm* ]];
                    then
                      echo "rpm installer......."
                      cd "$jdkinstallpath" && rpm -ivh "$jdkfilename" && cd - && echo "JDK RPM installer  has been installed successfully......"
                 elif [[ $jdkfilename == *tar.gz* ]];
                     then
                      echo "tar.gz installer......."
                      cd "$jdkinstallpath" && tar -zxvf "$jdkfilename" && cd - && echo "JDK tar.gz installer  has been installed successfully......"
                 else
                      chmod u+x "$jdkinstallpath$jdkfilename"
                      sh "$jdkinstallpath$jdkfilename" && echo "JDK has been installed successfully......"
                      mv ./"$jdkunpackedname" "$jdkinstallpath"
                 fi
                 
                 ##############################################################################
                 # 7. Judging by the ls command is successfully installed jdk
                 ##############################################################################
                 if [[ -z $(ls "$jdkinstallpath$jdkunpackedname") ]];
                    then
                       echo " Failed to install JDK $jdkfilename"
                 else 
                       ##############################################################################
                       # 8.backup .profile and config user's .profile
                       # if suse Linux ,then config user home directory .profile
                       # if Redhat,CentOS,then config user home directory .bash_profile
                       ##############################################################################
                       if [ ! -z "$username" ] && [[ ! -z $(cat /etc/issue | grep SUSE | grep -v grep) ]];
                          then
                          echo " SUSE Linux : Config .profile JDK environment for $username......"
                          user_bash_file="$userhomedir/.profile"
                          ls -la $userhomedir && echo "**********************"
                          cp $userhomedir/.profile $userhomedir/.profile.beforeAddJDKenv.bak && echo "Backup .profile success......"
                          echo "export JAVA_HOME=$jdkinstallpath$jdkunpackedname" >> $user_bash_file
                          echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> $user_bash_file
                          echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> $user_bash_file
                       else
                          echo " Config .bash_profile for JDK environment from $username......"
                          user_bash_file="$userhomedir/.bash_profile"
                          ls -la $userhomedir && echo "**********************"
                          cp $userhomedir/.bash_profile $userhomedir/.bash_profile.beforeAddJDKenv.bak && echo "Backup bash_profile success......"
                          echo "export JAVA_HOME=$jdkinstallpath$jdkunpackedname" >> $user_bash_file
                          echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> $user_bash_file
                          echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> $user_bash_file
                       fi
                       
                       ##############################################################################
                       # 9. prepare for install weblogic *******************************************************
                       # if wls media name have 12,then install weblogic 12c
                       ##############################################################################
                       if  [[ $wlsfilename == *12* ]];
                          then
                          cd $userhomedir && mkdir tmp && cd tmp && mkdir .inventory
                          echo "inventory_loc=$userhomedir/tmp/.inventory" >> oralnst.loc
                          echo "inst_group=$username" >> oralnst.loc
                          
                          echo "[ENGINE]"  >> wls1213.install
                          echo "Response File Version=1.0.0.0.0"  >> wls1213.install
                          echo "[GENERIC]"  >> wls1213.install
                          echo "ORACLE_HOME=$wlsinstallpath"  >> wls1213.install
                          echo "INSTALL_TYPE=Complete with Examples"  >> wls1213.install
                          echo "MYORACLESUPPORT_USERNAME="  >> wls1213.install
                          echo "MYORACLESUPPORT_PASSWORD=<SECURE VALUE>"  >> wls1213.install
                          echo "DECLINE_SECURITY_UPDATES=true"  >> wls1213.install
                          echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false"  >> wls1213.install
                          echo "PROXY_HOST="  >> wls1213.install
                          echo "PROXY_PORT="  >> wls1213.install
                          echo "PROXY_USER="  >> wls1213.install
                          echo "PROXY_PWD=<SECURE VALUE>"  >> wls1213.install
                          echo "COLLECTOR_SUPPORTHUB_URL="  >> wls1213.install
                          
##############################################################################
# 10 su weblogic user,install welogic 12c
##############################################################################
chown -R $username:bea $userhomedir
chown -R $username:bea $prehomedir
su $username <<!
export LANG=zh_CN.gb18030
echo "Now !it is installing Weblogic 12c *******************************************************"
$jdkinstallpath$jdkunpackedname/bin/java $bit -jar $userhomedir/$wlsfilename -silent -responseFile $userhomedir/tmp/wls1213.install -invPtrLoc $userhomedir/tmp/oralnst.loc -Djava.security.egd=file:/dev/./urandom > $userhomedir/wls_install.log 
exit
!

filenames=`ls ${userhomedir} |grep wls_install.log`
echo "$filenames"
for filename in $filenames; do
     succeskey=`grep "100%" ${userhomedir}/wls_install.log`
     echo "$succeskey"
     if [ -n "$succeskey" ];then
          echo "Install weblogic successfull and will create wls domain ...... " 
          echo "readTemplate(\"${wlsinstallpath}wlserver/common/templates/wls/wls.jar\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "cd(\"Server/AdminServer\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "cmo.setName(\"$servername\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "set(\"ListenAddress\",\"$listenaddress\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "set(\"ListenPort\",$listenport)"  >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "cd(\"/Security/base_domain/User/weblogic\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "cmo.setPassword(\"$password\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "setOption(\"OverwriteDomain\",'true')" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "setOption('ServerStartMode','prod')" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "writeDomain(\"$domainpath\")" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "closeTemplate()" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          echo "exit()" >> ${wlsinstallpath}wlserver/common/bin/createdomain.py
          cat ${wlsinstallpath}wlserver/common/bin/createdomain.py
          
##############################################################################
# 11. create wls 12c domain
##############################################################################

chown -R $username:$username $userhomedir
if [[ ! -z $(ls "${wlsinstallpath}wlserver/common/bin/createdomain.py") ]]; then
su  $username <<!
export LANG=zh_CN.gb18030
echo "Now !it is create Weblogic 12c domains *******************************************************"
${wlsinstallpath}wlserver/common/bin/wlst.sh  ${wlsinstallpath}wlserver/common/bin/createdomain.py && echo "Created domain successfully!......."
exit
!
fi

      else
          echo "Install weblogic 12c failed **********"
      fi
done
 
                       ##############################################################################
                       # 12. install wls 11g  
                       ##############################################################################
                       else
                          echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> $userhomedir/silent.xml
                          echo "<bea-installer>" >> $userhomedir/silent.xml
                          echo "<input-fields>" >> $userhomedir/silent.xml 
                          echo "<data-value name=\"BEAHOME\" value=\"$wlsinstallpath\" />" >> $userhomedir/silent.xml
                          echo "</input-fields>" >> $userhomedir/silent.xml
                          echo "</bea-installer>" >> $userhomedir/silent.xml
                          cat $userhomedir/silent.xml 
                          
chown -R $username:bea $userhomedir
chown -R $username:bea $prehomedir
su $username <<!
export LANG=zh_CN.gb18030
echo "Now !it is installing Weblogic 11g *******************************************************"
$jdkinstallpath$jdkunpackedname/bin/java $bit -jar $userhomedir/$wlsfilename -mode=silent -silent_xml=$userhomedir/silent.xml -log=$userhomedir/wls_install.log -Djava.io.tmpdir=/tmp/
exit
!

filenames=`ls ${userhomedir} |grep wls_install.log`
echo "$filenames"
for filename in $filenames; do
        succeskey=`grep "successfull!" ${userhomedir}/wls_install.log`
        echo "$succeskey"
        if [ -n "$succeskey" ];then
          echo "Install weblogic successfull and will create wls domain ...... " 
          echo "readTemplate(\"${wlsinstallpath}wlserver_10.3/common/templates/domains/wls.jar\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "cd(\"Server/AdminServer\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "cmo.setName(\"$servername\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "set(\"ListenAddress\",\"$listenaddress\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "set(\"ListenPort\",$listenport)"  >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "cd(\"/Security/base_domain/User/weblogic\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "cmo.setPassword(\"$password\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "setOption(\"OverwriteDomain\",'true')" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "setOption('ServerStartMode','prod')" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "writeDomain(\"$domainpath\")" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "closeTemplate()" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          echo "exit()" >> ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py
          cat ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py

##############################################################################
# 13. create wls 11g domain 
##############################################################################
chown -R $username:bea $userhomedir
chown -R $username:bea $prehomedir
if [[ ! -z $(ls "${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py") ]]; then
su  $username <<!
export LANG=zh_CN.gb18030
echo "Now !it is create Weblogic 11g domains *******************************************************"
${wlsinstallpath}wlserver_10.3/common/bin/wlst.sh  ${wlsinstallpath}wlserver_10.3/common/bin/createdomain.py && echo "Created domain successfully!......."
exit
!
fi
      else
          echo "Install weblogic 11g failed **********"
      fi
done

                      #wls12c fi
                      fi
                #jdk fi
                fi
        #rpm fi
        fi
#no jdk media
fi
chown -R $username:bea $userhomedir
chown -R $username:bea $prehomedir





