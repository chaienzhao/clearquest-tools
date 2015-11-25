#!/opt/rational/clearquest/bin/cqperl

use lib "/home/eenzcha/perl-modules/lib/perl5/site_perl/5.8.8/";

use CQPerlExt;
use strict;
use Spreadsheet::ParseExcel;
use Getopt::Long;

# Global variables
my $sessionObj;
my @display_fields=("id", "headline");
#my @month=("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November");
my @mon_short = ('DEC','JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV');
my @Resolved_dateRange;
my @Investigated_dateRange;
my @sub_systems=("EPS","UPS","MPS","MTS","GTS-U","GTS-C","MVS","CHS","CAS","TTx");
my @group_systems=("EPS","MPS_UPS","MTS_GTS","CAS_MVS","CHS","TTx");
my @product=("SGSN-MME 13B","SGSN-MME 13A","SGSN-MME 2010A","SGSN-MME 2010B","SGSN-MME 2011A","SGSN-MME 2011A FP02","SGSN-MME 2011B","SGSN-MME 2012A","SGSN-MME 2009A","SGSN-MME 2009B");
my @importance=("89");
my @D_answerCode=("D");
my @B11_answerCode=("B11");
my @original=("Yes");
my %no;
my $effort=0;
my $date;
my $filename;
my $cq_dir="/home/eenzcha/clearquest";

sub month_days {
    my($m, $y) = @_;
    my %md_mon = ('JAN',1,'FEB',2,'MAR',3,'APR',4,'MAY',5,'JUN',6,'JUL',7,'AUG',8,'SEP',9,'OCT',10,'NOV',11,'DEC',12);
    my @md_mon = (0,31,28,31,30,31,30,31,31,30,31,30,31);
    $m = $md_mon{uc($m)} if $m =~ /[a-zA-Z]/;
    my $d = $md_mon[$m];
    $d++ if $m == 2 && $y % 4 == 0 && ($y % 100 != 0 || $y % 400 == 0);
    return $d;
}

sub get_dateRange{
   my($mon,$year_off)=(localtime(time))[4,5];
   my $year = $year_off + 1900;
   my $mon_beg = $mon-2;
   my $year_beg = $year;
   if($mon_beg le 0){
     $year_beg--;
   }
   
   my $day = month_days($mon_short[$mon], $year);
   my $begin = sprintf("%02d-%02d-%02d", $year_beg, $mon_beg, 1);
   my $end   = sprintf("%02d-%02d-%02d", $year, $mon, $day);
   my @date_range = ($begin, $end);
   return \@date_range;
}

sub logon_db{
  my($sessionObj, $username, $passwd, $db_name, $db_set)=@_;
  $sessionObj->UserLogon($username, $passwd, $db_name, $db_set);
  if($? eq 0){
     #print "Successfully logon ...\n";
     return $sessionObj;
  }else{
     die "Logon database failed: $!\n";
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

# add filter effort 
sub add_filter_effort{
  my($querydef, $sub_sys)=@_;
  my @target_sys;

  push @target_sys, $sub_sys;

  my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator1 = $operator->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);
  my $operator2 = $operator1->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
  my $operator3 = $operator2->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_OR);

  $operator->BuildFilter("foundInproduct", $CQPerlExt::CQ_COMP_OP_IN,\@product);
  $operator->BuildFilter("Importance", $CQPerlExt::CQ_COMP_OP_NEQ, \@importance);
  $operator->BuildFilter("isOriginal", $CQPerlExt::CQ_COMP_OP_EQ, \@original);
  $operator1->BuildFilter("ResolvedOn", $CQPerlExt::CQ_COMP_OP_BETWEEN, \@Resolved_dateRange);
  $operator2->BuildFilter("InvestigatedOn", $CQPerlExt::CQ_COMP_OP_BETWEEN, \@Investigated_dateRange);
  $operator3->BuildFilter("answerCode", $CQPerlExt::CQ_COMP_OP_LIKE, \@D_answerCode);
  $operator3->BuildFilter("answerCode", $CQPerlExt::CQ_COMP_OP_LIKE, \@B11_answerCode);
  
  $operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@target_sys);

  #print "Add filter\n";

}


