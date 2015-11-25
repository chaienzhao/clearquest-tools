#!/bin/sh

PERL="/usr/bin/perl"
CQPERL="/opt/rational/clearquest/bin/cqperl"
CQDIR="/home/eenzcha/clearquest"
ANSWER_TIME="$CQDIR/answer_time.pl"

echo -n "Remove the workbook downloaded last time ...    "
`rm /home/eenzcha/clearquest/Main_SGSN_answertimeRolling.xls >/dev/null 2>&1`
if [ $? -ne 0 ]
then
    echo "Remove failed, please check!"
else
    echo "Done"
fi

echo -n "Start downloading Main_SGSN_answertimeRolling.xls ...    "
`wget http://www.mo.sw.ericsson.se/PC_Metrics/Statistics/Mirrored_reports/Main_SGSN_answertimeRolling.xls >/dev/null 2>&1`
if [ $? -ne 0 ]
then
    echo "Download failed, please check!"
else
    echo "Done"
fi

$PERL $ANSWER_TIME
if [ $? -ne 0 ]
then
    echo "Error, execution of $ANSWER_TIME failed"         
    exit 1
fi
