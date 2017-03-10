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
# This is the Dockerfile for Oracle Database 12c Release 1  
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) linuxx64_12201_database.zip
#     Download Oracle Database Standard Edition 2 and Enterprise Edition
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
# 
# Put the downloaded files in the software directory 
# Run: 
#      $ docker build -t mritschel/oracle12cr2_base:latest . 
#
##########################################################################

FROM oraclelinux:7-slim

# Maintainer
# ----------
MAINTAINER Martin RItschel <martin.ritschel@trivadis.com.com>

LABEL  Basic oracle 12c R2  

# Environment variables for the install files ans scripts (do NOT change)
# -------------------------------------------------------------
ENV SOFTWARE_HOME=./software \
    SCRIPT_HOME=./scripts

# Environment variables for this Oracle installation
# -------------------------------------------------------------
ENV ORACLE_VERSION=SE2 \
    ORACLE_BASE=/u01/oracle \
    ORACLE_HOME=/u01/oracle/product/12.2.0.1/dbhome_1

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV DB_FILE_1="linuxx64_12201_database.zip" \
    DB_RSP="install.rsp" \
    DBCA_RSP="dbca.rsp.tpl" \
    PWD_FILE="set_password.sh" \
    PERL_INSTALL_FILE="install_perl.sh" \
    RUN_FILE="init_oracle.sh" \
    START_FILE="DB_start.sh" \
    CREATE_DB_FILE="DB_create.sh" \
    ORACLE_CDB="true" \
    INSTALL_DB_BINARIES_FILE="install_oracle.sh" \    
    FORMAT_ECHO="colorecho" \
    PRE_INSTALL="pre_install.sh" \
    ENTRY_FILE="entrypoint.sh"

# Use second ENV so that variable get substituted
# -------------------------------------------------------------
ENV INSTALL_DIR=$ORACLE_BASE/install \
    SCRIPT_DIR=$ORACLE_BASE/scripts \
    PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib


# Copy install binaries
# -----------------------
COPY $SOFTWARE_HOME/$DB_FILE_1 $INSTALL_DIR/

# Copy install scripts
# -----------------------
COPY $SCRIPT_HOME/$FORMAT_ECHO $SCRIPT_HOME/$PRE_INSTALL $SCRIPT_HOME/$DB_RSP $SCRIPT_HOME/$PERL_INSTALL_FILE $SCRIPT_HOME/$SETUP_LINUX_FILE $SCRIPT_HOME/$CHECK_SPACE_FILE $SCRIPT_HOME/$INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Copy install scripts to Oracle Base 
# -----------------------------------
COPY $SCRIPT_HOME/$FORMAT_ECHO $SCRIPT_HOME/$RUN_FILE $SCRIPT_HOME/$START_FILE $SCRIPT_HOME/$CREATE_DB_FILE $SCRIPT_HOME/$CONFIG_RSP $SCRIPT_HOME/$PWD_FILE $SCRIPT_DIR/


RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$PRE_INSTALL

# Install DB software binaries
USER oracle
RUN $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE $ORACLE_VERSION

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh && \
    rm -rf $INSTALL_DIR

USER oracle
WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 
EXPOSE 5500
EXPOSE 8080
    
# Define default command to start Oracle Database. 
CMD $SCRIPT_DIR/$RUN_FILE
