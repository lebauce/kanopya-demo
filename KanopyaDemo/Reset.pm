package KanopyaDemo::Reset;

use strict;
use warnings;
use Data::Dumper;
use KanopyaDemo::Config;

# main function

sub run {
    print "######################################\n";
    print "# Kanopya Demo : reset infrastucture #\n";
    print "######################################\n";
        
    # stop processes
    kanopya_processes('stop');

    # delete db
    drop_kanopya_db();

    # remove nfs exports
    clean_nfs_exports();

    # stop middlewares
    kanopya_middlewares('stop');

    # find, umount and delete logical volumes
    my @lvs = get_kanopya_lvs();
    umount_lvs(@lvs);
    delete_lvs(@lvs);

    # remove directories
    delete_kanopya_dir();
    
    return 0;
}

# sub functions

sub kanopya_processes {
    my ($action) = @_;
    
    if($action ne 'start' && $action ne 'stop') {
        die "kanopya_processes: first argument must be 'start' or 'stop'";
    }
    for my $process (@{$config->{processes}}) {
        system("invoke-rc.d $process $action");
    }
}

sub kanopya_middlewares {
    my ($action) = @_;
    if($action ne 'start' && $action ne 'stop') {
        die "kanopya_middlewares: first argument must be 'start' or 'stop'";
    }
    for my $process (@{$config->{middlewares}}) {
        system("invoke-rc.d $process $action");
    }
}

sub get_kanopya_lvs {
    my $vg = $config->{volume_group_name};
    my $output = `lvs --noheadings -o lv_name,lv_attr --separator '|' $vg`;
    my @lvs = ();
    
    for my $lv (split('\n', $output)) {
        my ($lvname, $lvattr) = split('\|', $lv);
        $lvname =~ s/\s//g;
        push @lvs, { name => $lvname, attr => $lvattr };
    }
    return @lvs;
}

sub umount_lvs {
    my @lvs = @_;
    my $vg = $config->{volume_group_name};
    for my $lv (@lvs) {
        if($lv->{attr} =~ /o/) {
            my $lvpath = "/dev/$vg/".$lv->{name};
            print "umounting $lvpath\n";
            system("umount $lvpath");
        }
    }
}

sub delete_lvs {
    my @lvs = @_;
    my $vg = $config->{volume_group_name};
    for my $lv (@lvs) {
        my $lvpath = "/dev/$vg/".$lv->{name};
        print "deleting $lvpath\n";
        system("lvremove -f $lvpath 2> /dev/null");
    }
}

# database 

sub drop_kanopya_db {
    my $pwd = $config->{mysql_root_password};
    my $db = $config->{mysql_database_name};
    print "dropping kanopya database from mysql\n";
    system("mysql -u root -p$pwd -e 'DROP DATABASE $db'");
}

# directories

sub delete_kanopya_dir {
    for my $dir (@{$config->{directories}}) {
        system("[ -e $dir ] && rm -rf $dir");
    }
}

# NFS

sub clean_nfs_exports {
    system('exportfs -au');
    system("echo '' > /etc/exports");
}




1;
