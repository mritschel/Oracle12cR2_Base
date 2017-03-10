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

# Install latest Perl

cd $INSTALL_DIR
mv $ORACLE_HOME/perl $ORACLE_HOME/perl.old
wget http://www.cpan.org/src/5.0/perl-5.14.1.tar.gz
tar -xzf perl-5.14.1.tar.gz
cd perl-5.14.1
./Configure -des -Dprefix=$ORACLE_HOME/perl -Doptimize=-O3 -Dusethreads -Duseithreads -Duserelocatableinc
make clean
make
make install

# Copy old binaries into new Perl dir
cd $ORACLE_HOME/perl
rm -rf lib/ man/
cp -r ../perl.old/lib/ .
cp -r ../perl.old/man/ .
cp ../perl.old/bin/dbilogstrip bin/
cp ../perl.old/bin/dbiprof bin/
cp ../perl.old/bin/dbiproxy bin/
cp ../perl.old/bin/ora_explain bin/
cd $ORACLE_HOME/lib
ln -sf ../javavm/jdk/jdk7/lib/libjavavm12.a

# Relink Oracle
cd $ORACLE_HOME/bin
if ! relink all; then
	echo "Relink all failed"
	cat "$ORACLE_HOME/install/relink.log"
	exit 1
fi

# Cleanup
rm -rf $ORACLE_HOME/perl.old
rm -rf $INSTALL_DIR/perl-5.14.1*
