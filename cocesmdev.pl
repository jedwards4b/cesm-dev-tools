#!/usr/bin/perl
use strict;
my $version = shift;
my $alpharoot = "https://svn-ccsm-models.cgd.ucar.edu/cesm1/alphas/branches/";
my $fullurl;
if($version =~ /^cesm/){
    $fullurl=$alpharoot.$version;
}elsif($version =~ /(cesm1_.*$)/){
    $fullurl=$version;
    $version = $1;
}else{
    die "Usage $0 cesm_version";
}

system("svn co --ignore-externals $fullurl");
chdir($version);
open(F,"SVN_EXTERNAL_DIRECTORIES");
foreach(<F>){
    if(/^(components.*)\s+(http.*)$/){
	my $path = $1;
	my $url = $2;
#	print "$url $path\n";
	system("svn co $url $path &");
    }
}
close(F);
