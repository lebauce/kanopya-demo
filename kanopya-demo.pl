#!/usr/bin/perl -w
use strict;
use warnings;
use KanopyaDemo::Reset;
use KanopyaDemo::Setup;
use KanopyaDemo::Init;
use KanopyaDemo::IAAS;
use KanopyaDemo::Policies;
use KanopyaDemo::Services;
use KanopyaDemo::ServiceInstances;

local $| = 1;

# test root privileges
if ($< != 0) {
    die "You must be root to execute this script";
}

# test PERL5LIB
if(not exists $ENV{PERL5LIB}) {
    die "PERL5LIB environment variable must be set to execute this script";
}

# reset step :
# clean the system to go back to a fresh installation state 

if(KanopyaDemo::Reset::run() != 0) {
    die "KanopyaDemo::Reset::run() terminates with no zero exit code\n";
}

# setup step :
# launch setup.pl with auto answers 

if(KanopyaDemo::Setup::run() != 0) {
    die "KanopyaDemo::Setup::run() terminates with no zero exit code\n";
}

# infra init
if(KanopyaDemo::Init::run() != 0) {
    die "KanopyaDemo::Init::run() terminates with no zero exit code\n";
}

# iaas init step :
# declare iaas infrastructure

if(KanopyaDemo::IAAS::run() != 0) {
    die "KanopyaDemo::IAAS::run() terminates with no zero exit code\n";
}

# policies step :
# create policies used to build services

if(KanopyaDemo::Policies::run() != 0) {
    die "KanopyaDemo::Policies::run() terminates with no zero exit code\n";
}

# services step
# create services used to instanciate customer services

if(KanopyaDemo::Services::run() != 0) {
    die "KanopyaDemo::Services::run() terminates with no zero exit code\n";
}

# services instances step
# create vms service instances
if(KanopyaDemo::ServiceInstances::run() != 0) {
    die "KanopyaDemo::ServiceInstances::run() terminates with no zero exit code\n";
}

print "\n !!! Kanopya Demo infrastructure ready to use !!!\n";
