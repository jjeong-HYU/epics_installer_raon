#! /bin/bash
set -e


function ini_func() { sleep 1; printf "\n>>>> You are entering in  : %s\n" "${1}"; }
function end_func() { sleep 1; printf "\n<<<< You are leaving from : %s\n" "${1}"; }

function prepare_install(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};
    echo "Update package list and upgrade packages"
    if [ "$CENT" == "centos" ]; then
    $SUDO_CMD yum -y update
    else
    $SUDO_CMD apt-get update
    $SUDO_CMD apt-get -y dist-upgrade
    fi
    end_func ${func_name};
}

function jdk17_setup(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

        case `uname -sm` in
        "Linux x86_64")
                if [ "$CENT" == "centos" ]; then
        $SUDO_CMD yum -y install java-17-openjdk-devel
                else
                $SUDO_CMD apt-get -y install openjdk-17-jdk
                fi
                ;;
        "Linux armv7l" | "Linux armv6l")
        $SUDO_CMD apt-get -y install openjdk-17-jdk
                ;;
        *)
                echo "*********************************************************"
                echo "Sorry, this scripts do not support your operation system."
                echo "*********************************************************"
                ;;
        esac
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))


    end_func ${func_name};
}

function tomcat_setup(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    cd ${DOWNLOAD_SITE}
    $SUDO_CMD apt-get install -y libcap-dev

    printf "Downloading the Tomcat9... \n"
    $WGET_CMD "dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    printf "Unzip the tomcat into ${EPICS_PATH}/archiver_applinace... \n"
    $TAR_CMD apache-tomcat-${TOMCAT_VERSION}.tar.gz -C ${EPICS_PATH}/archiver_appliance

    export TOMCAT_HOME=${EPICS_PATH}/archiver_appliance/apache-tomcat-${TOMCAT_VERSION}

cat > ${TOMCAT_HOME}/lib/log4j.properties <<EOF
# Set root logger level and its only appender to A1.
# DEBUG < INFO < WARN < ERROR < FATAL
# Set properties file
log4j.rootLogger=ERROR, A1
log4j.logger.config.org.epics.archiverappliance=INFO
log4j.logger.org.apache.http=ERROR
# A1 is set to be a DailyRollingFileAppender
# Use DailyRollingFileAppender to set write files by date specify class to use appender
log4j.appender.A1=org.apache.log4j.DailyRollingFileAppender
# Use File option to set file path and names
log4j.appender.A1.File=arch.log
# Use DatePattern option to set log file data
log4j.appender.A1.DatePattern='.'yyyy-MM-dd
# A1 uses PatternLayout.
# DateLayout, HTMLLayout, PatternLayout, SimpleLayout, XMLLayout
# In general, using PatternLayout is best for debugging
log4j.appender.A1.layout=org.apache.log4j.PatternLayout
# Define log pattern
log4j.appender.A1.layout.ConversionPattern=%-4r [%t] %-5p %c %x - %m%n
EOF

# Build the Apache Commons Daemon that ships with Tomcat
pushd ${TOMCAT_HOME}/bin
tar zxf commons-daemon-native.tar.gz
COMMONS_DAEMON_VERSION_FOLDER=`ls -d commons-daemon-*-native-src | head -1`
popd

pushd ${TOMCAT_HOME}/bin/commons-daemon-1.3.1-native-src/unix
./configure
make

    cp ${TOMCAT_HOME}/bin/commons-daemon-1.3.1-native-src/unix/jsvc ${TOMCAT_HOME}/bin


    end_func ${func_name};
}

