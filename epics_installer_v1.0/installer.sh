#! /bin/bash

# .. env variable setting ..

INSTALLER_PATH=${PWD##*/}

# ..epics install..

mkdir ${HOME}/epics

cd ${HOME}/epics

wget https://epics.anl.gov/download/base/base-7.0.6.1.tar.gz

tar zxvf base-7.0.6.1.tar.gz

cd base-7.0.6.1

make

echo 'export EPICS_BASE=${HOME}/epics/base-7.0.6.1' >> ~/.bashrc 
echo 'export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)' >> ~/.bashrc 
echo 'export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}' >> ~/.bashrc 

source ~/.bashrc

# .. support ..

mkdir ${HOME}/epics/support

# .. calc install ..

cd ${HOME}/epics/support

git clone https://github.com/epics-modules/calc

cd calc

cp ${INSTALLER_PATH}/option/calc/RELEASE .

make

# .. asyn install ..

cd ${HOME}/epics/support

git clone https://github.com/epics-modules/asyn

cd asyn

cp ${INSTALLER_PATH}/option/asyn/RELEASE .

make

# .. streamdevice install ..

cd ${HOME}/epics/support

git clone https://github.com/paulscherrerinstitute/StreamDevice.git

cd StreamDevice/

rm GNUmakefile

cp ${INSTALLER_PATH}/option/StreamDevice/RELEASE .

make

# .. IOC install ..

cd ${HOME}/epics/

cp ${INSTALLER_PATH}/option/serialTest_RAON_20220420 . -r

cd serialTest_RAON_20220420

make clean

make

exit 0