#!/bin/sh

PERL="/usr/bin/perl"
CQPERL="/opt/rational/clearquest/bin/cqperl"
CQDIR="/home/eenzcha/clearquest"
EFFORT="$CQDIR/tr_effort.pl"
DATA="$CQDIR/91229839.xls"


INPUT=""
while getopts "d:ef:h" opt
  do
    case $opt in
      e)
        INPUT="$INPUT -effort $OPTARG"
        ;;
      f)
        INPUT="$INPUT -filename $OPTARG"
        ;;
      d)
        INPUT="$INPUT -date $OPTARG"
        ;;
      h)
	echo "Usage: `basename $0` -e effort per tr of all subsystem"
        echo "                    -d date range in which you want to query(input eg,'2012-09-01,2012-10-31')"
        echo "                    -f file name of time report(eg, 91229839_Oct.xls)"
        echo "                    -h help"
        #INPUT="$INPUT -help $OPTARG" 
        exit 0;
        ;;
      *)
	echo "Wrong option, exiting ..."
	exit 1
        ;;
     esac
  done


#echo $INPUT
$CQPERL $EFFORT $INPUT 
