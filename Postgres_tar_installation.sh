#!/bin/bash

#################################################################################################
# Configuration section
#################################################################################################

# Postgres installation directory
export PG_INSTALL_DIR=/var/lib/postgresha
export PG_INSTALL_DIR=/var/lib/postgresha
# Postgres Data directory
export PGDATA=/var/lib/postgresha/data
# Default database
export PGDATABASE=postgres
# Default admin database.
export PG_DEFAULT_ADMIN_DB=postgres
# Postgres username.
export PGUSER=postgres
export PGUSER_PASSWD=PostgresHa
export PGUSER_UID=600
export PG_USER_HOME_DIR=/var/lib/postgresha

# Postgres daemon port.
export PGPORT=5522
# FileName and Version.
export PG_VERSION=postgresql-9.2.4;

export PG_DOWNLOAD_LOCATION=https://ftp.postgresql.org/pub/source/v9.2.4/postgresql-9.2.4.tar.gz

export PATH=${PG_INSTALL_DIR}/bin:$PATH

#################################################################################################

echo "Downloading Postgres tabball.."
wget ${PG_DOWNLOAD_LOCATION};

echo "Extracting Postgres tabball";
tar -xzf ${PG_VERSION}.tar.gz

if [ $? -ne 0 ] ; then
        echo "Failed to extract tarball corrupted/partition full"
        exit 1;
fi

cd ${PG_VERSION}

# Postgres isntallation directory

echo "Creating installation directory ${PG_INSTALL_DIR}";
mkdir -p ${PG_INSTALL_DIR};

# Installing Postgres dependant libraries.

echo "Installing dependant libraries before compiling";
yum install -y readline-devel readline zlib zlib-devel

if [ $? -ne 0 ] ; then
        echo "Failed to install dependant libraries"
        exit 1;
fi

echo "Configuring .."
./configure --prefix=${PG_INSTALL_DIR}
echo "Compiling .."
gmake ;
echo "Compiling and installing.."
gmake install


################################
# Service user creation section.
################################

mkdir -p ${PGDATA};

if [[ ${PGUSER_UID} == "" ]]; then
        useradd -d ${PG_USER_HOME_DIR} ${PGUSER}
else
        useradd -d ${PG_USER_HOME_DIR} -u ${PGUSER_UID} ${PGUSER}
fi

echo "${PGUSER_PASSWD}" | passwd --stdin ${PGUSER};

mkdir -p ${PGDATA};

chown -R ${PGUSER}.${PGUSER} ${PGDATA};
chown -R ${PGUSER}.${PGUSER} ${PG_USER_HOME_DIR};

####################################
# Configuring start up script.
####################################

export CONTRIB_START_SCRIPT_LOC=contrib/start-scripts/linux;

sed -i "s|prefix\=.*|prefix=${PG_INSTALL_DIR}|" ${CONTRIB_START_SCRIPT_LOC};
sed -i "s|PGDATA\=.*|PGDATA=${PGDATA}|" ${CONTRIB_START_SCRIPT_LOC};
sed -i "s|PGUSER\=.*|PGUSER=${PGUSER}|" ${CONTRIB_START_SCRIPT_LOC};

cp contrib/start-scripts/linux "/etc/init.d/${PGUSER}"
chmod +x "/etc/init.d/${PGUSER}"

environmentfile=${PG_INSTALL_DIR}/postgres-env.sh;

echo "export PGDATA=${PGDATA}" >> ${environmentfile};
echo "export PGPORT=${PGPORT}" >> ${environmentfile};
echo "export PGDATABASE=${PG_DEFAULT_ADMIN_DB}" >> ${environmentfile};
echo "export PATH=${PG_INSTALL_DIR}/bin:$PATH" >> ${environmentfile};

chmod +x ${PG_INSTALL_DIR}/postgres-env.sh;

echo "source ${PG_INSTALL_DIR}/postgres-env.sh" > ${PG_INSTALL_DIR}/.bashrc;


su ${PGUSER} -c "${PG_INSTALL_DIR}/bin/pg_ctl initdb -D ${PGDATA}";

echo "Updating listen address and port .."

sed -i "s|#listen_addresses = 'localhost'|listen_addresses = '0.0.0.0'|" ${PGDATA}/postgresql.conf
sed -i "s|#port = 5432|port = $PGPORT|" ${PGDATA}/postgresql.conf

#${PG_INSTALL_DIR}/bin/pg_ctl initdb -U ${PGUSER};
mkdir -p ${PGDATA}
chown -R ${PGUSER}.${PGUSER} ${PGDATA};

echo "Start Postgres using /etc/init.d/$PGUSER as sudo ";

###########################################################
# Creating user and DB after servers set up.
	# create databse test_db1;
	# create user user1 with password 'pass1';
	# alter database test_db1 owner to user1;
	# alter user user1 with password 'pass1';

# Modify server pg_hba.conf
# Restart server
###########################################################
