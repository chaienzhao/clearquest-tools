#!/opt/rational/clearquest/bin/cqperl

###########################################################
## Script  : cq_report.pl
## Purpose : SGSN Trouble Report Statistic
## Author  : Joseph Chai(eenzcha)
## History : 2013-11-13 v0.1 eenzcha Initial requirements
##
##
###########################################################


use CQPerlExt;
use strict;
use Getopt::Long;
use POSIX;

# Global variables
$|= 1; # do not buffer output
my $sessionObj;
my $databases;
my @p_product=("Maintenance","Program","Total");
my @sub_systems=("EPS","EMS","UPS","MPS","MVS","XPS","MTS","GTS-U","GTS-C","CAS","CHS","TTx");
my @sub_and_ft=("EPS","EMS","UPS","MPS","MVS","XPS","MTS","GTS-U","GTS-C","CAS","CHS","TTx","FT","GTT","Total");
my @lfd=("15", "0", "9", "6", "0", "0", "3", "1", "1", "0", "0","1");
my @maint_systems=("MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx","XPS","EMS");
my @xft_systems_total=("Total","EPS", "UPS", "MPS","MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx","XPS","EMS");
my @combine_systems=("EPS","UPS","MPS","MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx","XPS","EMS");
my @gtt_systems=("EPS","UPS","MPS","MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx","XPS","EMS","GTT","Total");
my @gtt_sys=("EPS","UPS","MPS","MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx","XPS","EMS","GTT");
my $ccgm = "CAS|CHS|GTS-C|MVS|XPS|EMS";
my $mg   = "MTS|GTS-U";
my @group_systems = ("Total","EPS","UPS","MPS",$ccgm, $mg, "TTx");
my @sub_group_systems = ("Total",$ccgm, $mg);
my @states = ("Closed", "Followup");
my @status=("Submitted","Assigned", "Investigated", "Resolved", "Verified");
my @severity = ("Improvement");
my @null = ();
my @original=("Yes");
my @yes=("YES");
my @importance = ("86");
#my @control_team=("eqruaai", "ezhxinr", "ejigxig", "efeizen", "exioyin", "egugwuu", "eadghhk", "edifang","exruxxu","eehikmw","efhjkoc","esiyuwa","exuujiu");
my @control_team=("eqruaai", "ejigxig", "efeizen", "exioyin", "eadghhk", "edifang", "exinydo", "ejieyyi","ezhxinr");
my @payload_team=("elngliu", "erenyin", "esualli", "eyaozhu");
#Team Blue my @custom_team=("ervtpet", "etomaca", "ervlfjn");
my @custom_team=("exruxxu","eehikmw","efhjkoc","esiyuwa","exuujiu");

my $cq_dir = "/home/eenzcha/clearquest";
my $eng_file = "$cq_dir/engineers";
my $last_week;
my $curr_week;
my $last_tuesday;
my $curr_tuesday;
my %inflow;
my %outflow;
my %engineers;
my %weekly_tr;   # Customer TR
my %inter_tr;    # Internal TR
my %gtt_tr;      # GTT TR
my %blocker_tr;
my %hot_tr;
my %length;
my %blocker_length;
my %tr_state;
my %all_tr;
my %cp_team;
my %pl_team;
my %custom_team;

# flags
my $out=0;
my $tuesday=0;
my $friday=0;
my $list=0;
my $detail=0;
my $detail_by_product = 0;
my $customer_print = 0;
my $internal_print = 0;
my $state_print = 0;
my $gtt_print = 0;

# The whole table of SGSN product TR
my %product; 
my %maintenance;
my %hot;
my %xft;
my %gtt;
my @product_mme =("SGSN-MME");
#my @product_mme=("SGSN-MME 2010A","SGSN-MME 2010B","SGSN-MME 2011A","SGSN-MME 2011A FP02","SGSN-MME 2011B","SGSN-MME 2012A","SGSN-MME 13A","SGSN-MME 13B","SGSN-MME 14A","SGSN-MME 14B","SGSN-MME 15A");
my @product_gtt_ft=("GTT_LSV","FAST_LSV", "SimFAST_LSV");

# Selects a field to include in the query's search results
my @display_fields=("id", "headline");

my $sep  = "-" x 31;
my $sep2 = "=" x 31;

my $wy_ref = &get_week;
my($week_no, $year)=@{$wy_ref};
my $week_no_last = $week_no - 1;
my $year_last;
my $tue_str = "TUE";

$curr_week = "$cq_dir/w$year$week_no";
$curr_tuesday = "$cq_dir/w$year$week_no$tue_str";

# check if this is the first week
if($week_no_last eq 0){
 $year_last=$year-1;
 $week_no_last = 52;
 $last_week = "$cq_dir/w$year_last$week_no_last";
 $last_tuesday =  "$cq_dir/w$year_last$week_no_last$tue_str";
}else{
 $last_week = "$cq_dir/w$year$week_no_last";
 $last_tuesday = "$cq_dir/w$year$week_no_last$tue_str";
}

# get the no of week
sub get_week{
   my($sec,$min,$hour,$mday,$mon,$year_off,$wday,$yday,$isdst)=localtime(time);
   my $num = $yday + 1;
   my $result_str=strftime("%V", gmtime time);
#   if ($num % 7 == 0) {
#      $result = int($num / 7) + 1;
#   } else {
#      $result  = int($num / 7 + 1);
#   }
   my ($first_digit,$second_digit) = split(//,$result_str);
   my $result;
   if($first_digit == 0){
      $result = $second_digit;
   }else{
      $result = $result_str;
   }
   my $year = $year_off + 1900;
   my @result=($result, $year);
   return \@result;
}

sub get_week_range{
    my $NUM_DAY = 7;
    my $date_now = strftime "%F", localtime(time());
    my $date_from = strftime "%F", localtime(time()-(60*60*24*$NUM_DAY));
    my @week_range = ($date_from, $date_now);
    return \@week_range; 
}

# Get a list of accessible databases
# $databases = $sessionObj->GetAccessibleDatabases("MASTR", "eenzcha", "ggsnj20");
sub get_dbs{
  my($sessionObj,$master_db_name, $username, $db_set) =@_;
  my $dbs = $sessionObj->GetAccessibleDatabases($master_db_name, $username, $db_set);
  return $dbs;
}

sub get_db_count{
  my($dbs, $count)=@_;
  $count = $databases->Count();
  return $count;
}

# For each accessible database, login as joe with password gh36ak3
sub logon_db{
  my($sessionObj, $username, $passwd, $db_name, $db_set)=@_;
  $sessionObj->UserLogon($username, $passwd, $db_name, $db_set);
  if($? eq 0){
     #print "Successfully logon...\n";
     return $sessionObj;
  }else{
     die "Logon failed: $!\n";
  } 
}

sub build_query{
  my($sessionObj)=@_;

  my $querydef = $sessionObj->BuildQuery("defect");
  foreach my $field(@display_fields){
    $querydef->BuildField($field);
  }

  return $querydef;
}

# add filter get PRA Quality no of TRs
sub add_filter_PRA_quality{
  my($querydef, $sub_sys)=@_;

  my @ne_systems = ("GTT", "Tecsas");
  my @products = ("CGSN R4", "QuicLINK", "Rackserver with HW Equipped Magasine", "RS 2100 8-port E1/T1 (SPP) 
Equipped magazine", "RS 2100 Ethernet only (IP-MUX) Equipped Magazine", "RS 2100 Ethernet only (SPP) Equipped 
Magazine", "SGSN MME Demo", "SGSN Prod Test", "SGSN Test Tools", "SGSN_LLV", "Shade-SGSN Development 
Environment", "SimFAST_LSV", "SPP");
  my @target_sys= ();
  my @product_sgsn=("SGSN");
  
  # get the no of target sub_system
  push @target_sys, $sub_sys;

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  
  $operator->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_LIKE,\@product_sgsn);
  $operator->BuildFilter("foundInProduct", $CQPerlExt::CQ_COMP_OP_NOT_IN, \@products);
  $operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@target_sys);
  $operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_NEQ,\@ne_systems);
  $operator->BuildFilter("Duplicate_Of", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator->BuildFilter("isOriginal", $CQPerlExt::CQ_COMP_OP_EQ, \@original);
  $operator->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);
  $operator->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_NEQ, \@importance);
  $operator->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@status);

  # print "Add filter of PRA Quality no of TRs ...\n";

}

