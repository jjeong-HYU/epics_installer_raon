#! /bin/bash
set -e

Install_pre(){

apt -y update
apt -y upgrade

apt -y install make
apt -y install git gcc g++ build-essential

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
}

Install_whole(){
Install_pre
Install_base
Install_calc
Install_asyn
Install_stream
Install_IOC 
}


# .. env variable setting ..

INSTALLER_PATH=${PWD}

echo "Type the path where the system is installed"
read -p "Path: " EPICS_PATH_TOP
export EPICS_PATH=${EPICS_PATH_TOP}/EPICS_DIR

while :
do
    echo "Install option:"
    echo "0. Prerequisition"
    echo "1. Whole system(EPICS_BASE, Asyn, Calc, StreamDevice"
    echo "2. EPICS_BASE_7.0.6.1"
    echo "3. Calc"
    echo "4. Asyn(Should be installed after calc was installed)"
    echo "5. StreamDevice(Should be installed after calc,asyn was installed)"
    echo "6. RAON_Serial_IOC(Should be installed after whole system was installed)"
    echo "7. Create setEpicsEnv.sh in base folder(Should be executed after base was installed)"
    echo "9. exit"
    read -p "Type your option: " option_install
    case ${option_install} in
        0) Install_pre ;;
        1) Install_whole ;;
        2) Install_base ;;
        3) Install_calc ;;
        4) Install_asyn ;;
        5) Install_stream ;;
        6) Install_IOC ;;
        7) create_env ;;
        9) exit 0 ;;
    esac
done

exit 0
