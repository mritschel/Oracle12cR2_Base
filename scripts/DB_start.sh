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
#  Database Start-Script  
# 
#
##########################################################################

source $SCRIPT_DIR/colorecho

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo_yellow "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

# Start Listener
lsnrctl start

# Start database
sqlplus / as sysdba << EOF
   STARTUP;
EOF
