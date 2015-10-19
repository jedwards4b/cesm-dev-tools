#!/usr/bin/perl
use strict;
use XML::LibXML;
my $allactive_tests = "$ENV{CIMEROOT}/cime_config/cesm/allactive/testlist_allactive.xml";
my $allactive_compsets = "$ENV{CIMEROOT}/cime_config/cesm/allactive/config_compsets.xml";
my $xml =  XML::LibXML->new( no_blanks => 1)->parse_file("$allactive_compsets");

my $aliasmap;

$aliasmap = { CAM5=>"C5",CAM4=>"C4", CLM40=>"L40", CLM45=>"L45",
	      CAM55=>"",
	      1850=>"1850", MOSART=>"", RTM=>"R", CISM1=>"G",
	      CISM2=>"G2",DWAV=>"DW",
              WW3=>"WW", 5505=>"55", RCP8=>"RCP85", RCP2=>"RCP26",
              RCP4=>"RCP45", 2000=>"", HIST=>"HIST", TEST=>"TEST"};


my $compsets;
my @lnodes = $xml->findnodes(".//lname");
my @oldanodes = $xml->findnodes(".//alias");
my $i=0;
foreach my $node (@lnodes){
    my $alias = $oldanodes[$i++]->textContent();
    if(defined $compsets->{$alias}{longname}){
	print "oldalias mismatch $alias $compsets->{$alias}{longname} ".$node->textContent()."\n";
    }else{
	$compsets->{$alias}{longname}  =  $node->textContent();
    }
}

foreach my $oldalias (keys %{$compsets}){
    my $compset = $compsets->{$oldalias}{longname};
    my @parts = split('_',$compset);
    my $alias;
    if($compset =~ /DOCN%SOM/){
	$alias = "E";
    }else{
	$alias = "B";
    }

    foreach my $part (@parts){
	my $modifier;
	next if ($part eq "DOCN%SOM");
	next if ($part eq "CLM50%BGC");
	next if ($part eq "POP2%ECO");
	if($part =~ /(.*)%(.*)/){
	    $part = $1;
	    $modifier = $2;
	}
	if(defined $aliasmap->{$part}){
	    $alias .=$aliasmap->{$part};
	}
	
	if(defined $modifier){
	    $alias .= $modifier;
	}
    }
    if(defined $compsets->{$oldalias}{newalias}){
	print "alias mismatch: $alias $compsets->{$oldalias}{longname} $compset\n";
    }
    $compsets->{$oldalias}{newalias} = $alias;
#    print "$alias $compset\n";
}



my $txml =   XML::LibXML->new( no_blanks => 1)->parse_file("$allactive_tests");

my @tnodes = $txml->findnodes(".//compset");
foreach my $tnode (@tnodes){
    my $talias = $tnode->getAttribute('name');

    if(defined $compsets->{$talias}){
	$compsets->{$talias}{tested}=1;
    }else{
	print "No match found for test compset $talias\n";
    }
    
}

foreach my $oldalias (keys %$compsets){
    if(defined $compsets->{$oldalias}{tested}){
	printf("%-20.20s %-20.20s %s\n",$oldalias,$compsets->{$oldalias}{newalias}, $compsets->{$oldalias}{longname});
    }else{
	printf ("%-20.20s %20.20s %s is not tested\n",$oldalias, " ",$compsets->{$oldalias}{longname} );
    }

}

open(FT,"$allactive_tests");
my @allactive_tests = <FT>;
close(FT);
open(NFT,">$allactive_tests.new");
foreach(@allactive_tests){

    if(/<compset name=\"(.*)\">/){
	my $oldalias = $1;
	my $newalias = $compsets->{$oldalias}{newalias};
	s/$oldalias/$newalias/;
    }
    print NFT $_;
}
close(NFT);

open(CC,"$allactive_compsets");
my @allactive = <CC>;
close(CC);
open(NCC,">$allactive_compsets.new");
my $incompset=0;
foreach(@allactive){
    if(/<compset>/){
	$incompset=1;
	next;
    }
    if(/<\/compset>/){
	if($incompset==1){
	    print NCC $_;
	}
	$incompset=0;
	next;
    }
    if($incompset == 1){
	if(/<alias>\s*(\w+)\s*<\/alias>/){
	    my $oldalias = $1;
	    my $newalias = $compsets->{$oldalias}{newalias};
	    if($compsets->{$oldalias}{tested}==1){
		s/$oldalias/$newalias/;
		print NCC "  <compset>\n";
		print NCC $_;
		next;
	    }else{
		$incompset = -1;
		next;
	    }
	}
	print NCC $_;
    }elsif($incompset == 0){
	print NCC $_;
    }

}

