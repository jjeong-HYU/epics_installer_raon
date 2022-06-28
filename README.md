# epics_installer_raon
EPICS_IOC installer for RAON muSR facility (Ubuntu)

please execute this shell script in super user account.

==============================================================
How to use
==============================================================
[root@host ~]# git clone https://github.com/jjeong-HYU/epics_installer_raon
[root@host ~]# cd epics_installer_raon/epics_installer_v1.0
[root@host ~]# chmod +x installer.sh
[root@host ~]# ./installer.sh

Then, type where epics software should be installed. (ex: /epics or ~/epics e.t.c.)
***The folder has to be made before executing this shell script.

    Install option:
    A . Whole system(EPICS_BASE, Asyn, Calc, StreamDevice)
    Ac. Whole system(EPICS_BASE, Asyn, Calc, StreamDevice, Archappl)
    1 . Prerequisition
    2 . EPICS_BASE_7.0.6.1
    3 . Calc
    4 . Asyn(Should be installed after calc was installed)
    5 . StreamDevice(Should be installed after calc,asyn was installed)
    6 . Archiver appliance
    7 . RAON_Serial_IOC(Should be installed after whole system was installed)
    8 . Create setEpicsEnv.sh in base folder(Should be executed after base was installed)
    9 . exit

A : Install EPICS Base, Asyn module, Calc module, and StreamDevice module. Modules are saved in ${INSTALL_PATH}/support.
Ac : Install all software above and additionally, archiver appliance server also.
1. apt update and upgrade, and install make, gcc, g++, build-essential, libcap-dev, python2.7. and set the command 'python' executes python2.7
2. Install only EPICS base. (version 7.0.6.1)
3. Install recent Calc module.
4. Install recent Asyn module. (Should be installed after calc was installed)
5. Install recent StreamDevice module. (Should be installed after calc, asyn was installed)
6. Install Archiver appliance. (Should be installed after EPICS base was installed.
7. Install RAON muSR facility's Control example IOC.
8. Create setEpicsEnv.sh file in base folder. (Should be executed after base was installed)

When installing EPICS base, the command prompt will ask if you need to create setEpicsEnv.sh and add it to your bashrc.
If it's the first time you run it, go ahead and reject it if it's a reinstall.

When installing Archiver appliance, the command prompt will ask if you need to create mysql account and database table.
If it's the first time you run it, go ahead and reject it if it's a reinstall.