function mysql_setup(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    cd ${DOWNLOAD_SITE}

    printf "Downloading mysql-connector... \n"
    $WGET_CMD "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${CONNECTOR_VERSION}.tar.gz"
    $TAR_CMD mysql-connector-java-${CONNECTOR_VERSION}.tar.gz

    cd ${DOWNLOAD_SITE}/mysql-connector-java-${CONNECTOR_VERSION}
    cp ${DOWNLOAD_SITE}/mysql-connector-java-${CONNECTOR_VERSION}/mysql-connector-java-${CONNECTOR_VERSION}-bin.jar ${TOMCAT_HOME}/lib

    case "$CENT" in
      centos)
            printf "Setup mariadb-server... \n"
        $SUDO_CMD yum -y install mariadb-server
        $SUDO_CMD systemctl enable mariadb.service
        $SUDO_CMD systemctl start mariadb.service
        echo ""
        echo "Enter the mariadb root password"
        echo "Is there mysql account already set? (1:yes / 0:no): "
        read mysqlaccount
if [ $mysqlaccount -eq 0 ]; then
        echo "create user ${MYSQL_USER}@localhost identified by '${MYSQL_USER_PW}';create database if not exists ${MYSQL_DB};grant all on ${MYSQL_DB}.* to ${MYSQL_USER}@localhost;" | mysql -u "root" -p"${MYSQL_ROOT_PW}"
        fi
	echo "use ${MYSQL_DB};" | mysql -u"${MYSQL_USER}" -p"${MYSQL_USER_PW}"
            ;;
      *)
            printf "Setup mysql-server... \n"
            $SUDO_CMD apt-get -y install mysql-server
        echo ""
        echo "Enter the mysql root password"
        echo "Is there mysql account already set? (1:yes / 0:no): "
        read mysqlaccount
if [ $mysqlaccount -eq 0 ]; then
	echo "create user ${MYSQL_USER}@localhost identified by '${MYSQL_USER_PW}';create database if not exists ${MYSQL_DB};grant all on ${MYSQL_DB}.* to ${MYSQL_USER}@localhost;" | mysql -u "root" -p"${MYSQL_ROOT_PW}"
fi
            echo "use ${MYSQL_DB};" | mysql -u"${MYSQL_USER}" -p"${MYSQL_USER_PW}"
            ;;
    esac
    end_func ${func_name};
}