sub add_filter_short_lived_tr{
  my($querydef) = @_;
  my @status_short = ("Verified","Closed","FollowUp");
  my @product_sgsn=("SGSN");
  
  my $week_ref = get_week_range;
 
  my ($w_from, $today) =  @{$week_ref}[0, -1];
  print "\n====This is a temporay printout for slippery TRs====\n\n";
  print "Date from $w_from, until $today\n";

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator1 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);
  my $operator3 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);
  my $operator4 = $operator3->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

  # operator
  $operator->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ,\@status_short);
  $operator->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_LIKE,\@product_sgsn);
  $operator->BuildFilter("isOriginal", $CQPerlExt::CQ_COMP_OP_EQ, \@original);
  $operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ, \@sub_systems);

  $operator1->BuildFilter("SubmittedOn", $CQPerlExt::CQ_COMP_OP_BETWEEN,$week_ref);
  $operator1->BuildFilter("ForwardOn", $CQPerlExt::CQ_COMP_OP_BETWEEN,$week_ref);

  $operator3->BuildFilter("FollowUpOn", $CQPerlExt::CQ_COMP_OP_BETWEEN,$week_ref);
  
  $operator4->BuildFilter("Delivered", $CQPerlExt::CQ_COMP_OP_EQ,\@yes);
  $operator4->BuildFilter("VerifiedOn", $CQPerlExt::CQ_COMP_OP_BETWEEN,$week_ref);
  
}

sub compute_short_lived_tr{
  my($sessionObj, $querydef)=@_;

  my $resultset = $sessionObj->BuildResultSet($querydef);
  $resultset->EnableRecordCount();
  $resultset->Execute();
  my $count = $resultset->GetRecordCount();
  print "There are $count slippery TRs, check if they have already been counted in.\n"; 

  if(defined $resultset){
     while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
       my $id   = $resultset->GetColumnValue(1);
       my $entity  = $sessionObj->GetEntity("Defect", $id);
       my $headline = $entity->GetFieldValue("Headline")->GetValue();
       my $systemPart= $entity->GetFieldValue("systemPart")->GetValue();
       my $foundInProd= $entity->GetFieldValue("foundInProduct")->GetValue();
       my $importance= $entity->GetFieldValue("Importance")->GetValue();
       my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
       my $state= $entity->GetFieldValue("State")->GetValue();
       my $severity= $entity->GetFieldValue("Severity")->GetValue();
       my $overduedate= $entity->GetFieldValue("overdueDate")->GetValue();
       my $isoriginal= $entity->GetFieldValue("IsOriginal")->GetValue();
       my $mhsId = $entity->GetFieldValue("mhsId")->GetValue();
       my $delivered= $entity->GetFieldValue("Delivered")->GetValue();

       print "\n-------Here is the slippery TR:\n";
       print "$id, $systemPart, $assignedEng, $state, $severity\n";

      }
  } 

}

sub add_filter_blocker_all{
  my($querydef, $sub_sys)=@_;
  my @product_lsv=("SGSN_LSV");
  #my @products = ("FAST_13A", "GTT_LSV", "GTT-MME 13A", "GTT-MME 2012A", "SGSN-MME 13A", "SGSN-MME 13A - CPI", "SGSN-MME 13A - HW");
  my @products = ("FAST_15A", "GTT-MME 15A", "SGSN-MME 15A", "SGSN-MME 13A", "SGSN-MME 13B", "SGSN-MME 14A", "SGSN-MME 14B");
  my @system;
  my @importance=("20","30","31","32","33","34","35","36","37","38","39","95","98");

  push @system, $sub_sys;

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);
  my $operator1 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator2 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

  # operator1
  $operator1->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_IN,\@importance);
  $operator1->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ,\@status);
  $operator1->BuildFilter("Delivered", $CQPerlExt::CQ_COMP_OP_NEQ,\@yes);
  $operator1->BuildFilter("foundInProduct", $CQPerlExt::CQ_COMP_OP_IN,\@product_lsv);
  $operator1->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@system);
  $operator1->BuildFilter("Duplicate_Of", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  #$operator1->BuildFilter("Clone", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator1->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@system);
  #$operator1->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);

  # operator2
  $operator2->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_IN,\@importance);
  $operator2->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ,\@status);
  $operator2->BuildFilter("Delivered", $CQPerlExt::CQ_COMP_OP_NEQ,\@yes);
  $operator2->BuildFilter("foundInProduct", $CQPerlExt::CQ_COMP_OP_IN,\@products);
  $operator2->BuildFilter("Duplicate_Of", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator2->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@system);
  #$operator2->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);

}


sub add_filter_hot{
  my($querydef, $ref, $sub_sys)=@_;
  my @product=@{$ref};
  #my @product=("SGSN-MME");
  my @ne_products=("CGSN R4","GTT-MME 2009B RP01","GTT-MME 2009B RP02","QuicLINK","Rackserver with HW Equipped Magasine","RS 2100 8-port E1/T1 (SPP) Equipped magazine","RS 2100 Ethernet only (IP-MUX) Equipped Magazine","RS 2100 Ethernet only (SPP) Equipped Magazine","SGSN 2008B","SGSN 2009B","SGSN MME Demo","SGSN Prod Test","SGSN R6 FP00","SGSN R6 FP01","SGSN R7 FP00","SGSN R7 FP01,SGSN R8","SGSN Test Tools","SGSN_LLV","SGSN-MME 2009B RP01","SGSN-MME 2009B RP02","Shade - SGSN Development Environment","SPP");
  my @system= ();
  my @tecsas=("Tecsas");
  push @system, $sub_sys;
  my @maint_importance=(10,11,12,13,14,15,16,17,18,19,2,20,21,22,23,24,25,26,27,28,29,3,30,31,32,33,34,35,36,37,38,39,98);
  my @hot_importance=(10,11,12,13,14,15,16,17,18,19,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59);

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator1 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);
  my $operator2 = $operator1->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator3 = $operator1->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
 
  $operator->BuildFilter("Delivered", $CQPerlExt::CQ_COMP_OP_NEQ,\@yes);
  $operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@system);
  $operator->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_EQ,\@hot_importance);

  $operator2->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_NEQ,\@tecsas);
  $operator2->BuildFilter("clonedFrom", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator2->BuildFilter("Duplicate_Of", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator2->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);
  $operator2->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_NEQ, \@importance);
  $operator2->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@status);
  $operator2->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_NOT_IN,\@ne_products);
  $operator2->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_LIKE,\@product);

  $operator3->BuildFilter("Duplicate_Of", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator3->BuildFilter("clonedFrom", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@null);
  $operator3->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_EQ, \@maint_importance);
  $operator3->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_NOT_IN,\@ne_products);
  $operator3->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_LIKE,\@product);
  $operator3->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_NEQ,\@tecsas);
  $operator3->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_IN, \@status);
  $operator3->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_NEQ, \@importance);
  $operator3->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);

}


sub add_filter_gtt_ft{
  my($querydef, $ref)=@_;
  my @product=@{$ref};
  #my @system= ();
  #push @system, $sub_sys;

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

  $operator->BuildFilter("Delivered", $CQPerlExt::CQ_COMP_OP_NEQ,\@yes);  
  #$operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@system);
  $operator->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_IN,\@product);
  $operator->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@status);
  #$operator->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_NEQ, \@importance);
  #$operator->BuildFilter("Severity", $CQPerlExt::CQ_COMP_OP_NEQ, \@severity);

}

$product{Total}{'Blocker'} = 0;

sub compute_blocker{
  my($sessionObj, $querydef, $sub_sys)=@_;
  my $resultset = $sessionObj->BuildResultSet($querydef);
  my $count;

  $resultset->EnableRecordCount();
  $resultset->Execute();
  $count = $resultset->GetRecordCount();
  #print "$sub_sys:\t$count\n";
  $product{$sub_sys}{'Blocker'} = $count;
$product{Total}{'Blocker'} += $product{$sub_sys}{'Blocker'};
  if(defined $resultset){
       while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
           my $id   = $resultset->GetColumnValue(1);
           my $entity  = $sessionObj->GetEntity("Defect", $id);
           my $headline = $entity->GetFieldValue("Headline")->GetValue();
           my $systemPart= $entity->GetFieldValue("systemPart")->GetValue();
           my $foundInProd= $entity->GetFieldValue("foundInProduct")->GetValue();
           my $importance= $entity->GetFieldValue("Importance")->GetValue();
           my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
           my $state= $entity->GetFieldValue("State")->GetValue();
           # my @temp = ($id,$systemPart,$importance,$state,$assignedEng,$foundInProd,$headline);
           # $blocker_tr{$id}=\@temp;
           if($detail_by_product){
               my @temp = ($id,$foundInProd,$importance,$state,$assignedEng,$systemPart,$headline);
               $blocker_tr{$id} = \@temp;
               push @{$hot_tr{$foundInProd}},\@temp;
           }else{
               my @temp = ($id,$systemPart,$importance,$state,$assignedEng,$foundInProd,$headline);
               $blocker_tr{$id} = \@temp;
               push @{$hot_tr{$systemPart}},\@temp;
           }
       }
  }else{
       print "ResultSet is undef\n";
  }
} 

