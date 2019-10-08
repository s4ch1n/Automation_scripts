FROM_ADDR=abcd@gmail.com
PASS=XXX
RECIPIENT1=abcd@gmail.com
RECIPIENT2=cde@gmail.com
SUBJECT_PREFIX="EMAIL Subject - `date +'%d %b %Y - %H:%M'`"

oldDownloadFile=".page_status.txt_1"
newDownloadFile=".page_status.txt"

[ ! -f ${oldDownloadFile} ] && noOldFile="true" ;

CMD  h4status.js > ${newDownloadFile}
/usr/local/bin/node  abcd.js  >> ${newDownloadFile}

[ $? -ne 0 ] && exit 1 ;

[[ "${noOldFile}" == "true" ]] &&  cp ${newDownloadFile} ${oldDownloadFile}

diff $newDownloadFile  $oldDownloadFile

if [ $? -eq 0 ] ; then
    SUBJECT="${SUBJECT_PREFIX} (No Updates)"
else
    SUBJECT="${SUBJECT_PREFIX} (New Updates)***"
fi

cp  ${newDownloadFile} ${oldDownloadFile}

echo $SUBJECT ;

echo -e "From: ${FROM_ADDR}\nTo: ${RECIPIENT1}\nSubject: ${SUBJECT}\n\n`cat ${newDownloadFile}`"  > email.txt

## Uses OSX curl utility
/usr/bin/curl --url 'smtps://smtp.gmail.com:465' --ssl-reqd   --mail-from "${FROM_ADDR}"   --mail-rcpt "${RECIPIENT1}" --mail-rcpt "${RECIPIENT2}"  --user "${FROM_ADDR}:${PASS}" -T email.txt   -v &>/dev/null
