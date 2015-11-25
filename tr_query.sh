#!/bin/sh

INPUT=""
while getopts "u:n:h" opt
  do
    case $opt in
      u)
        INPUT="$INPUT -user $OPTARG"
        ;;
      n)
        INPUT="$INPUT -no $OPTARG"
        ;;
      h)
	echo "Usage: `basename $0` -u user alias that you would like to query(eg, eenzcha)"
        echo "                  -n no of the TR you want to query(eg,'SGSN00056269', not functional yet)"
        echo "                  -h help"
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
/opt/rational/clearquest/bin/cqperl /home/eenzcha/clearquest/tr_query.pl $INPUT 
