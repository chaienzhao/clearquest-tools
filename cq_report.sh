#!/bin/sh

INPUT=""
while getopts "dpolcigstfh" opt
  do
    case $opt in
      s)
        INPUT="$INPUT -state $OPTARG"
        ;;
      d)
        INPUT="$INPUT -detail $OPTARG"
        ;;
      p)
        INPUT="$INPUT -product $OPTARG"
        ;;
      h)
	echo "Usage: `basename $0` -d details of alert/hot/blocker TRs"
        echo "                    -p details of alert/hot/blocker TRs, sorted by product, should be used with -d"
        echo "                    -o output TRs into a file, should use this option with -t or -f, but not both at the same time"
        echo "                    -t compare today(tuesday)'s query result with last tuesday, don't use this option with -f"
        echo "                    -f compare today(friday)'s query result with last friday, don't use this option with -t"
        echo "                    -l list inflow and outflow TRs"
        echo "                    -c customer TR status"
        echo "                    -i internal TR status"
        echo "                    -s state, TR state as Submitted,Assigned..."
        echo "                    -h help"
        #INPUT="$INPUT -help $OPTARG" 
        exit 0;
        ;;
      o)
        INPUT="$INPUT -output $OPTARG"
        ;;
      t)
        INPUT="$INPUT -tuesday $OPTARG"
        ;;
      f)
        INPUT="$INPUT -friday $OPTARG"
        ;;
      l)
        INPUT="$INPUT -list $OPTARG"
        ;;
      c)
        INPUT="$INPUT -customer $OPTARG"
        ;;
      i)
        INPUT="$INPUT -internal $OPTARG"
        ;;
      g)
        INPUT="$INPUT -gtt $OPTARG"
        ;;
      *)
	echo "Wrong option, exiting ..."
	exit 1
        ;;
     esac
  done


#echo $INPUT
/opt/rational/clearquest/bin/cqperl /home/eenzcha/clearquest/cq_report.pl $INPUT 
