#!/bin/bash
# Author: Prof T
# URL: chaveran.com
# Description: DATA Pump Export Backup Script 
# Usage: ./expdp_script.sh <email_address>
#
# SUMMARY OF STEPS
# =================
# 1. declare script variables
# 2. check script arguments
# 3. delete old log and dump file for given day matching today
# 4. perform full db export
# 5. compress export dmp file to $ZIP_PATH
# 6. email backup status 

# variables
HOST_NAME=`uname -n`
CDATE=`date +%d%m%Y`
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
ORACLE_SID=profdb
LOGFILE=/orabackup/dpexport_backups/expdp_$CDATE.log
EXPORT_PATH=/orabackup/dpexport_backups
ZIP_PATH=/home/oracle/backup_scripts
DMP_FILE=expdp_$CDATE.dmp
EMAIL_ADDRESS=$1

# check usage
if [ $# -ne 1 ]
then
 echo -e "\nUsage: $0 <email_address>\n"
 exit 1;
fi

# delete old log and dmp file
if [ -f "$EXPORT_PATH/$DMP_FILE" ]
then 
 rm -fr $EXPORT_PATH/$DMP_FILE
fi

if [ -f "$LOGFILE" ]
then
 rm -fr $LOGFILE 
fi

# perform expdp
echo "Starting: `date`" > $LOGFILE
expdp system@hrdev  directory=DPEXPORTS dumpfile=expdp_$CDATE.dmp logfile=expdp_$CDATE.log FULL=Y compression=all parallel=4 exclude=statistics | tee -a $LOGFILE
echo "Backup Completed: `date`" | tee -a $LOGFILE

# compress dmp file
echo "Compressing backup: `date`" | tee -a $LOGFILE 
zip $ZIP_PATH/${DMP_FILE}.zip $EXPORT_PATH/$DMP_FILE | tee -a $LOGFILE
echo "Compression Completed: `date`" | tee -a $LOGFILE

# mail expdp status
if [ "`grep failed $LOGFILE|wc -l`" -gt 0 ] 
then
 mailx -s "oracle : expdp and cp completed successfully" $EMAIL_ADDRESS dohkoranteng@gmail.com < $LOGFILE
else 
 mailx -s "oracle : expdp failed" $EMAIL_ADDRESS < $LOGFILE
fi
