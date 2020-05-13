#!/bin/bash
# Author: Prof T
# URL: chaveran.com
# Description: DATA Pump Export Backup Script 
# Usage: ./impdp_script.sh <email_address>  <dmp file>
#
# SUMMARY OF STEPS
# =================
# 1. declare script variables
# 2. check script arguments
# 3. delete old log
# 4. unzip zip dmp and perform full db import
# 5. email backup status 

#Backup script by Export backup.
export HOST_NAME=`uname -n`
CDATE=`date +%d%m%Y`
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
ORACLE_SID=profdb
LOGFILE=/orabackup/dpexport_backups/expdp_$CDATE.log
EXPORT_PATH=/home/oracle/backup_scripts
DATAPUMP_DIR_PATH=/orabackup/dpexport_backups
DATAPUMP_DIR_NAME=DPEXPORTS
EMAIL_ADDRESS=$1
DMP_FILE=$2

# CHECK USAGE
if [ $# -ne 2 ]
then
 echo -e "\nUsage: $0 <email_address> <dmp zipped file>\n"
 exit 1;
fi

# DELETE OLD LOG
if [ -f "$LOGFILE" ]
then
 rm -fr $LOGFILE
fi

# UNZIP DMP AND START IMPORT
echo "Starting" > $LOGFILE

if [ -f "$EXPORT_PATH/$DMP_FILE" ]
then
 unzip $EXPORT_PATH/${DMP_FILE} -d / | tee -a $LOGFILE
 impdp system@hrdev directory=DPEXPORTS dumpfile=`echo "$DMP_FILE"|sed 's/.zip//'` logfile=impdp_$CDATE.log parallel=10 table_exists_action=SKIP | tee -a $LOGFILE

# MAIL IMPDP STATUS
 if [ "`grep failed $LOGFILE|wc -l`" -gt 0 ]
 then
  mailx -s "oracle : impdp successfully" $EMAIL_ADDRESS dohkoranteng@gmail.com < $LOGFILE
 else
  mailx -s "oracle : impdp failed" $EMAIL_ADDRESS < $LOGFILE
 fi

else

# FAIL OUT IF DMP ZIPPED FILE NOT FOUND
 echo -e "\nError: Unable to find export dmp zipped file '$DATAPUMP_DIR_PATH/$DMP_FILE'\n"
 exit 1;

fi
