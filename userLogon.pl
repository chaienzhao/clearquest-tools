#!/opt/rational/clearquest/bin/cqperl
use CQPerlExt;
use strict;

# Global variables
my $sessionObj;
my $databases;
my $count;
my @owners = ("eenzcha");
my @states = ("Assigned", "Investigated");
my $resultset;
my $querydef;
my @filters = ("Clone of");
my @dateRange = ("2012-09-01", "2012-09-30");
my @fields=("id", "answerCode", "assignedEngineer", "AssignedOn", "CSR_number", "Headline", "history", "Importance", "InvestigatedOn", "overdueDate", "Owner", "ResolvedOn", "State", "SubmittedOn", "systemPart");
my @systems=("CHS", "CAS", "EPS", "UPS","MPS","MTS","GTS-U","GTS-C","MVS","XPS","TTx");
my @subs=("TTx"); # Only for test
my @tr_id = ("SGSN00070442");


#Start a Rational ClearQuest session

$sessionObj = CQSession::Build();

#Get a list of accessible databases

$databases = $sessionObj->GetAccessibleDatabases("MASTR", "eenzcha", "ggsnj20");

$count = $databases->Count();

#For each accessible database, login as joe with password gh36ak3

for(my $x=0;$x<$count;$x++){

   my $db = $databases->Item($x);
   my $dbName = $db->GetDatabaseName();

   # Logon to the database
   if($dbName =~ /SGSN/){
      print "Logon database $dbName...\n";
      $sessionObj->UserLogon("eenzcha", "eenzcha", $dbName, "ggsnj20");
      if($? eq 0){
        print "Logon successfully\n";
      }
      
my $userName = $sessionObj->GetUserFullName();
my $userLogin = $sessionObj->GetUserLoginName();
my $userEmail = $sessionObj->GetUserEmail();
print "$userName, $userLogin, $userEmail\n";

      # Build query
      $querydef = $sessionObj->BuildQuery("defect");
      $querydef->BuildField("id");
      $querydef->BuildField("headline");

      # Add filters
      my $operator = $querydef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
      #$operator->BuildFilter("Owner", $CQPerlExt::CQ_COMP_OP_EQ,\@owners);
      #$operator->BuildFilter("systemPart", $CQPerlExt::CQ_COMP_OP_EQ,\@subs);
      $operator->BuildFilter("ID", $CQPerlExt::CQ_COMP_OP_EQ,\@tr_id);
      #$operator->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@states);
      #$operator->BuildFilter("SubmittedOn", $CQPerlExt::CQ_COMP_OP_BETWEEN, \@dateRange);
      #$operator->BuildFilter("Headline", $CQPerlExt::CQ_COMP_OP_NOT_LIKE, \@filters);

      $resultset = $sessionObj->BuildResultSet($querydef);
      $resultset->Execute();

      while (($resultset->MoveNext()) == 1){

   	  my $id   = $resultset->GetColumnValue(1);
  	  my $entity  = $sessionObj->GetEntity("Defect", $id);
   	  my $head = $entity->GetFieldValue("Headline")->GetValue();
   	  my $state= $entity->GetFieldValue("State")->GetValue();
   	  my $owner= $entity->GetFieldValue("Owner")->GetValue();
          my $assigned_engineer_email = $entity->GetFieldValue("assignedEngineer.email")->GetValue();
          #foreach my $group(@$assigned_engineer){
                #my $name = $group->GetValue();
                print "The email address of assigned engineer is $assigned_engineer_email\n";
          #}
          my $progress_infos_ref = $entity->GetFieldValue("progressInformation")->GetValueAsList();
          foreach my $p_ref(@$progress_infos_ref){
                  my $progress_entity = $sessionObj->LoadEntityByDbId("progressInformation", $p_ref);
                  my $headline =  $progress_entity->GetFieldValue("headline")->GetValue(); 
                  print "This progress information's headline is $headline\n";
          } 

          # Find out how many history fields there
          # are so the for loop can iterate them
          
          my $historyfields = $entity->GetHistoryFields();
          my $numfields = $historyfields->Count();
          print "Number of history fields is $numfields\n";
          for (my $x = 0; $x < $numfields ; $x++){
          
             # Get each history field
          
              my $onefield = $historyfields->Item($x);
              my $histories = $onefield->GetHistories(); 
               
              my $num_histories = $histories->Count();
              for (my $y = 0; $y < $num_histories ; $y++){
                     my $history = $histories->Item($y);
                     my $value = $history -> GetValue();
                     print "$y,  $value. \n";
               }
          
           } 

      }
   } 

}

CQSession::Unbuild($sessionObj); 
