package KanopyaDemo::Config;

use strict;
use warnings;

use JSON;
use Hash::Merge;
use Exporter 'import';
our @EXPORT = qw($config $instances waitForWorkflow);
 
# contain all the configuration
our $config = {
    processes => [
        'kanopya-front',
        'kanopya-executor',
        'kanopya-collector',
        'kanopya-aggregator',
        'kanopya-rulesengine'
    ],
                   
    middlewares => [
        'nfs-kernel-server',
        'iscsitarget',
        'isc-dhcp-server',
        'mysql'
    ],
                     
    directories => [
        '/var/log/kanopya',
        '/var/lib/kanopya',
        '/var/cache/kanopya',
        '/tmp/kanopya-sessions'
    ],
                     
    volume_group_name => 'kanopya',
    
    mysql_root_password => 'Hedera@123',
    
    mysql_database_name => 'kanopya',
    
    setup_file => '/root/kanopyademo/scripts/setup.inputs',
    
    login => 'admin',
    
    password => 'K4n0pY4',
    
    customers => {
        'Hernest' => {
            user_firstname => 'Hernest',
            user_lastname  => 'Big Foot',
            user_desc      => 'user demo context',
            user_login     => 'hernest',
            user_password  => 'hernest',
            user_email     => 'hernest.bigfoot@peak.tibet.com'
        },
    },
                 
    hosts => "/root/kanopyademo/scripts/hosts.json",

    masterimages_path => '/root/kanopyademo/masterimages',
    
    masterimages => {
        'centos' => "centos-6.3-opennebula3.tar.bz2",
        'sles'   => 'sles-11-simple-host.tar.bz2',
        'ubuntu' => 'ubuntu-precise-amd64.tar.bz2'
    },
                          
    repositories => {
        'system_datastore'   => 1,
        'openstack_fast_nfs' => 200,
        'openstack_low_nfs'  => 200,
        'opennebula_nfs'     => 100,
        'glance_repository'  => 100,
    },
                    
    networks => {
        'Public access' => {
            network_addr      => '192.168.0.0',
            network_netmask   => '255.255.255.0',
            network_gateway   => '192.168.0.1',
            poolip_name       => 'Hederatech DMZ pool',
            poolip_first_addr => '192.168.0.100',
            poolip_size       => '50',
        }
    },

    admin_network_gateway => "10.0.0.1",

    nameserver => "192.168.10.254"
};

if (-e "config.json") {
    my $json = '';
    open (JSON, '<', 'config.json');
    while (<JSON>) {
        $json .= $_;
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $config = $merge->merge($config, decode_json($json));
}

# used to store instances created
our $instances = {};

sub waitForWorkflow {
    my ($op) = @_;
    while(1) {
        my $workflow = $op->getWorkflow;

        my $state = $workflow->state;
        if($state eq 'running') {
            print ".";
            sleep(5);
        } elsif($state =~ /(failed|cancelled)/) {
            print "bug on workflow execution !\n";
            exit(1);
        } elsif($state eq 'done') {
            print "ok\n";
            last;
        }
    }
}

1;
