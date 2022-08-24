#!../../bin/linux-aarch64/serialTest

## You may have to change serialTest to something else
## everywhere it appears in this file

< envPaths
epicsEnvSet "STREAM_PROTOCOL_PATH" "$(TOP)/db" 
epicsEnvSet("EPICS_DB_INCLUDE_PATH","$(TOP)/db")
cd "${TOP}"

## Register all support components
dbLoadDatabase "dbd/serialTest.dbd"
serialTest_registerRecordDeviceDriver pdbbase

################################################################
## Connect device

drvAsynIPPortConfigure("TPG366PORT",192.168.0.30:8000)

drvAsynSerialPortConfigure("ACP40-1_PORT","/dev/ttyr01")

drvAsynSerialPortConfigure("ACP40-2_PORT","/dev/ttyr03")

# drvAsynSerialPortConfigure("OBC4VPORT","/dev/ttyr00")

#drvAsynSerialPortConfigure("A100L_PORT","/dev/ttyr02")

#drvAsynSerialPortConfigure("TC400_PORT","/dev/ttyUSB0")

#drvAsynSerialPortConfigure("OsakaPump_PORT","/dev/?????")

#drvAsynSerialPortConfigure("PSC232-1_PORT","/dev/?????")
#drvAsynSerialPortConfigure("PSC232-2_PORT","/dev/?????")
#drvAsynSerialPortConfigure("PSC232-3_PORT","/dev/?????")

#drvAsynSerialPortConfigure("SM15K-1_PORT","/dev/?????")
#drvAsynSerialPortConfigure("SM15K-2_PORT","/dev/?????")
#drvAsynSerialPortConfigure("SM15K-3_PORT","/dev/?????")

################################################################

################################################################
## Load record instances

# Load TPG366 db
dbLoadTemplate("db/TPG366.subs","CONTROLLER=TPG366,PORT=TPG366PORT,WARN_=2E-07,ALARM_=5E-07,S1=ChamberVacSensor,MIN1=-4,MAX1=-3,WARN1=Inf,ALARM1=Inf,S2=sensor2,S3=sensor3,S4=sensor4,S5=sensor5,S6=sensor6,MIN6=-4,MAX6=-3,WARN6=Inf,ALARM6=Inf")

# Load ACP40 db

dbLoadTemplate("db/ACP40.subs","CONTROLLER=ACP40,ADDR1=101,PORT1=ACP40-1_PORT,S1=1,ADDR2=000,PORT2=ACP40-2_PORT,S2=2")

#dbLoadRecords("db/OBC.db","CONTROLLER=musr:OBC,PORT=OBC4VPORT")

#dbLoadTemplate("db/A100L.subs","CONTROLLER=musr:A100L,PORT=A100L_PORT")

#dbLoadRecords("db/TC400.db","CONTROLLER=musr:TC400,PORT=TC400_PORT")

#dbLoadRecords("db/OsakaPump.db","CONTROLLER=musr:OsakaPump,PORT=OsakaPump_PORT")

#dbLoadTemplate("db/PSC232.subs","CONTROLLER=musr:PSC232,S1=1,S2=2,S3=3,PORT1=PSC232-1_PORT,PORT2=PSC232-2_PORT,PORT3=PSC232-3_PORT")

#dbLoadTemplate("db/SM15K.subs","CONTROLLER=musr:SM15K,S1=1,S2=2,S3=3,PORT1=SM15K-1_PORT,PORT2=SM15K-2_PORT,PORT3=SM15K-3_PORT")


################################################################

cd "${TOP}/iocBoot/${IOC}"
iocInit

## Start any sequence programs
#seq sncxxx,"user=raiseHost"
# seq sncExample