for my $g_sys(@group_systems){
    $maintenance{$g_sys}{'A'} = 0;
    $maintenance{$g_sys}{'B'} = 0;
    $maintenance{$g_sys}{'C'} = 0;
    $maintenance{$g_sys}{'Backlog'} = 0;
}

sub get_customer_tr{
      foreach my $id(keys%weekly_tr){
           my($id,$systemPart,$state, $severity) = @{$weekly_tr{$id}}[0,2,6,7];
           $maintenance{$systemPart}{'Open'} += 1;

           if($systemPart =~ /$ccgm/){
              if($severity =~ /A/){
                 $maintenance{$ccgm}{'A'} += 1;                
              }
              if($severity =~ /B/){
                 $maintenance{$ccgm}{'B'} += 1;                

              }
              if($severity =~ /C/){
                 $maintenance{$ccgm}{'C'} += 1;                

              }
              if($state =~ /Submitted/){
                 $maintenance{$ccgm}{'Backlog'} += 1;
                 $maintenance{'Total'}{'Backlog'} += 1;
              }
           }
           if($systemPart =~ /$mg/){
              if($severity =~ /A/){
                 $maintenance{$mg}{'A'} += 1;                

              }
              if($severity =~ /B/){
                 $maintenance{$mg}{'B'} += 1;                

              }
              if($severity =~ /C/){
                 $maintenance{$mg}{'C'} += 1;                

              }
              if($state =~ /Submitted/){
                 $maintenance{$mg}{'Backlog'} += 1;
                 $maintenance{'Total'}{'Backlog'} += 1;
              }
           }else{
              if($severity =~ /A/){
                 $maintenance{$systemPart}{'A'} += 1;                

              }
              if($severity =~ /B/){
                 $maintenance{$systemPart}{'B'} += 1;                

              }
              if($severity =~ /C/){
                 $maintenance{$systemPart}{'C'} += 1;                

              }
              if($state =~ /Submitted/){
                 $maintenance{$systemPart}{'Backlog'} += 1;
                 $maintenance{'Total'}{'Backlog'} += 1;
              }
           }
      }
      foreach my $c_sys(@group_systems){
           if(!defined($maintenance{$c_sys}{'Open'})){
                  $maintenance{$c_sys}{'Open'} = 0;
           }
      }

}


sub compute_hot{
  my($sessionObj, $querydef, $sub_sys)=@_;
  my $resultset = $sessionObj->BuildResultSet($querydef);
  my $count;

  $resultset->EnableRecordCount();
  $resultset->Execute();
  $count = $resultset->GetRecordCount();
#print "$sub_sys, $count\n";
  $maintenance{$sub_sys}{'Hot'} = $count;

  if(defined $resultset){
       while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
           my $id   = $resultset->GetColumnValue(1);
           my $entity  = $sessionObj->GetEntity("Defect", $id);
           my $headline = $entity->GetFieldValue("Headline")->GetValue();
           my $systemPart= $entity->GetFieldValue("systemPart")->GetValue();
           my $foundInProd= $entity->GetFieldValue("foundInProduct")->GetValue();
           my $importance= $entity->GetFieldValue("Importance")->GetValue();
           my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
           my $state= $entity->GetFieldValue("State")->GetValue();
           # my @temp = ($id,$systemPart,$importance,$state,$assignedEng,$foundInProd,$headline);
           # $blocker_tr{$id}=\@temp;
           # push @{$blocker_tr{$systemPart}},\@temp;
           if($detail_by_product){
               my @temp = ($id,$foundInProd,$importance,$state,$assignedEng,$systemPart,$headline);
               push @{$hot_tr{$foundInProd}},\@temp;
           }else{
               my @temp = ($id,$systemPart,$importance,$state,$assignedEng,$foundInProd,$headline);
               push @{$hot_tr{$systemPart}},\@temp;
           }
       }
  }else{
       print "ResultSet is undef\n";
  }

}

sub get_internal_tr{
  $xft{Total}{'Backlog'}=0;
  $xft{Total}{'Open'} = 0;
  $xft{Total}{'Inflow'} = 0;
  $xft{Total}{'Outflow'} = 0;
  $xft{Total}{'Blocker'} = 0;
  $xft{Total}{'Non-blocker'} = 0;

  foreach my $s(@combine_systems){
      $xft{$s}{'Open'} = 0;
      $xft{$s}{'Backlog'}= 0;
      $xft{$s}{'Blocker'} = 0;
      $xft{$s}{'Non-blocker'} = 0;
  }
  foreach my $id(keys%inter_tr){
        my ($systemPart,$state) = @{$inter_tr{$id}}[2,6];
               
        $xft{$systemPart}{'Open'} += 1;
        if($state =~ /Submitted/){
           $xft{$systemPart}{'Backlog'} += 1;
        }
        if(exists $blocker_tr{$id}){
           $xft{$systemPart}{'Blocker'} +=1;
        }else{
           $xft{$systemPart}{'Non-blocker'} +=1;
        }
        
  }

  foreach my $sub_sys(@combine_systems){
     $xft{Total}{'Backlog'}+=$xft{$sub_sys}{'Backlog'};
     $xft{Total}{'Open'} += $xft{$sub_sys}{'Open'};
     $xft{Total}{'Blocker'} += $xft{$sub_sys}{'Blocker'};
     $xft{Total}{'Non-blocker'} += $xft{$sub_sys}{'Non-blocker'};
  }
}

sub get_gtt_tr{
  foreach my $s(@gtt_systems){
      $gtt{$s}{'Open'} = 0;
      $gtt{$s}{'Backlog'}= 0;
      $gtt{$s}{'Inflow'} = 0;
      $gtt{$s}{'Outflow'} = 0;
  }
  foreach my $id(keys%gtt_tr){
        my ($systemPart,$state) = @{$gtt_tr{$id}}[2,6];
    
        $gtt{$systemPart}{'Open'} += 1;
        if($state =~ /Submitted/){
           $gtt{$systemPart}{'Backlog'} += 1;
        }
    
  }

  foreach my $sub_sys(@gtt_sys){
     $gtt{Total}{'Backlog'}+=$gtt{$sub_sys}{'Backlog'};
     $gtt{Total}{'Open'} += $gtt{$sub_sys}{'Open'};
  }
}

foreach(@status){
   $tr_state{'Maintenance'}{$_}=0;
   $tr_state{'Program'}{$_}=0;
}
foreach(@p_product){
   $tr_state{$_}{'InTotal'}=0;
}

sub get_state{
   my($product, $state)=@_;
   if($state =~ /Submitted/){
     $tr_state{$product}{'Submitted'} +=1;
   } 
   if($state =~ /Assigned/){
     $tr_state{$product}{'Assigned'} +=1;
   } 
   if($state =~ /Investigated/){
     $tr_state{$product}{'Investigated'} +=1;
   } 
   if($state =~ /Resolved/){
     $tr_state{$product}{'Resolved'} +=1;
   } 
   if($state =~ /Verified/){
     $tr_state{$product}{'Verified'} +=1;
   } 


}

$product{Total}{'Program'} = 0;
$product{Total}{'Maintenance'} = 0;
$product{Total}{'InTotal'} = 0;
$product{Total}{'Open'} = 0;

