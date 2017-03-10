#!/bin/bash
##########################################################################
# LICENSE CDDL 1.0 + GPL 2.0
#
#  Author      M. Ritschel 
#  Company     Trivadis GmbH Hamburg
#  Date        08.03.2017
#  Copyright   (c) 1982-2017 Trivadis GmbH. All rights reserved.
#
# Docker Basis Oracle Database
# ------------------------------
# Start-Script for the Trivadis Oracle Basis docker images
# 
#
##########################################################################
set -e

source $SCRIPT_DIR/colorecho


ORACLE_SID=$1
# Check whether ORACLE_SID is passed on
if [ "$ORACLE_SID" == "" ]; then
  ORACLE_SID=ORCLCDB
fi;

ORACLE_PDB=$2
# Check whether ORACLE_PDB is passed on
if [ "$ORACLE_PDB" == "" ]; then
  ORACLE_PDB=ORCLPDB1
fi;

ORACLE_CDB=$3
# Check whether ORACLE_PDB is passed on
if [ "$ORACLE_CDB" == "" ]; then
  ORACLE_CDB=false
fi;


# Auto generate ORACLE PWD
ORACLE_PWD="`openssl rand -base64 8`1"
echo_green "###############################################################################################";
echo_green "Automatic generated password fOr the user "SYS", "SYSTEM" AND "PDBAMIN" is  $ORACLE_PWD";
echo_green "###############################################################################################";

# Modify the response file for the database gerneration
cp $SCRIPT_DIR/$DBCA_RSP $SCRIPT_DIR/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $SCRIPT_DIR/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $SCRIPT_DIR/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $SCRIPT_DIR/dbca.rsp
sed -i -e "s|###CONTAINER_DB###|$ORACLE_CDB|g" $SCRIPT_DIR/dbca.rsp
#sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $SCRIPT_DIR/dbca.rsp

# Create config files for sqlnet.ora, tnsnames.ora, listener.ora
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= {TNSNAMES, EZCONNECT, HOSTNAME}" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -createDatabase -responseFile $SCRIPT_DIR/dbca.rsp ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log
 
echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" >> $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)" >> $ORACLE_HOME/network/admin/tnsnames.ora

# Default for ORACLE Contrainer DB
if [ "$ORACLE_CDB" == "true" ]; then
   # Remove second control file and alter database to PDB auto open
   sqlplus / as sysdba << EOF
      ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
      ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EOF
else
   # Remove second control file 
   sqlplus / as sysdba << EOF
      ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   EOF
fi;

# Remove temporary response file
rm $SCRIPT_DIR/$DBCA_RSP
