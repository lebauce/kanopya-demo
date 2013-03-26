package KanopyaDemo::Config;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw($config $instances waitForWorkflow);
 
# contain all the configuration
our $config = {
    processes => [ 'kanopya-front',
                   'kanopya-executor',
                   'kanopya-collector',
                   'kanopya-aggregator',
                   'kanopya-orchestrator' ],
                   
    middlewares => [ 'nfs-kernel-server',
                     'iscsitarget',
                     'isc-dhcp-server',
                     'mysql' ],
                     
    directories => [ '/var/log/kanopya',
                     '/var/lib/kanopya',
                     '/var/cache/kanopya',
                     '/tmp/kanopya-sessions' ],
                     
    volume_group_name => 'kanopya',
    
    mysql_root_password => 'Hedera@123',
    
    mysql_database_name => 'kanopya',
    
    setup_file => '/root/kanopyademo/scripts/setup.inputs',
    
    login => 'admin',
    
    password => 'K4n0pY4',
    
    customers => { 'Hernest' => {user_firstname => 'Hernest',
                                 user_lastname  => 'Big Foot',
                                 user_desc      => 'user demo context',
                                 user_login     => 'hernest',
                                 user_password  => 'hernest',
                                 user_email     => 'hernest.bigfoot@peak.tibet.com' },
                 },
                 
    hosts => [  { ram    => 8192,
                  core   => 2,
                  serial => 'FujitsuServer001',
                  desc   => 'Fujitsu rack server 001', 
                  ifaces => [ { name => "eth0",
                                mac  => "00:0a:e4:8a:51:6c",
                                pxe  => 1 }, 
                              { name => "eth1",
                                mac  => "00:0a:e4:8a:51:6d",
                                pxe  => 0, } 
                            ],
                },
                { ram    => 12288,
                  core   => 8,
                  serial => 'FujitsuBlade001',
                  desc   => 'Fujitsu blader server BX920S 001', 
                  ifaces => [ { name => "eth0",
                                mac  => "60:eb:69:8e:fe:8c",
                                pxe  => 1 }, 
                              { name => "eth1",
                                mac  => "60:eb:69:8e:fe:8d",
                                pxe  => 0, },
                              { name => "eth2",
                                mac  => "60:eb:69:8e:fe:8e",
                                pxe  => 0, }, 
                              { name => "eth3",
                                mac  => "60:eb:69:8e:fe:8f",
                                pxe  => 0, } 
                            ],
                },
                { ram    => 12288,
                  core   => 8,
                  serial => 'FujitsuBlade002',
                  desc   => 'Fujitsu blader server BX920S 002', 
                  ifaces => [ { name => "eth0",
                                mac  => "60:eb:69:8e:fe:54",
                                pxe  => 1 }, 
                              { name => "eth1",
                                mac  => "60:eb:69:8e:fe:55",
                                pxe  => 0, },
                              { name => "eth2",
                                mac  => "60:eb:69:8e:fe:56",
                                pxe  => 0, }, 
                              { name => "eth3",
                                mac  => "60:eb:69:8e:fe:57",
                                pxe  => 0, } 
                            ],
                },
                { ram    => 8192,
                  core   => 8,
                  serial => 'SMServer001',
                  desc   => 'SUPERMICRO rack server 001', 
                  ifaces => [ { name => "eth0",
                                mac  => "00:25:90:a5:13:aa",
                                pxe  => 1 }, 
                              { name => "eth1",
                                mac  => "00:25:90:a5:13:ab",
                                pxe  => 0, } 
                            ],
                },
                { ram    => 8192,
                  core   => 8,
                  serial => 'SMServer002',
                  desc   => 'SUPERMICRO rack server 002', 
                  ifaces => [ { name => "eth0",
                                mac  => "00:25:90:a4:97:58",
                                pxe  => 1 }, 
                              { name => "eth1",
                                mac  => "00:25:90:a4:97:59",
                                pxe  => 0, } 
                            ],
                },
            ],

    masterimage_files => { 'centos' => '/root/kanopyademo/masterimages/centos-6.3-opennebula3.tar.bz2',
                           'sles'   => '/root/kanopyademo/masterimages/sles-11-simple-host.tar.bz2',
                           'ubuntu' => '/root/kanopyademo/masterimages/ubuntu-precise-amd64.tar.bz2' },
                          
    repositories => { 'system_datastore'   => 1,
                      'openstack_fast_nfs' => 200,
                      'openstack_low_nfs'  => 200,
                      'opennebula_nfs'     => 100,
                      'glance_repository'  => 100,
                    },
                    
    networks => { 'Public access' => { network_addr    => '192.168.0.0',
                                       network_netmask => '255.255.255.0',
                                       network_gateway => '192.168.0.1',
                                       poolip_name     => 'Hederatech DMZ pool',
                                       poolip_first_addr => '192.168.0.100',
                                       poolip_size       => '50',
                                     }},
                                     
                 
};

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