sub compute_PRA_quality{
  my($sessionObj, $querydef, $sub_sys)=@_;
  my($no_lsv, $no_maint, $not_deliver) = (0, 0, 0) ;

  my $resultset = $sessionObj->BuildResultSet($querydef);
  $resultset->EnableRecordCount();
  $resultset->Execute();
  my $count = $resultset->GetRecordCount();

  $product{$sub_sys}{'Open'}=$count;
  $product{Total}{'Open'} +=$product{$sub_sys}{'Open'};
  
  if(defined $resultset){
     while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
       my $id   = $resultset->GetColumnValue(1);
       my $entity  = $sessionObj->GetEntity("Defect", $id);
       my $headline = $entity->GetFieldValue("Headline")->GetValue();
       my $systemPart= $entity->GetFieldValue("systemPart")->GetValue();
       my $foundInProd= $entity->GetFieldValue("foundInProduct")->GetValue();
       my $importance= $entity->GetFieldValue("Importance")->GetValue();
       my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
       my $state= $entity->GetFieldValue("State")->GetValue();
       my $severity= $entity->GetFieldValue("Severity")->GetValue();
       my $overduedate= $entity->GetFieldValue("overdueDate")->GetValue();
       my $isoriginal= $entity->GetFieldValue("IsOriginal")->GetValue();
       my $mhsId = $entity->GetFieldValue("mhsId")->GetValue();
       my $delivered= $entity->GetFieldValue("Delivered")->GetValue();
       my $subm_team= $entity->GetFieldValue("submittedByProjectOrTeam")->GetValue();
       my @temp = ($id,$headline,$systemPart,$foundInProd,$importance,$assignedEng,$state,$severity,$overduedate,$isoriginal,$mhsId,$delivered,$subm_team);

       if($mhsId =~ /\d+/){
          if($state !~ /Verified/){
             $no_maint++;
          }
          if($delivered !~ /YES/){
              get_state("Maintenance",$state);
              $not_deliver++;
              $weekly_tr{$id}=\@temp;
              $all_tr{$id} = \@temp;
          }
       }else{
          if($state !~ /Verified/){
             $no_lsv++;
          }
          if($delivered !~ /YES/){
             get_state("Program",$state);
             $not_deliver++;
             $inter_tr{$id} = \@temp;
             $all_tr{$id} = \@temp;
          }
       }
       #if($sub_sys =~ /UPS/){
       #   print "PRA-----------------$id, $state, $foundInProd, $subm_team\n";
       #}
     }

     foreach(@status){
        $tr_state{'Total'}{$_}=$tr_state{'Program'}{$_} + $tr_state{'Maintenance'}{$_};
     }
     
     $product{$sub_sys}{'Program'} = $no_lsv;
     $product{$sub_sys}{'Maintenance'} = $no_maint;
     $product{$sub_sys}{'InTotal'} = $no_lsv + $no_maint;
     $product{$sub_sys}{'TotalNotDeliver'} = $not_deliver;

  }else{
     $product{$sub_sys}{'Program'} = $no_lsv;
     $product{$sub_sys}{'Maintenance'} = $no_maint;
     $product{$sub_sys}{'InTotal'} = 0;
     $product{$sub_sys}{'TotalNotDeliver'} = 0;
  }

  $product{Total}{'Program'} += $product{$sub_sys}{'Program'};
  $product{Total}{'Maintenance'} += $product{$sub_sys}{'Maintenance'};
  $product{Total}{'InTotal'} += $product{$sub_sys}{'InTotal'};
  $product{Total}{'TotalNotDeliver'} += $product{$sub_sys}{'TotalNotDeliver'};

}


sub compute_gtt_ft{
  my($sessionObj, $querydef)=@_;
  my($ft,$ft_lfd, $ft_no_maint, $ft_no_lsv, $ft_not_deliver, $ft_open) = ("FT", 5, "-", 0, 0, 0);
  my($gtt,$gtt_lfd, $gtt_no_maint, $gtt_no_lsv, $gtt_not_deliver, $gtt_open) = ("GTT", "-", "-", 0, 0, 0);

  my $resultset = $sessionObj->BuildResultSet($querydef);
  $resultset->EnableRecordCount();
  $resultset->Execute();

  #my $count = $resultset->GetRecordCount();
  #$product{$ft}{'Open'}=$count;

  if(defined $resultset){
     while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
       my $id   = $resultset->GetColumnValue(1);
       my $entity  = $sessionObj->GetEntity("Defect", $id);
       my $headline = $entity->GetFieldValue("Headline")->GetValue();
       my $systemPart= $entity->GetFieldValue("systemPart")->GetValue();
       my $foundInProd= $entity->GetFieldValue("foundInProduct")->GetValue();
       my $importance= $entity->GetFieldValue("Importance")->GetValue();
       my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
       my $state= $entity->GetFieldValue("State")->GetValue();
       my $severity= $entity->GetFieldValue("Severity")->GetValue();
       my $overduedate= $entity->GetFieldValue("overdueDate")->GetValue();
       my $isoriginal= $entity->GetFieldValue("IsOriginal")->GetValue();
       my $mhsId = $entity->GetFieldValue("mhsId")->GetValue();
       my $delivered= $entity->GetFieldValue("Delivered")->GetValue();
       my @temp = ($id,$headline,$systemPart,$foundInProd,$importance,$assignedEng,$state,$severity,$overduedate,$isoriginal,$mhsId,$delivered);


       if($foundInProd =~ /FAST_LSV/ || ($foundInProd =~ /SimFAST_LSV/)){
          $ft_open++;
          if($state !~ /Verified/){
            $ft_no_lsv++;
          }
          if($delivered !~ /YES/){
            $ft_not_deliver++;
            $all_tr{$id} = \@temp;
          }
       }
       if($foundInProd =~ /GTT_LSV/){
          $gtt_open++;
          if($state !~ /Verified/){
            $gtt_no_lsv++;
          }
          if($delivered !~ /YES/){ 
            $gtt_not_deliver++;
            $gtt_tr{$id} = \@temp;
            $all_tr{$id} = \@temp;
          }   

       }

       #print "$id, $state,$systemPart, $foundInProd\n";
     }

     $product{$ft}{'Program'} = $ft_no_lsv;
     $product{$ft}{'Maintenance'} = $ft_no_maint;
     $product{$ft}{'InTotal'} = $ft_no_lsv;
     $product{$ft}{'TotalNotDeliver'} = $ft_not_deliver;
     $product{$ft}{'Open'}=$ft_open;

     $product{$gtt}{'Program'} = $gtt_no_lsv;
     $product{$gtt}{'Maintenance'} = $gtt_no_maint;
     $product{$gtt}{'InTotal'} = $gtt_no_lsv;
     $product{$gtt}{'TotalNotDeliver'} = $gtt_not_deliver;
     $product{$gtt}{'Open'}=$gtt_open;

  }else{
     $product{$ft}{'Program'} = $ft_no_lsv;
     $product{$ft}{'Maintenance'} = $ft_no_maint;
     $product{$ft}{'InTotal'} = 0;
     $product{$ft}{'TotalNotDeliver'} = $ft_not_deliver;
     $product{$gtt}{'Program'} = $gtt_no_lsv;
     $product{$gtt}{'Maintenance'} = $gtt_no_maint;
     $product{$gtt}{'InTotal'} = 0;
     $product{$gtt}{'TotalNotDeliver'} = $gtt_not_deliver;
  }

  $product{$ft}{'Blocker'}=0;
  $product{$ft}{'LFD'} = $ft_lfd;
  $product{$gtt}{'Blocker'}=0;
  $product{$gtt}{'LFD'} = $gtt_lfd;

}

# Read XIP/D engineers' alias into a hash
sub get_engineer{
   my $eng_count=0;
   open(FH, "< $eng_file") or die("can not open file $eng_file: $!\n");
   while(<FH>){
     chomp;
     if($_ =~ /^\w+/){
        $engineers{$_} =++$eng_count;
     }
   }
   close FH;

}

sub get_length{
  my($show_rf) = @_;
  foreach my $show_arry_ref(@{$show_rf}){
     foreach my $show(@{$show_arry_ref}){
        my $show_space = "$show  ";
        my $length = length($show_space);
        $length{$show} = $length if(! $length{$show});

     }
  }
}

sub maxLength{
    my($X,$ref)=@_;
    my $length=length("$X ");
    $blocker_length{$ref}=length("$ref ") if (!$blocker_length{$ref});
    $blocker_length{$ref}=$length if ($blocker_length{$ref} < $length);
}


# These variables used for display in
my $product_title="SGSN-MME Product TR Status";
my $maint_title="Customer TR Overall Status";
my $xft_title="Internal TR Overall Status";
my $gtt_title="GTT TR Overall Status";
my $state_title="TR State";

