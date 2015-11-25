#!/usr/bin/perl 

use lib "/home/eenzcha/perl-modules/lib/perl5/site_perl/5.8.8/";
use strict;
use Spreadsheet::ParseExcel;

my @sub_systems=("CAS","CHS","EPS","GTS","MPS","MTS","MVS","UPS","XPS","TTx");
#my @sub_systems=("EPS");
my %no;
my %goal;
my %percent;
my @month=("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November");

my %month_row=('December'=>'51',
               'January' =>'52',
               'February'=>'53',
               'March'   =>'54',
               'April'   =>'55',
               'May'     =>'56',
               'June'    =>'57',
               'July'    =>'58',
               'August'  =>'59',
               'September'=>'60',
               'October' =>'61',
               'November'=>'62'
);
my ($row_min, $row_max) = (51,63);
my ($col_min, $col_max) = (1,9);

my $FileName = "/home/eenzcha/clearquest/Main_SGSN_answertimeRolling.xls";
my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($FileName);
die $parser->error() if(!defined $workbook);

my @show = ("Number of TRs", "Number of TRs w/in goal", "Percentage of TRs w/in goal");
my @sub_show = ("A", "B", "C", "A", "B", "C", "A", "B", "C", "Total");
my $bar= "-" x 110;
my $last_month = &get_last_month;

sub print_header{
   print "\nResponsible Time of TRs in $last_month\n$bar\n";
   printf("%-9s|", "");
   printf("%-29s|", $_) foreach(@show);
   print "\n$bar\n";
   printf("%-9s|", "Subsystem");
   printf("%-9s|", $_) foreach(@sub_show);
   print "\n$bar\n";
}
 
sub get_last_month{
   my($sec,$min,$hour,$mday,$mon,$year_off,$wday,$yday,$isdst)=localtime(time);
   my $last_month=$month[$mon];
   return $last_month;
}
sub get_row{
   my($worksheet)=@_;
   for my $row($row_min .. $row_max){
     my $cell = $worksheet->get_cell($row, 0);
     my $value = $cell->value();
#print "$value\n";
     if($value =~ $last_month){
        return $row;
     } 
   }  
}

&print_header;

#print "$last_month,  $row\n";

# Following block is used to Iterate through all worksheets
# in the workbook and print the worksheet content 
for my $sub_sys(@sub_systems){
   printf("%-9s ", $sub_sys);
   my $worksheet = $workbook->worksheet($sub_sys);
   my $row = get_row($worksheet);
   my($no, $w_in_goal)=(0,0);
   my $percent;
   for my $col ($col_min .. $col_max) {
       my $cell = $worksheet->get_cell($row, $col);
       next unless $cell; 
       my $value = $cell->value();
       printf("%-9s ", $value);
       if($col le 3){
         $no += $value; 
       }
       if(($col ge 4) && ($col le 6)){
         $w_in_goal +=$value;
       }

       if($col eq 1){
          $no{$sub_sys}{'A'} = $value; 
       }
       if($col eq 2){
          $no{$sub_sys}{'B'} = $value;
       }
       if($col eq 3){
          $no{$sub_sys}{'C'} = $value;
       }
       if($col eq 4){
          $goal{$sub_sys}{'A'} = $value;
       }
       if($col eq 5){
          $goal{$sub_sys}{'B'} = $value;
       }
       if($col eq 6){
          $goal{$sub_sys}{'C'} = $value;
       }

   }
   if($no gt 0){
       $percent = sprintf("%0.3f", ($w_in_goal/$no));
   }else{
       $percent = 0;
   }
   printf("%-0.1f%\n", $percent*100);
   #print "$w_in_goal, $no\n";
}

# ready to print the total result of all subsystems
print "$bar\n";
printf("%-9s ", "Total");
my($no_total, $goal_total, $total_percent)=(0,0,0);

my @severity=("A", "B", "C");
foreach my $sev(@severity){
   for my $sub_sys(@sub_systems){
       $no{'Total'}{$sev} +=$no{$sub_sys}{$sev};
       $goal{'Total'}{$sev} +=$goal{$sub_sys}{$sev};
   }
}

foreach my $sev(@severity){
   if($no{'Total'}{$sev} gt 0){
      $percent{'Total'}{$sev} = sprintf("%0.1f%", ($goal{'Total'}{$sev}/$no{'Total'}{$sev})*100);
   }else{
      $percent{'Total'}{$sev} = 0;
   }
}

foreach my $sev(@severity){
   $no_total += $no{'Total'}{$sev};
   $goal_total += $goal{'Total'}{$sev};
}

if($no_total gt 0){
   $total_percent = sprintf("%0.1f%", ($goal_total/$no_total)*100);
}else{
   $total_percent = 0;
}

foreach my $sev(@severity){
   printf("%-9s ", $no{'Total'}{$sev});
}

foreach my $sev(@severity){
   printf("%-9s ", $goal{'Total'}{$sev});
}

foreach my $sev(@severity){
   printf("%-9s ", $percent{'Total'}{$sev});
}
printf("%-9s ", $total_percent);
print "\n$bar\n";
