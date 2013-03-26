package KanopyaDemo::Setup;

use strict;
use warnings;
use Cwd;
use KanopyaDemo::Config;

sub run {
    print "########################\n";
    print "# Kanopya Demo : setup #\n";
    print "########################\n";

    my $setup_file = $config->{setup_file};
    my $dir = getcwd();
    
    chdir '/opt/kanopya/scripts/install';
    if(not -e $setup_file) {
        print "$setup_file not found, exiting\n";
        exit(1);
    }

    system("invoke-rc.d mysql start");
    system("perl setup.pl < $setup_file");
    chdir $dir;
    return 0;
}

1;