sub print_header{
  my($type, $show) = @_;
  my $header ="";
  foreach my $show(@{$show}){
     my $length = length($show);
     $header .= sprintf("%-${length}s | ", $show); 
  } 
  my $bar= "-" x length($header);
  if($type =~ /product/){
     print "\n$product_title\n$bar\n$header\n$bar\n";
  }elsif($type =~ /xft/){
     print "\n$xft_title\n$bar\n$header\n$bar\n";
  }elsif($type =~ /maintenance/){
     print "\n$maint_title\n$bar\n$header\n$bar\n";
  }elsif($type =~ /state/){
     print "\n$state_title\n$bar\n$header\n$bar\n";
  }elsif($type =~ /gtt/){
     print "\n$gtt_title\n$bar\n$header\n$bar\n";
  }
}

sub usage{
 print "This script is used for generate TR status report\n";
 exit 0;
}

sub set_output{
 $out = 1;
}
sub set_tuesday{
 $tuesday = 1;
}
sub set_friday{
 $friday = 1;
}

sub set_list{
 $list = 1;
}

sub set_detail{
 $detail = 1;
}
sub set_detail_by_product{
 $detail_by_product = 1;
}
sub set_customer_print{
 $customer_print = 1;
}
sub set_internal_print{
 $internal_print = 1;
}
sub set_gtt_print{
 $gtt_print = 1;
}
sub set_state_print{
 $state_print = 1;
}
####################
##      main      ##
####################
my $res=GetOptions('detail'       => \&set_detail,
                   'product'      => \&set_detail_by_product,
                   'output'       => \&set_output,
                   'tuesday'       => \&set_tuesday,
                   'friday'       => \&set_friday,
                   'list'         => \&set_list,
                   'customer'     => \&set_customer_print,
                   'internal'     => \&set_internal_print,
                   'gtt'          => \&set_gtt_print,
                   'state'        => \&set_state_print,
                   'help'         => \&usage,
                  );

# Start a Rational ClearQuest session
$sessionObj = CQSession::Build();

# Logon
$sessionObj = logon_db($sessionObj, "eenzcha", "eenzcha", "SGSN", "ggsnj20");

# print "Generating, this may take almost one minute, please wait ...\n";
print "Generating report, please wait ...\n";

# SGSN-MME Product TR status 

my $loop=0;
foreach my $sub_sys(@sub_systems){
    my $querydef=build_query($sessionObj);
    add_filter_PRA_quality($querydef, $sub_sys);
    compute_PRA_quality($sessionObj, $querydef, $sub_sys);
    $product{$sub_sys}{"LFD"}=$lfd[$loop];
    $loop++;
    $product{Total}{"LFD"} +=$product{$sub_sys}{"LFD"};
}

foreach my $sub_sys(@sub_systems){
    my $querydef=build_query($sessionObj);
    add_filter_blocker_all($querydef, $sub_sys);
    compute_blocker($sessionObj, $querydef, $sub_sys);

}

# Customer TR
get_customer_tr;

# Alert/Hot TR
foreach my $sub_sys(@combine_systems){
   my $querydef=build_query($sessionObj);
   add_filter_hot($querydef, \@product_mme, $sub_sys);
   compute_hot($sessionObj, $querydef, $sub_sys);
}

# Internal TR
get_internal_tr;

# add filter to get the GTT_LSV, FAST_LSV and SimFAST_LSV TR
#foreach my $sys(@sub_systems){
   my $querydef_ft=build_query($sessionObj);
   add_filter_gtt_ft($querydef_ft, \@product_gtt_ft);
   compute_gtt_ft($sessionObj, $querydef_ft);
#}
#GTT TR
get_gtt_tr;

# Unbuild the session
#
# For some improvement, don't unbuild the session right now, keep it for future use
#
#
# CQSession::Unbuild($sessionObj);

my $querydef_short = build_query($sessionObj);
add_filter_short_lived_tr($querydef_short);
compute_short_lived_tr($sessionObj, $querydef_short);

# Compute inflow or outflow

# Read TRs of last week into a hash
my @tr_last;
my %tr_last;

if($friday){
    open(FH, "< $last_week") or die("can not open file $last_week:$!\n");
    while(<FH>){
     my @temp = (split(/\|/, $_))[0, 2, 3, 5,10];
     #my($id, $systemPart, $foundInProduct, $assignedEng, $mhsId)=(split(/\|/, $_))[0, 2, 3, 5, 10];
     push @tr_last, $temp[0];
     $tr_last{$temp[0]} = \@temp;
    }
    close FH;
}
if($tuesday){
    open(FH, "< $last_tuesday") or die("can not open file $last_tuesday:$!\n");
    while(<FH>){
     my @temp = (split(/\|/, $_))[0, 2, 3, 5,10];
     #my($id, $systemPart, $foundInProduct, $assignedEng, $mhsId)=(split(/\|/, $_))[0, 2, 3, 5, 10];
     push @tr_last, $temp[0];
     $tr_last{$temp[0]} = \@temp;
    }
    close FH;

}

sub get_info_from_closed_tr{
    my($id) = @_;
    my $entity  = $sessionObj->GetEntity("Defect", $id);
    my $assignedEng = $entity->GetFieldValue("assignedEngineer")->GetValue();
    return $assignedEng;
}

sub ioflow_by_state{
   foreach("Inflow","Outflow"){
         $tr_state{'Maintenance'}{$_} = 0;
         $tr_state{'Program'}{$_} = 0;
         $tr_state{'Application'}{$_} = 0;
         $tr_state{'Payload'}{$_} = 0;
         $tr_state{'Custom'}{$_} = 0;
         $tr_state{'Other'}{$_} = 0;
   }
   foreach my $id(keys%all_tr){
       if(!exists $tr_last{$id}){
          my ($product,$assignedEng, $mhsId)=@{$all_tr{$id}}[3,5,10];
#print "ioflow_by_state:$id   $assignedEng  $mhsId\n";
        if(($product =~ /SGSN-MME/) || ($product =~ /SGSN_LSV/)){
          if($mhsId =~ /\d+/){
             $tr_state{'Maintenance'}{'Inflow'} +=1;
          }else{
             $tr_state{'Program'}{'Inflow'} +=1;
          }

          if(exists $cp_team{$assignedEng}){
             $tr_state{'Application'}{'Inflow'} += 1;
#print "Inflow:application: $id\n";
          }elsif(exists $pl_team{$assignedEng}){
             $tr_state{'Payload'}{'Inflow'} += 1;
#print "Inflow:application: $id\n";

          }elsif(exists $custom_team{$assignedEng}){
             $tr_state{'Custom'}{'Inflow'} += 1;

          }else{
             $tr_state{'Other'}{'Inflow'} += 1;

          }
        }
       }

   }
   foreach my $i(keys%tr_last){
       if(!exists $all_tr{$i}){
          my ($product, $assignedEng,$mhsId)=@{$tr_last{$i}}[2,3,-1];
#print "tr  last : $mhsId\n";
         if(($product =~ /SGSN-MME/) || ($product =~ /SGSN_LSV/)){
          if($mhsId =~ /\d+/){
#print "TR state outflow: $i\n";
             $tr_state{'Maintenance'}{'Outflow'} +=1;
          }else{
             $tr_state{'Program'}{'Outflow'} +=1;
          }
          if($assignedEng !~ /\w+/){
#print "hello       --------------------$i\n";
             $assignedEng = get_info_from_closed_tr($i);
             my($id, $systemPart, $foundInProduct, $assignedEngOld, $mhsId)  = @{$tr_last{$i}};
             my @tmp = ($id, $systemPart, $foundInProduct, $assignedEng, $mhsId);
             $tr_last{$i} = \@tmp; 
          }
          if(exists $cp_team{$assignedEng}){
             $tr_state{'Application'}{'Outflow'} += 1;
          }elsif(exists $pl_team{$assignedEng}){
             $tr_state{'Payload'}{'Outflow'} += 1;

          }elsif(exists $custom_team{$assignedEng}){
             $tr_state{'Custom'}{'Outflow'} += 1;

          }else{
             $tr_state{'Other'}{'Outflow'} += 1;

          }
         }
       }
   }

}