function archappl_setup(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    cd ${DOWNLOAD_SITE}

    mkdir -p ${DOWNLOAD_SITE}/archappl

    printf "Downloading archiver appliance... \n"
    $WGET_CMD "https://github.com/slacmshankar/epicsarchiverap/releases/download/v0.0.1_SNAPSHOT_30-September-2021/${ARCHAPPL_filename}"
    printf "Unzip ${ARCHAPPL_filename} into ${DOWNLOAD_SITE}/archappl directory... \n"
    $TAR_CMD ${ARCHAPPL_filename} -C ${DOWNLOAD_SITE}/archappl

# Create an appliances.xml file and set up this appliance's identity.
cat > ${EPICS_PATH}/archiver_appliance/appliances.xml <<EOF
 <appliances>
   <appliance>
     <identity>appliance0</identity>
     <cluster_inetport>${AA_HOST_IP}:16670</cluster_inetport>
     <mgmt_url>http://${AA_HOST_IP}:17665/mgmt/bpl</mgmt_url>
     <engine_url>http://${AA_HOST_IP}:17666/engine/bpl</engine_url>
     <etl_url>http://${AA_HOST_IP}:17667/etl/bpl</etl_url>
     <retrieval_url>http://${AA_HOST_IP}:17668/retrieval/bpl</retrieval_url>
     <data_retrieval_url>http://${AA_HOST_IP}:17668/retrieval</data_retrieval_url>
   </appliance>
 </appliances>
EOF

export TOMCAT_HOME=${EPICS_PATH}/archiver_appliance/apache-tomcat-${TOMCAT_VERSION}
export ARCHAPPL_APPLIANCES=${EPICS_PATH}/archiver_appliance/appliances.xml
export ARCHAPPL_MYIDENTITY=appliance0

# Deploy multiple tomcats
python ${DOWNLOAD_SITE}/archappl/install_scripts/deployMultipleTomcats.py ${EPICS_PATH}/archiver_appliance

# Set the DB table into mysql DB
        echo "Is there mysql table already set? (1:yes / 0:no): "
        read mysqltable
if [ $mysqltable -eq 0 ]; then
mysql --user=${MYSQL_USER} --password=${MYSQL_USER_PW} --database=${MYSQL_DB} < ${DOWNLOAD_SITE}/archappl/install_scripts/archappl_mysql.sql
fi

# Put context.xml
cat > ${EPICS_PATH}/archiver_appliance/mgmt/conf/context.xml <<EOF
<?xml version='1.0' encoding='utf-8'?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!-- The contents of this file will be loaded for each web application -->
<Context>
    <!-- Default set of monitored resources -->
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <!-- Uncomment this to disable session persistence across Tomcat restarts -->
    <!--
    <Manager pathname="" />
    -->
    <!-- Uncomment this to enable Comet connection tacking (provides events
         on session expiration as well as webapp lifecycle) -->
    <!--
    <Valve className="org.apache.catalina.valves.CometConnectionManagerValve" />
    -->
    <Resource name="jdbc/archappl"
         auth="Container"
         type="javax.sql.DataSource"
         factory="org.apache.tomcat.jdbc.pool.DataSourceFactory"
         testWhileIdle="true"
         testOnBorrow="true"
         testOnReturn="false"
         validationQuery="SELECT 1"
         validationInterval="30000"
         timeBetweenEvictionRunsMillis="30000"
         maxActive="10"
         minIdle="2"
         maxWait="10000"
         initialSize="2"
         removeAbandonedTimeout="60"
         removeAbandoned="true"
         logAbandoned="true"
         minEvictableIdleTimeMillis="30000"
         jmxEnabled="true"
         driverClassName="com.mysql.jdbc.Driver"
         url="jdbc:mysql://localhost:3306/${MYSQL_DB}"
         username="${MYSQL_USER}"
         password="${MYSQL_USER_PW}"
     />
</Context>
EOF
export TOMCAT_HOME=${EPICS_PATH}/archiver_appliance/apache-tomcat-${TOMCAT_VERSION}

cd ${EPICS_PATH}/archiver_appliance/mgmt/conf
cp context.xml ${TOMCAT_HOME}/conf
    end_func ${func_name};
}
# Deploys a new build onto the EPICS archiver appliance installation
function deploy(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    printf "Deploy war release...\n"
    pushd ${EPICS_PATH}/archiver_appliance/mgmt/webapps && rm -rf mgmt*; cp ${WARSRC_DIR}/mgmt.war .; mkdir mgmt; cd mgmt; jar xf ../mgmt.war; popd;
    pushd ${EPICS_PATH}/archiver_appliance/engine/webapps && rm -rf engine*; cp ${WARSRC_DIR}/engine.war .; mkdir engine; cd engine; jar xf ../engine.war; popd;
    pushd ${EPICS_PATH}/archiver_appliance/etl/webapps && rm -rf etl*; cp ${WARSRC_DIR}/etl.war .; mkdir etl; cd etl; jar xf ../etl.war; popd;
    pushd ${EPICS_PATH}/archiver_appliance/retrieval/webapps && rm -rf retrieval*; cp ${WARSRC_DIR}/retrieval.war .; mkdir retrieval; cd retrieval; jar xf ../retrieval.war; popd

    end_func ${func_name};
}

