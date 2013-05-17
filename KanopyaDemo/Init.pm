package KanopyaDemo::Init;

use strict;
use warnings;
use KanopyaDemo::Config;

use JSON;
use BaseDB;
use Entity::ServiceProvider::Cluster;
use Entity::User::Customer;
use Entity::Host;
use Entity::Operation;
use Entity::Component::Lvm2::Lvm2Vg;
use Entity::Container;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::Network;
use Entity::Poolip;
use Entity::Masterimage;
use EEntity;
use Kanopya::Tools::Register;

sub run {
    print "################################################\n";
    print "# Kanopya Demo : infrastructure initialization #\n";
    print "################################################\n";
    
    # authentification
    BaseDB->authenticate(login => $config->{login}, password => $config->{password});
    
    # retrieve kanopya cluster
    $instances->{kanopya} = Entity::ServiceProvider::Cluster->find(
                                hash => { cluster_name => 'kanopya' }
                            );

    # This is required to instance a EEntity from outside the executor
    my @hosts = $instances->{kanopya}->getHosts();
    my $kanopya_master = $hosts[0];
    EEntity->new(entity => $kanopya_master);

    $instances->{kanopya_master} = $kanopya_master->node;

    $instances->{kanopya}->setAttr(name  => "cluster_nameserver1",
                                   value => $config->{nameserver},
                                   save  => 1);

    # customer creation  
    customers_creation();
    
    # hosts registration 
    hosts_registration();
    
    # master images upload 
    masterimages_upload();
    
    # images repositories creation
    repositories_creation();
    
    # networks and poolips declaration
    networks_registration();
    
    return 0;
}

sub customers_creation {
    $instances->{customers} = {};
    while(my($name, $customer) = each %{$config->{customers}}) {
        print "create customer $name\n";
        my $user = Entity::User::Customer->new(%$customer);
        $instances->{customers}->{$name} = $user;
    }
}

sub hosts_registration {
    my $file = $config->{hosts};

    my $json = '';
    open (JSON, '<', $file);
    while (<JSON>) {
        $json .= $_;
    }

    my $hostmanager = $instances->{kanopya}->getHostManager();
    my $hosts = decode_json($json);

    for my $board (@{$hosts}) {
        print "registering a physical host " . $board->{serial_number} . "...";
        Kanopya::Tools::Register->registerHost(board => $board);
        print "ok\n";
    }
}

sub masterimages_upload {
    $instances->{masterimages} = {};
    while(my($img,$file) = each %{$config->{masterimages}}) {
        print "registering master image $file";
        my $operation = Entity::Masterimage->create(
                            file_path => $config->{masterimages_path} . "/" . $file,
                            keep_file => 1,
                        );

        waitForWorkflow($operation);
        
    }
}

sub repositories_creation {
    my $disk_manager = $instances->{kanopya}->getComponent(name => 'Lvm');
    my $nfsd_manager = $instances->{kanopya}->getComponent(name => 'Nfsd');
    
    while( my ($name, $size) = each %{$config->{repositories}}) {
        print "creating disk repository $name...";
        
        my $operation = $disk_manager->createDisk(
                            name       => $name,
                            size       => $size * 1024 * 1024 * 1024,
                            filesystem => "ext3",
                            vg_id      => Entity::Component::Lvm2::Lvm2Vg->find(
                                             hash => { lvm2_vg_name => $config->{volume_group_name} }
                                          )->id,
                        );
        
        waitForWorkflow($operation);

        my $container = Entity::Container->find(hash => { container_name => $name });

        print "exporting disk repository $name via nfs...";
        $operation = $nfsd_manager->createExport(
                         container      => $container,
                         export_name    => $name,
                         client_name    => "*",
                         client_options => "rw,sync,no_root_squash"
                     );
        waitForWorkflow($operation);
        
        $container = Entity::Container->find(hash => { container_name => $name });
        my @nfs_accesses = Entity::ContainerAccess::NfsContainerAccess->search(hash => {
                               container_id => $container->id
                           });
        my @nfss = grep {$_->export_manager_id != 0} @nfs_accesses;
        $instances->{$name} = $nfss[0];
    }
    $instances->{disk_manager} = $disk_manager;
    $instances->{nfsd_manager} = $nfsd_manager;
}

sub networks_registration {
    while( my ($name, $net) = each %{$config->{networks}}) {
        $instances->{networks}->{$name} = Entity::Network->new(
                       network_name    => $name,
                       network_addr    => $net->{network_addr},
                       network_netmask => $net->{network_netmask},
                       network_gateway => $net->{network_gateway}
                   );

        my $poolip = Entity::Poolip->new(
                         poolip_name       => $net->{poolip_name},
                         poolip_first_addr => $net->{poolip_first_addr},
                         poolip_size       => $net->{poolip_size},
                         network_id        => $instances->{networks}->{$name}->id,
                        );
    }
}

1;