sub team_by_state{
   foreach my $s(@status){
      if($s =~ /Submitted/){
          $tr_state{'Application'}{$s} = "-";
          $tr_state{'Payload'}{$s} = "-";
          $tr_state{'Custom'}{$s} = "-";
          $tr_state{'Other'}{$s} = "-";

      }else{
          $tr_state{'Application'}{$s} = 0;
          $tr_state{'Payload'}{$s} = 0;
          $tr_state{'Custom'}{$s} = 0;
          $tr_state{'Other'}{$s} = 0;
      }
   }
   foreach my $id(keys%all_tr){
     my($product,$assignedEng, $state, $delivered) = @{$all_tr{$id}}[3,5,6,-1];
     if(($product =~ /SGSN-MME/) || ($product =~ /SGSN_LSV/)){
       if(exists $cp_team{$assignedEng}){
            if($state =~ /Assigned/){
                $tr_state{'Application'}{'Assigned'} += 1;

            }
            if($state =~ /Investigated/){
                $tr_state{'Application'}{'Investigated'} += 1;

            }
            if($state =~ /Resolved/){
                $tr_state{'Application'}{'Resolved'} += 1;

            }
            if($state =~ /Verified/){
                if($delivered !~ /YES/){
#print "Verified----$id, $state, $assignedEng\n";
                   $tr_state{'Application'}{'Verified'} += 1;
                }

            }
       }elsif(exists $pl_team{$assignedEng}){
            if($state =~ /Assigned/){
                $tr_state{'Payload'}{'Assigned'} += 1;

            }
            if($state =~ /Investigated/){
                $tr_state{'Payload'}{'Investigated'} += 1;

            }
            if($state =~ /Resolved/){
                $tr_state{'Payload'}{'Resolved'} += 1;

            }
            if($state =~ /Verified/){
                if($delivered !~ /YES/){
                   $tr_state{'Payload'}{'Verified'} += 1;
                }
            }

       }elsif(exists $custom_team{$assignedEng}){
            if($state =~ /Assigned/){
                $tr_state{'Custom'}{'Assigned'} += 1;

            }
            if($state =~ /Investigated/){
                $tr_state{'Custom'}{'Investigated'} += 1;

            }
            if($state =~ /Resolved/){
                $tr_state{'Custom'}{'Resolved'} += 1;

            }
            if($state =~ /Verified/){
                if($delivered !~ /YES/){
                   $tr_state{'Custom'}{'Verified'} += 1;
                }
            }

       }else{
            if($state =~ /Assigned/){
                $tr_state{'Other'}{'Assigned'} += 1;

            }
            if($state =~ /Investigated/){
                $tr_state{'Other'}{'Investigated'} += 1;

            }
            if($state =~ /Resolved/){
                $tr_state{'Other'}{'Resolved'} += 1;

            }
            if($state =~ /Verified/){
                if($delivered !~ /YES/){
                   $tr_state{'Other'}{'Verified'} += 1;
                }
            }

       }
      }
       
   }
   foreach("Assigned","Investigated","Resolved","Verified"){
       $tr_state{'Application'}{'InTotal'} += $tr_state{'Application'}{$_};
       $tr_state{'Payload'}{'InTotal'} += $tr_state{'Payload'}{$_};
       $tr_state{'Custom'}{'InTotal'} += $tr_state{'Custom'}{$_};
       $tr_state{'Other'}{'InTotal'} += $tr_state{'Other'}{$_};
   }   

}

sub ioflow_in_customer_tr{
   foreach my $id(keys%weekly_tr){
        if(!exists $tr_last{$id}){
            my($systemPart,$product,$assignedEng,$submitted_team) = @{$weekly_tr{$id}}[2,3,5,-1];
            if(($product =~ /SGSN-MME/) || ($product =~ /SGSN_LSV/)){             
               my @tmp=($id,$assignedEng,$submitted_team);
               push @{$inflow{$systemPart}{'Maintenance'}}, \@tmp;
            }
        }
   }
   foreach my $sub_sys(@combine_systems){
     if(exists $inflow{$sub_sys}){
        if(defined $inflow{$sub_sys}{'Maintenance'}){
           $maintenance{$sub_sys}{'Inflow'}= $maintenance{$sub_sys}{'Inflow'} + scalar(@{$inflow{$sub_sys}{'Maintenance'}});
        }else{
           $maintenance{$sub_sys}{'Inflow'} = 0;
        }
     }else{
        $maintenance{$sub_sys}{'Inflow'} = 0;
     }

   }
   
   foreach my $id(keys%tr_last){
        if(!exists $weekly_tr{$id}){
            my($systemPart,$product,$assignedEng,$mhsId) = @{$tr_last{$id}}[1,2,3,-1];
          if(($product =~ /SGSN-MME/) || ($product=~/SGSN_LSV/)){
            if($mhsId !~ /\d+/){
                  next;
            }else{            
                  my @tmp=($id,$assignedEng);
# print "Customer outflow: $id, $systemPart, $assignedEng\n";
                  push @{$outflow{$systemPart}{'Maintenance'}}, \@tmp;
            }
          }
        }
   }

   foreach my $sub_sys(@combine_systems){
     if(exists $outflow{$sub_sys}){
        if(defined $outflow{$sub_sys}{'Maintenance'}){
           $maintenance{$sub_sys}{'Outflow'} = $maintenance{$sub_sys}{'Outflow'} + scalar(@{$outflow{$sub_sys}{'Maintenance'}});
        }else{
           $maintenance{$sub_sys}{'Outflow'} = 0;
        }
     }else{
        $maintenance{$sub_sys}{'Outflow'} = 0;
     }

   }

}

sub ioflow_in_internal_tr{
   foreach my $id(keys%inter_tr){
       if(!exists $tr_last{$id}){
            my($systemPart,$product,$assignedEng,$submitted_team) = @{$inter_tr{$id}}[2,3,5,-1];
            if(($product =~ /SGSN-MME/) || ($product=~/SGSN_LSV/)){
              my @tmp=($id,$assignedEng,$product, $submitted_team);
              push @{$inflow{$systemPart}{'LSV'}}, \@tmp;
            }
        }
   }

   foreach my $sub_sys(@combine_systems){
      if(exists $inflow{$sub_sys}{'LSV'}){
          $xft{$sub_sys}{'Inflow'} = $xft{$sub_sys}{'Inflow'} + scalar(@{$inflow{$sub_sys}{'LSV'}});
      }
      if(!defined $xft{$sub_sys}{'Inflow'}){
         $xft{$sub_sys}{'Inflow'} = 0;
      }
      $xft{Total}{'Inflow'} += $xft{$sub_sys}{'Inflow'};
   }
 
   foreach my $id(keys%tr_last){
        if(!exists $inter_tr{$id}){
            my($systemPart,$product,$assignedEng,$mhsId) = @{$tr_last{$id}}[1,2,3,-1];
         if(($product =~ /SGSN-MME/) || ($product=~/SGSN_LSV/)){
            if($mhsId =~ /\d+/){
                next;
            }else{
                my @tmp=($id,$assignedEng);
                push @{$outflow{$systemPart}{'LSV'}}, \@tmp;
            }
         }
        }
   }
   foreach my $sub_sys(@combine_systems){
      if(exists $outflow{$sub_sys}{'LSV'}){
         $xft{$sub_sys}{'Outflow'} =  $xft{$sub_sys}{'Outflow'} + scalar(@{$outflow{$sub_sys}{'LSV'}});
      }
      if(!defined $xft{$sub_sys}{'Outflow'}){
         $xft{$sub_sys}{'Outflow'} = 0;
      }
      $xft{Total}{'Outflow'} +=  $xft{$sub_sys}{'Outflow'};
   }

}



sub ioflow_in_gtt_tr{
   foreach my $id(keys%gtt_tr){
       if(!exists $tr_last{$id}){
            my($systemPart,$product,$assignedEng) = @{$gtt_tr{$id}}[2,3,5];
            if($product=~/GTT_LSV/){
              my @tmp=($id,$assignedEng,$product);
              push @{$inflow{$systemPart}{'GTT'}}, \@tmp;
            }
        }
   }

   foreach my $sub_sys(@gtt_sys){
      if(exists $inflow{$sub_sys}{'GTT'}){
          $gtt{$sub_sys}{'Inflow'} = $gtt{$sub_sys}{'Inflow'} + scalar(@{$inflow{$sub_sys}{'GTT'}});
      }
      if(!defined $gtt{$sub_sys}{'Inflow'}){
         $gtt{$sub_sys}{'Inflow'} = 0;
      }
      $gtt{Total}{'Inflow'} += $gtt{$sub_sys}{'Inflow'};
   }

   foreach my $id(keys%tr_last){
        if(!exists $gtt_tr{$id}){
            my($systemPart,$product,$assignedEng,$mhsId) = @{$tr_last{$id}}[1,2,3,-1];
            if($product=~/GTT_LSV/){
                my @tmp=($id,$assignedEng,$product);
                push @{$outflow{$systemPart}{'GTT'}}, \@tmp;
            }
        }
   }
   foreach my $sub_sys(@combine_systems){
      if(exists $outflow{$sub_sys}{'GTT'}){
         $gtt{$sub_sys}{'Outflow'} =  $gtt{$sub_sys}{'Outflow'} + scalar(@{$outflow{$sub_sys}{'GTT'}});
      }
      if(!defined $gtt{$sub_sys}{'Outflow'}){
         $gtt{$sub_sys}{'Outflow'} = 0;
      }
      $gtt{Total}{'Outflow'} +=  $gtt{$sub_sys}{'Outflow'};
   }

}