# Change template for specific site
function change_template(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};
    printf "Change template for the site...\n"
    java -cp ${EPICS_PATH}/archiver_appliance/mgmt/webapps/mgmt/WEB-INF/classes org.epics.archiverappliance.mgmt.bpl.SyncStaticContentHeadersFooters ${SITE_SPECIFIC}/template_changes.html ${EPICS_PATH}/archiver_appliance/mgmt/webapps/mgmt/ui
    printf "Change img for the site... \n"
    cp -R ${SITE_SPECIFIC}/img/* ${EPICS_PATH}/archiver_appliance/mgmt/webapps/mgmt/ui/comm/img/

    end_func ${func_name};
}


# Prepare archiver appliance storage directory
function prepare_storage(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    printf "Make STS/MTS/LTS directory...\n"
    mkdir -p ${EPICS_PATH}/archiver_appliance/storage
    mkdir -p ${EPICS_PATH}/archiver_appliance/storage/{STS,MTS,LTS}

    end_func ${func_name};
}


# Create archiver appliance start script
function start_script(){

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};

    echo "Create Archiver Appliance start script..."

cat > ${EPICS_PATH}/archiver_appliance/single_node_archappl.sh <<EOF
#!/bin/bash
# startup script for the RAON archiver appliance
source ${EPICS_BASE}/setEpicsEnv.sh
#export EPICS_CA_MAX_ARRAY_BYTES=1000000000
#export EPICS_CA_ADDR_LIST=""
export JAVA_HOME=${JAVA_HOME}
export PATH=${JAVA_HOME}/bin:${PATH}
# We use a lot of memory; so be generous with the heap.
export JAVA_OPTS="-XX:+UseG1GC -Xmx4G -Xms4G -ea"
# Set up Tomcat home
export TOMCAT_HOME=${EPICS_PATH}/archiver_appliance/apache-tomcat-${TOMCAT_VERSION}
# Set up the root folder of the individual Tomcat instances.
export ARCHAPPL_DEPLOY_DIR=${EPICS_PATH}/archiver_appliance
# Set appliance.xml and the identity of this appliance
export ARCHAPPL_APPLIANCES=${EPICS_PATH}/archiver_appliance/appliances.xml
export ARCHAPPL_MYIDENTITY="appliance0"
# If you have your own policies file, please change this line.
# export ARCHAPPL_POLICIES=/nfs/epics/archiver/production_policies.py
# Set the location of short term and long term stores; this is necessary only if your policy demands it
export ARCHAPPL_SHORT_TERM_FOLDER=${EPICS_PATH}/archiver_appliance/storage/STS
export ARCHAPPL_MEDIUM_TERM_FOLDER=${EPICS_PATH}/archiver_appliance/storage/MTS
export ARCHAPPL_LONG_TERM_FOLDER=${EPICS_PATH}/archiver_appliance/storage/LTS
# Enable core dumps in case the JVM fails
ulimit -c unlimited
function startTomcatAtLocation() {
    export CATALINA_HOME=\$TOMCAT_HOME
    export CATALINA_BASE=\$1
    echo "Starting tomcat at location \${CATALINA_BASE}"
    export LD_LIBRARY_PATH=\${CATALINA_BASE}/webapps/engine/WEB-INF/lib/native/linux-x86_64:\${LD_LIBRARY_PATH}
    pushd \${CATALINA_BASE}/logs
    \${CATALINA_HOME}/bin/jsvc \\
        -server \\
        -cp \${CATALINA_HOME}/bin/bootstrap.jar:\${CATALINA_HOME}/bin/tomcat-juli.jar \\
        \${JAVA_OPTS} \\
        -Dcatalina.base=\${CATALINA_BASE} \\
        -Dcatalina.home=\${CATALINA_HOME} \\
        -cwd \${CATALINA_BASE}/logs \\
        -outfile \${CATALINA_BASE}/logs/catalina.out \\
        -errfile \${CATALINA_BASE}/logs/catalina.err \\
        -pidfile \${CATALINA_BASE}/pid \\
        org.apache.catalina.startup.Bootstrap start
     popd
}
function stopTomcatAtLocation() {
    export CATALINA_HOME=\$TOMCAT_HOME
    export CATALINA_BASE=\$1
    echo "Stopping tomcat at location \${CATALINA_BASE}"
    pushd \${CATALINA_BASE}/logs
    \${CATALINA_HOME}/bin/jsvc \\
        -server \\
        -cp \${CATALINA_HOME}/bin/bootstrap.jar:\${CATALINA_HOME}/bin/tomcat-juli.jar \\
        \${JAVA_OPTS} \\
        -Dcatalina.base=\${CATALINA_BASE} \\
        -Dcatalina.home=\${CATALINA_HOME} \\
        -cwd \${CATALINA_BASE}/logs \\
        -outfile \${CATALINA_BASE}/logs/catalina.out \\
        -errfile \${CATALINA_BASE}/logs/catalina.err \\
        -pidfile \${CATALINA_BASE}/pid \\
        -stop \\
        org.apache.catalina.startup.Bootstrap
     popd
}
function stop() {
        stopTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/engine
        stopTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/retrieval
        stopTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/etl
        stopTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/mgmt
}
function start() {
        startTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/mgmt
        startTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/engine
        startTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/etl
        startTomcatAtLocation \${ARCHAPPL_DEPLOY_DIR}/retrieval
}
# See how we were called.
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 2
esac
EOF

cd ${EPICS_PATH}/archiver_appliance
chmod +x single_node_archappl.sh

    end_func ${func_name};
}

Install_pre(){

apt -y update
apt -y upgrade

apt -y install make
apt -y install git gcc g++ build-essential cmake bison
apt -y install libcap-dev python2.7
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
}

create_env(){
echo "Create setEpicsEnv.sh file? (1:yes / 2:no): "
read option_env
if [ $option_env -eq 1 ]; then
    touch ${EPICS_PATH_TOP}/EPICS_DIR/base-7.0.6.1/setEpicsEnv.sh
    cat /dev/null > ${EPICS_PATH_TOP}/EPICS_DIR/base-7.0.6.1/setEpicsEnv.sh
    echo 'export EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> ${EPICS_PATH_TOP}/EPICS_DIR/base-7.0.6.1/setEpicsEnv.sh
    echo 'export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)' >> ${EPICS_PATH_TOP}/EPICS_DIR/base-7.0.6.1/setEpicsEnv.sh
    echo 'export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}' >> ${EPICS_PATH_TOP}/EPICS_DIR/base-7.0.6.1/setEpicsEnv.sh
    echo "Adding setEpicsEnv.sh to ./bashrc? (1:yes / 2:no): "
    read option_bashrc
    if [ $option_bashrc -eq 1 ]; then
        export 
        echo 'source '${EPICS_PATH}'/base-7.0.6.1/setEpicsEnv.sh' >> ~/.bashrc
        source ~/.bashrc
    fi
fi
}

Install_base(){

basecheck="${EPICS_PATH_TOP}/EPICS_DIR"
if [ -e $basecheck ];then
    rm -rf ${EPICS_PATH_TOP}/EPICS_DIR
    mkdir ${EPICS_PATH_TOP}/EPICS_DIR
else
    mkdir ${EPICS_PATH_TOP}/EPICS_DIR
fi

# ..epics install..



export EPICS_PATH=${EPICS_PATH_TOP}/EPICS_DIR



cd ${EPICS_PATH}

wget https://epics.anl.gov/download/base/base-7.0.6.1.tar.gz

tar zxvf base-7.0.6.1.tar.gz

cd base-7.0.6.1

make

create_env

# .. support ..

mkdir ${EPICS_PATH}/support
}



Install_calc(){

calccheck="${EPICS_PATH}/support/calc"
if [ -e $calccheck ];then
    rm -rf ${EPICS_PATH}/support/calc
    cd ${EPICS_PATH}/support
else
    cd ${EPICS_PATH}/support
fi

# .. calc install ..

git clone https://github.com/epics-modules/calc

cd calc

rm configure/RELEASE
touch configure/RELEASE
echo 'TEMPLATE_TOP=$(EPICS_BASE)/templates/makeBaseApp/top' >> configure/RELEASE
echo 'SUPPORT='${EPICS_PATH}'/support' >> configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.local' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local' >> configure/RELEASE
echo '-include $(TOP)/configure/RELEASE.local' >> configure/RELEASE

make

}

Install_asyn(){
# .. asyn install ..

asyncheck="${EPICS_PATH}/support/asyn"
if [ -e $asyncheck ];then
    rm -rf ${EPICS_PATH}/support/asyn
    cd ${EPICS_PATH}/support
else
    cd ${EPICS_PATH}/support
fi

git clone https://github.com/epics-modules/asyn

cd asyn
rm configure/RELEASE
touch configure/RELEASE
echo 'SUPPORT='${EPICS_PATH}'/support' >> configure/RELEASE
echo 'CALC=$(SUPPORT)/calc' >> configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.local' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local' >> configure/RELEASE
echo '-include $(TOP)/configure/RELEASE.local' >> configure/RELEASE

filecheck="/usr/include/rpc/rpc.h"
if [ -e $filecheck ];then
    make
else
    sudo apt -y install libntirpc-dev
    sed -i 's/# TIRPC=YES/TIRPC=YES/g' ${EPICS_PATH}/support/asyn/configure/CONFIG_SITE
    make
fi
}

Install_stream(){
# .. streamdevice install ..
streamcheck="${EPICS_PATH}/support/StreamDevice"
if [ -e $streamcheck ];then
    rm -rf ${EPICS_PATH}/support/StreamDevice
    cd ${EPICS_PATH}/support
else
    cd ${EPICS_PATH}/support
fi

git clone https://github.com/paulscherrerinstitute/StreamDevice.git

cd StreamDevice/

rm GNUmakefile

rm configure/RELEASE
touch configure/RELEASE
echo 'TEMPLATE_TOP=$(EPICS_BASE)/templates/makeBaseApp/top' >> configure/RELEASE
echo 'SUPPORT=$(TOP)/..' >> configure/RELEASE
echo '-include $(TOP)/../configure/SUPPORT.$(EPICS_HOST_ARCH)' >> configure/RELEASE
echo 'ASYN=$(SUPPORT)/asyn' >> configure/RELEASE
echo 'CALC=$(SUPPORT)/calc' >> configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.local' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local' >> configure/RELEASE
echo '-include $(TOP)/configure/RELEASE.local' >> configure/RELEASE

make
}

Install_seq()
{
apt-get install re2c

# .. sequencer install ..
seqcheck="${EPICS_PATH}/support/seq-${SEQUENCER_VERSION}"
if [ -e $seqcheck ];then
    rm -rf ${EPICS_PATH}/support/seq-${SEQUENCER_VERSION}
    cd ${EPICS_PATH}/support
else
    cd ${EPICS_PATH}/support
fi

wget https://www-csr.bessy.de/control/SoftDist/sequencer/releases/seq-${SEQUENCER_VERSION}.tar.gz

tar zxf seq-${SEQUENCER_VERSION}.tar.gz

cd ${EPICS_PATH}/support/seq-${SEQUENCER_VERSION}

rm configure/RELEASE
touch configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo '-include $(TOP)/../configure/EPICS_BASE.$(EPICS_HOST_ARCH)' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.local' >> configure/RELEASE
echo '-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local' >> configure/RELEASE
echo '-include $(TOP)/configure/RELEASE.local' >> configure/RELEASE

make
}

Install_IOC(){

# .. IOC install ..

cd ${EPICS_PATH}

cp ${INSTALLER_PATH}/option/serialTest_RAON_20220420 . -r

cd serialTest_RAON_20220420

rm configure/RELEASE
touch configure/RELEASE
echo 'TEMPLATE_TOP=$(EPICS_BASE)/templates/makeBaseApp/top' >> configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo 'SUPPORT=$(EPICS_BASE)/../support' >> configure/RELEASE
echo 'ASYN=$(SUPPORT)/asyn' >> configure/RELEASE
echo 'STREAM=$(SUPPORT)/StreamDevice' >> configure/RELEASE
echo 'CALC=$(SUPPORT)/calc' >> configure/RELEASE

make clean

make

cd ${EPICS_PATH}

cp ${INSTALLER_PATH}/option/testIOC . -r

cd testIOC

rm configure/RELEASE
touch configure/RELEASE
# echo 'TEMPLATE_TOP=$(EPICS_BASE)/templates/makeBaseApp/top' >> configure/RELEASE
echo 'EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> configure/RELEASE
echo 'SUPPORT=$(EPICS_BASE)/../support' >> configure/RELEASE
echo 'ASYN=$(SUPPORT)/asyn' >> configure/RELEASE
echo 'STREAM=$(SUPPORT)/StreamDevice' >> configure/RELEASE
echo 'CALC=$(SUPPORT)/calc' >> configure/RELEASE
echo 'SNCSEQ=$(SUPPORT)/seq-$(SEQUENCER_VERSION}' >> configure/RELEASE

make clean

make

}

Install_whole_exceptArchappl(){
Install_pre
Install_base
Install_calc
Install_asyn
Install_stream
Install_seq
Install_IOC 
}

Install_whole(){
Install_pre
Install_base
Install_calc
Install_asyn
Install_stream
Install_seq
mkdir -p ${HOME}/epics/{downloads,R${EPICS_VERSION}}
mkdir -p ${EPICS_PATH}/archiver_appliance
prepare_install
jdk17_setup
tomcat_setup
mysql_setup
archappl_setup
deploy
change_template
prepare_storage
start_script
Install_IOC 
}

# .. env variable setting ..

INSTALLER_PATH=${PWD}

echo "Type the path where the system is installed"
read -p "Path: " EPICS_PATH_TOP
export EPICS_PATH=${EPICS_PATH_TOP}/EPICS_DIR

export LOG_DATE=$(date +"%Y.%m.%d.%H:%M")
export SUDO_CMD="sudo"
export TAR_CMD="tar xzf"
export WGET_CMD="wget -c"
export DOWNLOAD_SITE=${EPICS_PATH}
export JDK_install_site=/opt
export TOMCAT_VERSION="9.0.64"
export SEQUENCER_VERSION="2.2.9"
export MYSQL_USER="archappl"
export MYSQL_USER_PW="archappl"
export MYSQL_DB="archappl"
export MYSQL_ROOT_PW=""
export ARCHAPPL_filename="archappl_v0.0.1_SNAPSHOT_30-September-2021T08-25-29.tar.gz"
export AA_HOST_IP=$(hostname -I | awk '{print $1}')
export WARSRC_DIR=${DOWNLOAD_SITE}/archappl
export SITE_SPECIFIC=$(pwd)/site_specific_content
export EPICS_VERSION="7.0.6.1"
export EPICS_PATH=${EPICS_PATH}
export EPICS_BASE=${EPICS_PATH}/base-7.0.6.1
export java_home==$(dirname $(dirname $(readlink -f $(which java))))
export CONNECTOR_VERSION="5.1.49"
export STRIPTOOL_VERSION="2_5_16_0"
export VDCT_VERSION="2.7.0"

while :
do
    echo "Install option:"
    echo "A . Whole system(EPICS_BASE, Asyn, Calc, StreamDevice, Sequencer)"
    echo "Ac. Whole system(EPICS_BASE, Asyn, Calc, StreamDevice, Sequencer, Archappl)"
    echo "1 . Prerequisition"
    echo "2 . EPICS_BASE_7.0.6.1"
    echo "3 . Modules (Asyn, Calc, StreamDevice, Sequencer)"
    echo "4 . Archiver appliance"
    echo "5 . RAON_Serial_IOC, testIOC(for sequencer test)"
    echo "6 . Create setEpicsEnv.sh in base folder(Should be executed after base was installed)"
    echo "9 . exit"
    read -p "Type your option: " option_install
    case ${option_install} in
        A) Install_whole_exceptArchappl ;;
        Ac) Install_whole ;;
        1) Install_pre ;;
        2) Install_base ;;
        3) Install_calc
           Install_asyn
           Install_stream
	   Install_seq ;;
        4)  echo "Install the Archiver Appliance... "
            mkdir -p ${HOME}/epics/{downloads,R${EPICS_VERSION}}
            mkdir -p ${EPICS_PATH}/archiver_appliance
            prepare_install
            jdk17_setup
            tomcat_setup
            mysql_setup
            archappl_setup
            deploy
            #change_template
            prepare_storage
            start_script
            echo "Archiver Appliance installed at ${EPICS_PATH}/archiver_appliance"
        ;;
        5) Install_IOC ;;
        6) create_env ;;
        9) exit 0 ;;
	tst) Install_seq ;;
    esac
done

exit 0
