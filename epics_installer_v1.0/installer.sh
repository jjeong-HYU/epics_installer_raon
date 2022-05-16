#! /bin/bash
set -e

Install_pre(){

apt -y update
apt -y upgrade

apt -y install make
apt -y install git gcc g++ build-essential

}

Install_base(){

# ..epics install..

mkdir ${EPICS_PATH_TOP}/EPICS_DIR
export EPICS_PATH=${EPICS_PATH_TOP}/EPICS_DIR



cd ${EPICS_PATH}

wget https://epics.anl.gov/download/base/base-7.0.6.1.tar.gz

tar zxvf base-7.0.6.1.tar.gz

cd base-7.0.6.1

make

echo "Create setEpicsEnv.sh file? (1:yes / 2:no): "
read option_env
if [ $option_env -eq 1 ]; then
    touch setEpicsEnv.sh
    cat /dev/null > setEpicsEnv.sh
    echo 'export EPICS_BASE='${EPICS_PATH}'/base-7.0.6.1' >> setEpicsEnv.sh
    echo 'export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)' >> setEpicsEnv.sh
    echo 'export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}' >> setEpicsEnv.sh
    echo "Adding setEpicsEnv.sh to ./bashrc? (1:yes / 2:no): "
    read option_bashrc
    if [ $option_bashrc -eq 1 ]; then
        echo 'source ${EPICS_BASE}/setEpicsEnv.sh' >> ~/.bashrc
    fi
fi

# .. support ..

mkdir ${EPICS_PATH}/support
}

Install_calc(){
# .. calc install ..

cd ${EPICS_PATH}/support

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

cd ${EPICS_PATH}/support

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

make
if [ $? -eq 0 ];then
    echo 'asyn compile done!'
else
    sed -i 's/# TIRPC=YES/TIRPC=YES/g' ${EPICS_PATH}/support/asyn/configure/CONFIG_SITE
fi
}

Install_stream(){
# .. streamdevice install ..

cd ${EPICS_PATH}/support

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
        9) exit 0 ;;
    esac
done

exit 0
