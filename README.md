# Oracle Linunx with Oracle Database 12c Release 2 installation
-------------------------------------------------------------------------

## Content

* Oracle Linux Server release 7.3
* Oracle Database 12.2.0.1 Standard Edition 2 
* Perl 5, version 14, subversion 1 (v5.14.1) 
	
Pull the latest trusted build from [here](https://hub.docker.com/r/mritschel/oracle12cr2_base).


## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Pull the image

		docker pull mritschel/oracle12cr2_base

2. Create the container

		docker run -d -p 8080:8080 -p 5500:5500 -p 1521:1521 -v [<host mount point>:]/u01/oracle/oradata  --name oracle-base mritschel/oracle12cr2_base 
		
3. wait around **5 minutes** until the image is downloaded. Check logs with ```docker logs oracle base```. The container stops if an error occurred. 
   Check the logs to determine how to proceed.
   
   On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:
   ###################################
    Database is started and ready!
   ###################################

	
### Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
DBCA_TOTAL_MEMORY | ```1024``` | Keep in mind that DBCA fails if you set this value too low
ORACLE_BASE | ```/u01/app/oracle``` | Oracle Base directory
ORACLE_HOME | ```/u01/app/oracle/product/12.1.0.2/dbhome_1 ``` | Oracle Home directory
PATH | ```$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \``` | Path
ORACLE_SID | ```ORCLCDB``` | The Oracle SID
SOFTWARE_HOME | ```$ORACLE_BASE/install``` | Install directory 
SCRIPTS_HOME | ```$ORACLE_BASE``` | Scripts directory 

    
### Database Connections

Once the container has been started and the database created you can connect to it just like to any other database:

  sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
  sqlplus system/<your password>@//localhost:1521/<your SID>
  sqlplus pdbadmin/<your password>@//localhost:1521/<Your PDB name>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

	https://localhost:5500/em/

**NOTE**: Oracle Database bypasses file system level caching for some of the files by using the `O_DIRECT` flag. It is not advised to run the container on a file system that does not support the `O_DIRECT` flag.

#### Changing the admin accounts passwords

On the first startup of the container a random password will be generated for the database. You can find this password in the output line:  
  ######################################################################
  Automatic generated password fOr the user SYS, SYSTEM AND PDBAMIN is 
  ######################################################################
   
The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:

	docker exec <container name> ./set_Password.sh <your password>

## Backup

Complete the following steps to backup the data volume:

1. Stop the container with 

		docker stop oracle-base
		
2. Backup the data volume to a compressed file ```oracle-base.tar.gz`` in the current directory with a little help from the linux image

		docker run --rm --volumes-from oracle-base -v $(pwd):/backup linux tar czvf /backup/oracle-base.tar.gz /u01/app/oracle
		
3. Restart the container

		docker start oracle-base


## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/): 

* [Existing issues](https://github.com/mritschel/oracle12cr2_base/issues)

## License

docker-oracle12c-apex is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>. 

See [Oracle Database Licensing Information User Manual](http://docs.oracle.com/database/121/DBLIC/editions.htm#DBLIC109) and [Oracle Database 12c Standard Edition 2](https://www.oracle.com/database/standard-edition-two/index.html) for further information.