sub compute_effort{
  my($sessionObj, $querydef, $sub_sys)=@_;
  my $resultset = $sessionObj->BuildResultSet($querydef);
  $resultset->EnableRecordCount();
  $resultset->Execute();
  my $count = $resultset->GetRecordCount();

  $no{$sub_sys}=$count;
  printf("%-20s: %-18s\n", $sub_sys,$count);

#  #printf "$sub_sys:\t$count\n";
#  if($sub_sys =~ /MVS/){ 
#   if(defined $resultset){
#      while (($resultset->MoveNext()) == $CQPerlExt::CQ_SUCCESS){
#        my $id   = $resultset->GetColumnValue(1);
#        my $entity  = $sessionObj->GetEntity("Defect", $id);
#        my $head = $entity->GetFieldValue("Headline")->GetValue();
#        my $foundInProduct = $entity->GetFieldValue("foundInProduct")->GetValue();
#        my $state= $entity->GetFieldValue("State")->GetValue();
# 
#        print "$id, $foundInProduct, $state\n";
#      }
# 
#   }else{
#      print "ResultSet is undef\n";
#   }
#  }


}

sub set_effort{
 $effort = 1;
}

#main

my $res=GetOptions('effort'       => \&set_effort,
                   'date=s'       => \$date,
                   'filename=s'   => \$filename,
                   'help'         => \&usage,
                  );


# Start a Rational ClearQuest session
$sessionObj = CQSession::Build();

# Logon
$sessionObj = logon_db($sessionObj, "eenzcha", "eenzcha", "SGSN", "ggsnj20");

if(defined $date){
   @Resolved_dateRange = split(/\,/, $date);
   @Investigated_dateRange = split(/\,/, $date);
}else{
   my $dateRange_ref = get_dateRange;
   @Resolved_dateRange = @{$dateRange_ref};
   @Investigated_dateRange = @{$dateRange_ref};
}

# Build query, add filter

my $query_bar="-" x 43;
print "\nNumber of TRs from $Resolved_dateRange[0] to $Resolved_dateRange[1]\n$query_bar\n";
foreach my $sub_sys(@sub_systems){
    my $querydef=build_query($sessionObj);
    add_filter_effort($querydef, $sub_sys);
    compute_effort($sessionObj, $querydef, $sub_sys);
}

print "$query_bar\n";

# Unbuild the session
CQSession::Unbuild($sessionObj);

############################################################
# the procedure below is used for computing man hour per tr
############################################################

if($effort){

# default time report file
my $FileName = "$cq_dir/91229839_Nov.xls.xls";
if(defined $filename){
 $FileName = "$cq_dir/$filename";

}
my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($FileName);

die $parser->error(), ".\n" if(!defined $workbook);

# Following block is used to Iterate through all worksheets
# in the workbook and print the worksheet content

my $worksheet= $workbook->worksheet('Sheet1');

# Find out the worksheet ranges
my ($row_min, $row_max) = $worksheet->row_range();
my ($col_min, $col_max) = $worksheet->col_range();

#print "\$row_min=$row_min, \$row_max=$row_max\n";
#print "\$col_min=$col_min, \$col_max=$col_max\n";

my %total_mhr;
my %system_row;
my $system_col;
my $total_col;

for my $row($row_min .. $row_max) {
    for my $col($col_min+1 .. $col_max) {
        # Return the cell object at $row and $col
        my $cell = $worksheet->get_cell($row, $col);
        next unless $cell;
        my $value = $cell->value();

        if($value =~ /Op.*text/){
          $system_col = $col;
        }
        if($value =~ /Grand Total/){
          $total_col = $col;
        }
       
    }
}
#print "\$system_col=$system_col, \$total_col= $total_col\n";

for my $row($row_min .. $row_max){
    my $cell = $worksheet->get_cell($row, $system_col);
    next unless $cell;
    my $value = $cell->value();
    if($value =~ /DM MTS_GTS-U TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'MTS_GTS-U'}=$total_cell->value();
    }
    if($value =~ /DM CHS_LIS/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'CHS'}=$total_cell->value();
    }
    if($value =~ /DM MPS_UPS TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'MPS_UPS'}=$total_cell->value();
    }
    if($value =~ /DM MSS TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'MVS'}=$total_cell->value();
    }
    if($value =~ /DM TTx/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'TTx'}=$total_cell->value();
    }
    if($value =~ /DM CAS TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'CAS'}=$total_cell->value();
    }
    if($value =~ /DM MVS TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'MVS'}=$total_cell->value();
    }
    if($value =~ /DM GTS-C TR/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'GTS-C'}=$total_cell->value();
    }
    if($value =~ /DM SGSN EPS/){
      my $total_cell = $worksheet->get_cell($row, $total_col);
      $total_mhr{'EPS'}=$total_cell->value();
    }

}


