#!../../bin/linux-x86_64/testIOC

#- You may have to change testIOC to something else
#- everywhere it appears in this file

< envPaths

cd "${TOP}"

## Register all support components
dbLoadDatabase "dbd/testIOC.dbd"
testIOC_registerRecordDeviceDriver pdbbase

## Load record instances
dbLoadTemplate "db/user.substitutions"
dbLoadRecords "db/testIOCVersion.db", "user=musr4"
dbLoadRecords "db/dbSubExample.db", "user=musr4"
dbLoadRecords "db/simpleDB.db", "user=musr4"

#- Set this to see messages from mySub
#var mySubDebug 1

#- Run this to trace the stages of iocInit
#traceIocInit

cd "${TOP}/iocBoot/${IOC}"
iocInit

## Start any sequence programs
#seq sncExample, "user=musr4"
seq testseq, "user=musr4"
