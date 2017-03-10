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
#  Script to extract and install the Oracle database software
# 
#
##########################################################################


source $SCRIPT_DIR/colorecho

EDITION=$1

# Check whether edition has been passed on
if [ "$EDITION" == "" ]; then
   echo_yellow "ERROR: No edition has been passed on!"
   echo_yellow "Please specify the correct edition!"
   exit 1;
fi;

# Check whether correct edition has been passed on
if [ "$EDITION" != "EE" -a "$EDITION" != "SE2" ]; then
   echo_yellow "ERROR: Wrong edition has been passed on!"
   echo_yellow "Edition $EDITION is no a valid edition!"
   exit 1;
fi;

# Check if the ORACLE_BASE is set
if [ "$ORACLE_BASE" == "" ]; then
   echo_yellow "ERROR: ORACLE_BASE has not been set!"
   echo_yellow "You have to have the ORACLE_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
   echo_red "ERROR: ORACLE_HOME has not been set!"
   echo_red "You have to have the ORACLE_HOME environment variable set to a valid value!"
   exit 1;
fi;


# Replace place holders
# ---------------------
sed -i -e "s|###ORACLE_EDITION###|$EDITION|g" $INSTALL_DIR/$DB_RSP && \
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" $INSTALL_DIR/$DB_RSP && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" $INSTALL_DIR/$DB_RSP && \
cd $INSTALL_DIR       && \
unzip $DB_FILE_1 && \
rm $DB_FILE_1    && \
$INSTALL_DIR/database/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_DIR/$DB_RSP -ignoresysprereqs -ignoreprereq && \
rm -rf $INSTALL_DIR/database && \
ln -s $SCRIPT_DIR/$PWD_FILE $HOME/ && \
echo "DEDICATED_THROUGH_BROKER_LISTENER=ON"  >> $ORACLE_HOME/network/admin/listener.ora && \
echo "DIAG_ADR_ENABLED = off"  >> $ORACLE_HOME/network/admin/listener.ora;

# Check whether Perl is working
chmod ug+x $INSTALL_DIR/install_perl.sh && \
$ORACLE_HOME/perl/bin/perl -v || \
$INSTALL_DIR/install_perl.sh