my %tr_no;
my %per_tr;
for my $sys(@group_systems) {
   if($sys =~ /MTS_GTS/){
      $tr_no{$sys} = $no{'MTS'} + $no{'GTS-U'} + $no{'GTS-C'};
      $total_mhr{$sys}= $total_mhr{'MTS_GTS-U'} + $total_mhr{'GTS-C'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }
   if($sys =~ /CHS/){
      $tr_no{$sys} = $no{'CHS'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }
   if($sys =~ /MPS_UPS/){
      $tr_no{$sys} = $no{'MPS'} + $no{'UPS'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }
   if($sys =~ /TTx/){
      $tr_no{$sys} = $no{'TTx'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }
   if($sys =~ /CAS_MVS/){
      $tr_no{$sys} = $no{'CAS'} + $no{'MVS'};
      $total_mhr{$sys} = $total_mhr{'CAS'} + $total_mhr{'MVS'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }
   if($sys =~ /EPS/){
      $tr_no{$sys} = $no{'EPS'};
      if($tr_no{$sys} gt 0){
         $per_tr{$sys} =sprintf("%0.1f", ($total_mhr{$sys}/$tr_no{$sys}));
      }else{
         $per_tr{$sys} = 0;
      }
   }


}


# compute total tr no and mhr per tr

for my $sys(@group_systems){
   $tr_no{'Total'} += $tr_no{$sys};
   $total_mhr{'Total'} += $total_mhr{$sys};
}
$per_tr{'Total'} = sprintf("%0.1f", ($total_mhr{'Total'}/$tr_no{'Total'}));

# print report

my @mhr_show = ("Subsystem", "Number of TRs", "Total MHR", "MHR per TR");
my $bar = "-" x 68;
print "\nMaintenance TR effort from $Resolved_dateRange[0] to $Resolved_dateRange[1]\n$bar\n";
foreach(@mhr_show){
   printf("%-16s|", $_);
}
print "\n$bar\n";
for my $sys(@group_systems) {
   if($sys =~ /EPS/){
     my $tr_no=$no{'EPS'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});
   
   }
   if($sys =~ /MPS_UPS/){
     my $tr_no=$no{'MPS'} + $no{'UPS'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});
   
   }
   if($sys =~ /MTS_GTS/){
     my $tr_no=$no{'MTS'} + $no{'GTS-U'} + $no{'GTS-C'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});

   } 
   if($sys =~ /CHS/){
     my $tr_no=$no{'CHS'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});
   
   }
   if($sys =~ /CAS_MVS/){
     my $tr_no=$no{'CAS'} + $no{'MVS'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});
   
   }
   if($sys =~ /TTx/){
     my $tr_no=$no{'TTx'};
     printf("%-16s %-16s %-16s %-16s\n", $sys,$tr_no,$total_mhr{$sys},$per_tr{$sys});
   
   }

}
print "$bar\n";
printf("%-16s %-16s %-16s %-16s\n", "Total",$tr_no{'Total'},$total_mhr{'Total'},$per_tr{'Total'});
print "$bar\n";

}