# print report

print "\nSH SGSN Maintenance Weekly Info, week $week_no, $year\n";

my @product_show=("Subsystem","LFD Target", "In Total", "Internal TR", "Customer TR", "Blocker TR(all)", "Total Open TR", "Total Not Delivered TR");
my @maint_show=("Subsystem                ", "Open", "Alert/Hot", "Backlog", "Inflow", "Outflow", "A   ", "B   ", "C   ");
my @xft_show=("Subsystem", "Open", "Inflow", "Outflow", "Backlog", "Blocker", "Non-blocker");
my @gtt_show=("Subsystem", "Open", "Inflow", "Outflow", "Backlog");
my @state_show=("Product    ","In Total","Submitted","Assigned", "Investigated", "Resolved", "Verified", "Inflow", "Outflow");
my @all_show = (\@product_show, \@xft_show, \@maint_show, \@state_show, \@gtt_show);

get_length(\@all_show);

print_header("product", \@product_show);
foreach my $element(@sub_and_ft){
  my $lfd = $product{$element}{'LFD'};
  my $inTotal = $product{$element}{'InTotal'};
  my $program = $product{$element}{'Program'};
  my $maint = $product{$element}{'Maintenance'};
  my $blocker = $product{$element}{'Blocker'};
  my $open = $product{$element}{'Open'};
  my $not_deliver = $product{$element}{'TotalNotDeliver'};
  printf("%-$length{'Subsystem'}s %-$length{'LFD Target'}s %-$length{'In Total'}s %-$length{'Internal TR'}s %-$length{'Customer TR'}s %-$length{'Blocker TR(all)'}s %-$length{'Total Open TR'}s %-$length{'Total Not Delivered TR'}s ",$element, $lfd, $inTotal, $program, $maint, $blocker, $open, $not_deliver);
  #print "$sub_sys\t$lfd\t$inTotal\t$program\t$maint\t$blocker\t$open\n";
  print "\n";
}


foreach my $i(@control_team){
    $cp_team{$i} = "Control Plane";
}
foreach my $j(@payload_team){
    $pl_team{$j} = "Payload";
}
foreach my $c(@custom_team){
    $custom_team{$c} = "Custom";
}

ioflow_by_state;
$tr_state{'Total'}{'Inflow'} = $tr_state{'Maintenance'}{'Inflow'}+$tr_state{'Program'}{'Inflow'};
$tr_state{'Total'}{'Outflow'} = $tr_state{'Maintenance'}{'Outflow'}+$tr_state{'Program'}{'Outflow'};
team_by_state;

foreach(@status){
    $tr_state{'Maintenance'}{'InTotal'} += $tr_state{'Maintenance'}{$_};
    $tr_state{'Program'}{'InTotal'} += $tr_state{'Program'}{$_};
    $tr_state{'Total'}{'InTotal'} += $tr_state{'Total'}{$_};
}

# print overall TR state
if($state_print){
  print_header("state",\@state_show);
  foreach my $p(@p_product){
     my $sub = $tr_state{$p}{'Submitted'};
     my $ass = $tr_state{$p}{'Assigned'};
     my $inv = $tr_state{$p}{'Investigated'};
     my $res = $tr_state{$p}{'Resolved'};
     my $ver = $tr_state{$p}{'Verified'};
     my $intotal = $tr_state{$p}{'InTotal'};
     my $inflow = $tr_state{$p}{'Inflow'};
     my $outflow = $tr_state{$p}{'Outflow'};

     printf("%-$length{'Product    '}s %-$length{'In Total'}s %-$length{'Submitted'}s %-$length{'Assigned'}s %-$length{'Investigated'}s %-$length{'Resolved'}s %-$length{'Verified'}s %-$length{'Inflow'}s %-$length{'Outflow'}s ",$p,$intotal, $sub, $ass, $inv,$res,$ver,$inflow,$outflow);
     print "\n";

  }
  foreach my $t("Application","Payload","Custom","Other"){
     if(($t =~ /Custom/) && (@custom_team == 0)){
        next;
     }else{
        my $sub = $tr_state{$t}{'Submitted'};
        my $ass = $tr_state{$t}{'Assigned'};
        my $inv = $tr_state{$t}{'Investigated'};
        my $res = $tr_state{$t}{'Resolved'};
        my $ver = $tr_state{$t}{'Verified'};
        my $intotal = $tr_state{$t}{'InTotal'};
        my $inflow = $tr_state{$t}{'Inflow'};
        my $outflow = $tr_state{$t}{'Outflow'};

        printf("%-$length{'Product    '}s %-$length{'In Total'}s %-$length{'Submitted'}s %-$length{'Assigned'}s %-$length{'Investigated'}s %-$length{'Resolved'}s %-$length{'Verified'}s %-$length{'Inflow'}s %-$length{'Outflow'}s ",$t,$intotal, $sub, $ass, $inv,$res,$ver,$inflow,$outflow);
        print "\n";
     }

  }

}
# print customer TR status;
ioflow_in_customer_tr;
ioflow_in_internal_tr;
ioflow_in_gtt_tr;

for my $gg_sys(@sub_group_systems){
    $maintenance{$gg_sys}{'Open'} = 0;
    $maintenance{$gg_sys}{'Hot'} = 0;
    $maintenance{$gg_sys}{'Inflow'} = 0;
    $maintenance{$gg_sys}{'Outflow'} = 0;

}

foreach my $sub_sys(@combine_systems){
   if($sub_sys =~ /$ccgm/){
     if(defined $maintenance{$sub_sys}{'Open'}){
        $maintenance{$ccgm}{'Open'}  = $maintenance{$ccgm}{'Open'} + $maintenance{$sub_sys}{'Open'};
     }
     if(defined $maintenance{$sub_sys}{'Hot'}){
        $maintenance{$ccgm}{'Hot'}  = $maintenance{$ccgm}{'Hot'} + $maintenance{$sub_sys}{'Hot'};
     }
     if(defined $maintenance{$sub_sys}{'Inflow'}){
        $maintenance{$ccgm}{'Inflow'}  = $maintenance{$ccgm}{'Inflow'} + $maintenance{$sub_sys}{'Inflow'};
     }
     if(defined $maintenance{$sub_sys}{'Outflow'}){
        $maintenance{$ccgm}{'Outflow'}  = $maintenance{$ccgm}{'Outflow'} + $maintenance{$sub_sys}{'Outflow'};
     }
   }
   if($sub_sys =~ /$mg/){
     if(defined $maintenance{$sub_sys}{'Open'}){
       $maintenance{$mg}{'Open'}  = $maintenance{$mg}{'Open'} + $maintenance{$sub_sys}{'Open'};
     }
     if(defined $maintenance{$sub_sys}{'Hot'}){
       $maintenance{$mg}{'Hot'}  = $maintenance{$mg}{'Hot'} + $maintenance{$sub_sys}{'Hot'};
     }
     if(defined $maintenance{$sub_sys}{'Inflow'}){
       $maintenance{$mg}{'Inflow'}  = $maintenance{$mg}{'Inflow'} + $maintenance{$sub_sys}{'Inflow'};
     }
     if(defined $maintenance{$sub_sys}{'Outflow'}){
       $maintenance{$mg}{'Outflow'}  = $maintenance{$mg}{'Outflow'} + $maintenance{$sub_sys}{'Outflow'};
     }
   }
   
   if($sub_sys !~ /Total/){
     $maintenance{'Total'}{'Open'} = $maintenance{'Total'}{'Open'} + $maintenance{$sub_sys}{'Open'};
     $maintenance{'Total'}{'Hot'} = $maintenance{'Total'}{'Hot'} + $maintenance{$sub_sys}{'Hot'};
     $maintenance{'Total'}{'Inflow'} = $maintenance{'Total'}{'Inflow'} + $maintenance{$sub_sys}{'Inflow'};
     $maintenance{'Total'}{'Outflow'} = $maintenance{'Total'}{'Outflow'} + $maintenance{$sub_sys}{'Outflow'};

   }

}

