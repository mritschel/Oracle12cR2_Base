#!/bin/bash
##########################################################################
# LICENSE CDDL 1.0 + GPL 2.0
#
#  Author      M. Ritschel 
#  Company     Trivadis GmbH Hamburg
#  Date        08.03.2017
#  Copyright   (c) 1982-2017 Trivadis GmbH. All rights reserved.
#  
#  Docker Basis Oracle Database
#  ------------------------------
#  Start-Script for the Trivadis Oracle Basis docker images
# 
#
##########################################################################

source $SCRIPT_DIR/colorecho

########### Move DB files ############
function moveFiles {

   if [ ! -d $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID ]; then
      mkdir -p $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   fi;
   # move files to the volumne
   mv $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/dbs/orapw$ORACLE_SID $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

   # Copy oratab to the volumne
   cp /etc/oratab $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   
   symLinkFiles;
}

########### Symbolic link DB files ############
function symLinkFiles {

   if [ ! -L $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
   fi;
   
   if [ ! -L $ORACLE_HOME/dbs/orapw$ORACLE_SID ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
   fi;
   
   if [ ! -L $ORACLE_HOME/network/admin/tnsnames.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
   fi;

   # Copy oratab to the volumne 
   cp $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab /etc/oratab

}

########### SIGINT handler ############
function dbInt() {
   echo_red "Stopping container."
   echo_red "SIGINT received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function dbTerm() {
   echo_red "Stopping container."
   echo_red "SIGTERM received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
EOF
   lsnrctl stop
}

########### SIGKILL handler ############
function dbKill() {
   echo_red "SIGKILL received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown abort;
EOF
   lsnrctl stop
}

############# MAIN ################


# Check whether container has enough memory
if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
   if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 2147483648 ]; then
      echo_red "Error: The container doesn't have enough memory allocated."
      echo_red "A database container needs at least 2 GB of memory."
      echo_red "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
      exit 1;
   fi;
fi;

# SIGINT handling
trap dbInt SIGINT

# SIGTERM handling
trap DBTerm SIGTERM

# SIGKILL handling
trap dbKill SIGKILL

# Default for ORACLE Contrainer DB
if [ "$ORACLE_CDB" == "" ]; then
   export ORACLE_CDB=false
fi;

# Default for ORACLE SID
if [ "$ORACLE_SID" == "" ]; then
   if [ "$ORACLE_CDB" == "true" ]; then
      export ORACLE_SID=ORCLCDB
   else
      export ORACLE_SID=ORCL
   fi;
else
  # The ORACLE_SID can be a maximum of 12 characters
  if [ "${#ORACLE_SID}" -gt 12 ]; then
     echo "Error: The ORACLE_SID must only be up to 12 characters long."
     exit 1;
  fi;
  
  # Check if the ORACLE_SID is alphanumeric
  if [[ "$ORACLE_SID" =~ [^a-zA-Z0-9] ]]; then
     echo "Error: The ORACLE_SID must be alphanumeric."
     exit 1;
   fi;
fi;

# Default for ORACLE PDB
if [ "$ORACLE_PDB" == "" ]; then
   if [ "$ORACLE_CDB" == "true" ]; then
      export ORACLE_PDB=ORCLPDB1
   fi;
fi;

# Default for ORACLE CHARACTERSET
if [ "$ORACLE_CHARACTERSET" == "" ]; then
   export ORACLE_CHARACTERSET=AL32UTF8
fi;

# Check whether database already exists
if [ -d $ORACLE_BASE/oradata/$ORACLE_SID ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
      mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
   fi;
   
   # Start database
   $SCRIPT_DIR/$START_FILE;
   
else
   # Remove database config files, if they exist
   rm -f $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
   rm -f $ORACLE_HOME/dbs/orapw$ORACLE_SID
   rm -f $ORACLE_HOME/network/admin/tnsnames.ora
   
   # Create database
   $SCRIPT_DIR/$CREATE_DB_FILE $ORACLE_SID $ORACLE_PDB $ORACLE_CDB;
   
   # Move database operational files to oradata
   moveFiles;
fi;

echo_green "###################################"
echo_green " Database is started and ready!"
echo_green "###################################"

# Check if the script entrypoint.sh is present 
if [ -f $SCRIPT_DIR/$ENTRY_FILE ]
  then
    $SCRIPT_DIR/$ENTRY_FILE
fi

tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log &
childPID=$!
wait $childPID
