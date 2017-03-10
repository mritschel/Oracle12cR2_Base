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

# Check CSpace 
REQUIRED_SPACE_GB=15
if [ `df -B 1G . | tail -n 1 | awk '{print $4'}` -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo_red "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo_red "$script_name: ERROR - There is not enough space available in the docker container."
  echo_red "$script_name: The container needs at least $REQUIRED_SPACE_GB GB available."
  echo_red "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
fi;

mkdir -p $ORACLE_BASE/oradata && \
chmod ug+x $SCRIPT_DIR/$PWD_FILE && \
chmod ug+x $SCRIPT_DIR/$RUN_FILE && \
chmod ug+x $SCRIPT_DIR/$START_FILE && \
chmod ug+x $SCRIPT_DIR/$CREATE_DB_FILE && \
groupadd -g 500 dba && \
groupadd -g 501 oinstall && \
useradd  -u 500 -d /home/oracle -g dba -G dba,oinstall -m -s /bin/bash oracle && \
echo oracle:oracle | chpasswd && \
yum -y install oracle-database-server-12cR2-preinstall unzip wget tar openssl zip gcc ksh which sudo && \
yum clean all && \
chown -R oracle:dba $ORACLE_BASE