for my $g_sys(@group_systems){
   if($g_sys !~ /Total/){
      $maintenance{'Total'}{'A'} = $maintenance{'Total'}{'A'} + $maintenance{$g_sys}{'A'};
      $maintenance{'Total'}{'B'} = $maintenance{'Total'}{'B'} + $maintenance{$g_sys}{'B'};
      $maintenance{'Total'}{'C'} = $maintenance{'Total'}{'C'} + $maintenance{$g_sys}{'C'};
      $maintenance{'Total'}{'Customer'} = $maintenance{'Total'}{'Customer'} + $maintenance{$g_sys}{'Customer'};
   }
}

$length{'group_subsystem'} = 27;

if($customer_print){
print_header("maintenance", \@maint_show);
foreach my $sub_sys(@group_systems){
  my $open = $maintenance{$sub_sys}{'Open'};
  my $hot = $maintenance{$sub_sys}{'Hot'};
  my $backlog = $maintenance{$sub_sys}{'Backlog'};
  my $inflow = $maintenance{$sub_sys}{'Inflow'};
  my $outflow = $maintenance{$sub_sys}{'Outflow'};
  my $severity_A = $maintenance{$sub_sys}{'A'};
  my $severity_B = $maintenance{$sub_sys}{'B'};
  my $severity_C = $maintenance{$sub_sys}{'C'};
 
  printf("%-$length{'group_subsystem'}s %-$length{'Open'}s %-$length{'Alert/Hot'}s %-$length{'Backlog'}s %-$length{'Inflow'}s %-$length{'Outflow'}s %-$length{'A   '}s %-$length{'B   '}s %-$length{'C   '}s ",$sub_sys, $open, $hot, $backlog, $inflow, $outflow, $severity_A, $severity_B, $severity_C);
  #print "$sub_sys\t$open\t$inflow\t$outflow\n";
  print "\n";
}
}

if($internal_print){
print_header("xft", \@xft_show);
foreach my $sub_sys(@xft_systems_total){
  my $open = $xft{$sub_sys}{'Open'};
  my $inflow = $xft{$sub_sys}{'Inflow'};
  my $outflow = $xft{$sub_sys}{'Outflow'};
  my $backlog = $xft{$sub_sys}{'Backlog'};
  my $blocker = $xft{$sub_sys}{'Blocker'};
  my $non_blocker = $xft{$sub_sys}{'Non-blocker'};

  printf("%-$length{'Subsystem'}s %-$length{'Open'}s %-$length{'Inflow'}s %-$length{'Outflow'}s %-$length{'Outflow'}s %-$length{'Blocker'}s %-$length{'Non-blocker'}s ",$sub_sys, $open, $inflow, $outflow,$backlog,$blocker,$non_blocker);
  print "\n";
  #print "$sub_sys\t$open\t$inflow\t$outflow\t$backlog\n";
  
}
}

if($gtt_print){
print_header("gtt", \@gtt_show);
foreach my $sub_sys(@gtt_systems){
  my $open = $gtt{$sub_sys}{'Open'};
  my $inflow = $gtt{$sub_sys}{'Inflow'};
  my $outflow = $gtt{$sub_sys}{'Outflow'};
  my $backlog = $gtt{$sub_sys}{'Backlog'};
#  my $blocker = $xft{$sub_sys}{'Blocker'};
#  my $non_blocker = $xft{$sub_sys}{'Non-blocker'};

  printf("%-$length{'Subsystem'}s %-$length{'Open'}s %-$length{'Inflow'}s %-$length{'Outflow'}s %-$length{'Outflow'}s ",$sub_sys, $open, $inflow, $outflow,$backlog);
  print "\n";
  #print "$sub_sys\t$open\t$inflow\t$outflow\t$backlog\n";
  
}
}


if($detail){
  #my @hot_blocker_show=("id","Subsystem","Importance","State","Headline","foundInProduct","assignedEngineer");
  my @hot_blocker_show=();
  if($detail_by_product){
     @hot_blocker_show=("id","Product","Imp","State","Engineer","Sub","Head");
  }else{
     @hot_blocker_show=("id","Sub","Imp","State","Engineer","Product","Head");
  }
  my $bar;
  my $length;
  for my $sys(keys%hot_tr){
     for my $temp_ref(@{$hot_tr{$sys}}){
         my @temp=@{$temp_ref};
         for(my $i=0;$i<@temp;$i++){
            maxLength($temp[$i],$hot_blocker_show[$i]);
         }
     }

  }
  foreach(keys%blocker_length){
    $length += $blocker_length{$_}; 
  }
  $bar = "-" x $length;
  print "\nDetails of all Alert/Hot/Blocker TRs\n$bar\n";
  for my $show(@hot_blocker_show){
     printf("%-$blocker_length{$show}s", $show);
  }
  print "\n$bar\n";
 if($detail_by_product){
  for my $prod(keys%hot_tr){
      for my $temp_ref(@{$hot_tr{$prod}}){
          my @temp=@{$temp_ref};
          for(my $i=0;$i<@temp;$i++){
             printf("%-$blocker_length{$hot_blocker_show[$i]}s", $temp[$i]);
          }
          print "\n";
      }
  }
 }else{
  for my $sys(keys%hot_tr){
      for my $temp_ref(@{$hot_tr{$sys}}){
          my @temp=@{$temp_ref};
          for(my $i=0;$i<@temp;$i++){
             printf("%-$blocker_length{$hot_blocker_show[$i]}s", $temp[$i]);
          }
          print "\n";
      }
  }
 }
}

if($list){
print "\n$sep2\nList of Inflow TRs\n$sep2\n";
foreach my $sub_sys(@gtt_sys){
   print "$sub_sys\n";
   if(defined $inflow{$sub_sys}{'LSV'}){
      print "   Internal:\n";
      for my $ref(@{$inflow{$sub_sys}{'LSV'}}){
         foreach(@{$ref}){
           print "\t$_";
         }
         print "\n";
      }
   }
   if(defined $inflow{$sub_sys}{'Maintenance'}){
      print "   Customer:\n";
      for my $ref(@{$inflow{$sub_sys}{'Maintenance'}}){
          foreach(@{$ref}){
             print "\t$_";
          }
           print "\n";
      }
   }
   if(defined $inflow{$sub_sys}{'GTT'}){
      print "   GTT:\n";
      for my $ref(@{$inflow{$sub_sys}{'GTT'}}){
          foreach(@{$ref}){
             print "\t$_";
          }
           print "\n";
      }
   }
  
   print "$sep\n";
}

print "\n$sep2\nList of Outflow TRs\n$sep2\n";
foreach my $sub_sys(@gtt_sys){
   print "$sub_sys\n";
   if(defined $outflow{$sub_sys}{'LSV'}){
      print "   Internal:\n";
      for my $ref(@{$outflow{$sub_sys}{'LSV'}}){
          foreach(@{$ref}){
             print "\t$_";
           }
           print "\n";
      }
   }
   if(defined $outflow{$sub_sys}{'Maintenance'}){
      print "   Customer:\n";
      for my $ref(@{$outflow{$sub_sys}{'Maintenance'}}){
         foreach(@{$ref}){
            print "\t$_";
         }
         print "\n";
      }
   }
   if(defined $outflow{$sub_sys}{'GTT'}){
      print "   GTT:\n";
      for my $ref(@{$outflow{$sub_sys}{'GTT'}}){
         foreach(@{$ref}){
            print "\t$_";
         }
         print "\n";
      }
   }
   print "$sep\n";
}
}


# Finally, write TRs of this week into a file, will not write to file if with option "-o"
if($friday & $out){
   open(FH, "> $curr_week") or die("can not open file $curr_week:$!\n");
   foreach my $id(keys%all_tr){
      my $record = join("|", @{$all_tr{$id}});
      print FH $record."\n";
   }
   close FH;
}
if($tuesday & $out){
   open(FH, "> $curr_tuesday") or die("can not open file $curr_tuesday:$!\n");
   foreach my $id(keys%all_tr){
      my $record = join("|", @{$all_tr{$id}});
      print FH $record."\n";
   }
   close FH;
}

CQSession::Unbuild($sessionObj);
