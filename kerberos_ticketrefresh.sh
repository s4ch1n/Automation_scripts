#!/bin/bash
##############################################################################################
# 
# Utility for refreshing Kerberos tickets 
#  
##############################################################################################

##############################################################################################
# Configuration section
##############################################################################################

# Kerberos ticket cache file location
export KRB5CCNAME=/opt/mstr/krb_user1_tktcache
# Kerberos keytab location
export KRB5_KTNAME=user1.keytab
# Kerberos principal name 
export KRB_PRICIPALNAME=user1@ENT.LOCAL

##############################################################################################

renewOrRegenerate()
{
	renew="false";
	if [ -f ${CACHE_FILE_LOC} ] ; then
		count=`cat ${CACHE_FILE_LOC}`
        if [ ${count} -lt ${KRB_TICKET_LIFE} ] ; then
			renew="true";
        else
			renew="false";
		fi
	else
        renew="false";
	fi

	if [[ "${renew}" == "false" ]] ; then
		echo "1" > ${CACHE_FILE_LOC}
	elif [[ "${renew}" == "true" ]] ; then
		((count++));
		echo "${count}" > ${CACHE_FILE_LOC};
else
        renew="error"
fi

echo "${renew}";

}

##############################################################################################
#Execution starts here
##############################################################################################

export CACHE_DIR="/tmp/krb5refresh_cache/"
export CACHE_FILE_LOC=${CACHE_DIR}/.count
# Kerberos ticket life time in days.
export KRB_TICKET_LIFE=6

mkdir -p ${CACHE_DIR};

renew=`renewOrRegenerate`

if [[ "${renew}" == "false" ]] ; then
        echo "Requesting for a new kerberos ticket"
        # command to obtain a new kerberos ticket.
        kinit -k ${KRB_PRICIPALNAME}
elif  [[ "${renew}" == "true" ]] ; then
        # Command to renew the existing ticket.
        echo "Renewing existing kerberos ticket"
        kinit -R -k ${KRB_PRICIPALNAME}
else
        echo "ERROR - ${renew} !!"

fi
