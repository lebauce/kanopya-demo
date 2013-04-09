package KanopyaDemo::IAAS;

use strict;
use warnings;
use KanopyaDemo::Config;

use EEntity;
use Entity::User;
use Entity::Poolip;
use Entity::NetconfRole;
use Entity::Netconf;
use Entity::Component::Iscsi::IscsiPortal;
use NetconfPoolip;
use Entity::Masterimage;
use Entity::ServiceProvider::Cluster;
use ClassType::ComponentType;
use Entity::Component::Linux::LinuxMount;

sub run {
    print "######################################\n";
    print "# Kanopya Demo : IAAS initialization #\n";
    print "######################################\n";
    
      
    my $kanopya = $instances->{kanopya};
    $instances->{user} = Entity::User->find(hash => { user_login => 'admin' });
    $instances->{physical_hoster} = $kanopya->getHostManager();

    $instances->{iscsi_manager} = EEntity->new(
                                      entity => $kanopya->getComponent(name => "Iscsitarget")
                                  );
                        
    $instances->{admin_poolip} = Entity::Poolip->find(hash => { poolip_name => 'kanopya_admin' });
    $instances->{vms_role} = Entity::NetconfRole->find(hash => { netconf_role_name => "vms" });
    $instances->{adminnetconf} = Entity::Netconf->find(
                                     hash => { netconf_name => "Kanopya admin" }
                                 );
    $instances->{iscsi_portal_ids} = [];
    for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $instances->{iscsi_manager}->id })) {
        push @{$instances->{iscsi_portal_ids}}, $portal->id;
    }
    
    # Opennebula IAAS creation #
    
    opennebula_iaas_creation();
    
    # Openstack IAAS creation #
    
    openstack_iaas_creation();
    
    # iaas_monitoring
    iaas_monitoring_definition();

    return 0;
}

sub opennebula_iaas_creation {
    print "create opennebula iaas...";

    my $vms_on_netconf = Entity::Netconf->create(netconf_name    => "opennebula_vms",
                                             netconf_role_id => $instances->{vms_role}->id);

    NetconfPoolip->new(netconf_id => $vms_on_netconf->id,
                       poolip_id  => $instances->{admin_poolip}->id);

    my $masterimage = Entity::Masterimage->find(
        hash => { masterimage_name => 'CentOS 6.3 with OpenNebula 3.6'}
    );

    my $operation = Entity::ServiceProvider::Cluster->create(
                       cluster_name         => 'Opennebula',
                       cluster_basehostname => 'one',
                       masterimage_id       => $masterimage->id,
                       user_id              => $instances->{user}->id,
                       default_gateway_id   => ($instances->{adminnetconf}->poolips)[0]->network->id,      
                       active               => 1,
                       cluster_min_node     => 1,
                       cluster_max_node      => 3,
                       cluster_priority      => "100",
                       cluster_si_shared     => 0,
                       cluster_si_persistent => 1,
                       cluster_domainname    => 'my.domain',
                       cluster_nameserver1   => '192.168.10.254',
                       cluster_nameserver2   => '194.158.122.10',
                       managers             => {
                           host_manager => {
                               manager_id     => $instances->{physical_hoster}->id,
                               manager_type   => "HostManager",
                               manager_params => {
                                   cpu => 1,
                                   ram => 2*1024*1024,
                               },
                           },
                           disk_manager => {
                               manager_id     => $instances->{disk_manager}->id,
                               manager_type   => "DiskManager",
                               manager_params => {
                                  vg_id => 1,
                                  systemimage_size => 4 * 1024 * 1024 * 1024,
                               },
                           },
                           export_manager => {
                              manager_id     => $instances->{iscsi_manager}->id,
                              manager_type   => "ExportManager",
                              manager_params => {
                                  iscsi_portals => $instances->{iscsi_portal_ids},
                              },
                           },
                       },
                       interfaces => {
                           admin => {
                               interface_netconfs  => { $instances->{adminnetconf}->id => $instances->{adminnetconf}->id },
                           },
                           vms => {
                               interface_netconfs => { $vms_on_netconf->id => $vms_on_netconf->id },
                           },
                       },   
                       components => {
                           'opennebula' => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Opennebula'})->id, 
                           },
                           'kvm'        => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Kvm'})->id,
                           },  
                           'fileimagemanager' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Fileimagemanager'})->id,
                           }
                       }
                  );

    waitForWorkflow($operation);
    
    my $opennebula = Entity::ServiceProvider::Cluster->find(
                         hash => { cluster_name => 'Opennebula'}
                     );
    $instances->{iaas}->{opennebula} = $opennebula;
    
                     
    # configuring opennebula #
    my $virtualization = $opennebula->getComponent(name => 'Opennebula');
    my $vmm = $opennebula->getComponent(name => 'Kvm');
    
    Entity::Component::Linux::LinuxMount->new(
        linux_id               => $opennebula->getComponent(category => 'System')->id,
        linux_mount_device     => '/dev/sda',
        linux_mount_point      => 'none',
        linux_mount_filesystem => 'swap',
        linux_mount_options    => 'sw',
        linux_mount_dumpfreq   => 0,
        linux_mount_passnum    => 0  
    );
    
    $vmm->setConf(conf => { iaas_id => $virtualization->id });
    $virtualization->setConf(conf => {
        image_repository_path    => "/srv/cloud/images",
        opennebula3_repositories => [ {
            container_access_id  => $instances->{opennebula_nfs}->id,
            repository_name      => 'image_repo'
        }, {
            container_access_id  => $instances->{system_datastore}->id,
            repository_name      => 'system'
        } ],
        hypervisor               => "kvm"
    } );

}

sub openstack_iaas_creation {
    print "create openstack iaas...";

    my $vms_os_netconf = Entity::Netconf->create(netconf_name    => "openstack_vms",
                                                 netconf_role_id => $instances->{vms_role}->id);

    NetconfPoolip->new(netconf_id => $vms_os_netconf->id,
                       poolip_id  => $instances->{admin_poolip}->id);

    my $masterimage = Entity::Masterimage->find(
                         hash => { masterimage_name => 'Ubuntu Precise - Simple host'}
                      );

    my $operation = Entity::ServiceProvider::Cluster->create(
                       cluster_name         => 'Openstack',
                       cluster_basehostname => 'controller',
                       masterimage_id       => $masterimage->id,
                       user_id              => $instances->{user}->id,
                       default_gateway_id   => ($instances->{adminnetconf}->poolips)[0]->network->id,
                       active               => 1,
                       cluster_min_node     => 1,
                       cluster_max_node      => 3,
                       cluster_priority      => "100",
                       cluster_si_shared     => 0,
                       cluster_si_persistent => 1,
                       cluster_domainname    => 'my.domain',
                       cluster_nameserver1   => '192.168.10.254',
                       cluster_nameserver2   => '194.158.122.10',
                       managers             => {
                           host_manager => {
                               manager_id     => $instances->{physical_hoster}->id,
                               manager_type   => "HostManager",
                               manager_params => {
                                   cpu => 1,
                                   ram => 2*1024*1024,
                               },
                           },
                           disk_manager => {
                               manager_id     => $instances->{disk_manager}->id,
                               manager_type   => "DiskManager",
                               manager_params => {
                                  vg_id => 1,
                                  systemimage_size => 4 * 1024 * 1024 * 1024,
                               },
                           },
                           export_manager => {
                              manager_id     => $instances->{iscsi_manager}->id,
                              manager_type   => "ExportManager",
                              manager_params => {
                                  iscsi_portals => $instances->{iscsi_portal_ids},
                              },
                           },
                       },
                       interfaces => {
                           admin => {
                               interface_netconfs  => { $instances->{adminnetconf}->id => $instances->{adminnetconf}->id },
                           },
                           vms => {
                               interface_netconfs => { $vms_os_netconf->id => $vms_os_netconf->id },
                           },
                       },
                       components => {
                           'mysql' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Mysql'})->id,
                           },
                           'amqp' => { 
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Amqp'})->id
                           },
                           'keystone' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Keystone'})->id,
                           },
                           'novacontroller' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'NovaController'})->id,
                               component_configuration => {
                                   overcommitment_cpu_factor    => 1,
                                   overcommitment_memory_factor => 1
                               }
                           },
                           'glance' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Glance'})->id,
                           },
                           'quantum' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Quantum'})->id,
                           },
                           'fileimagemanager' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'Fileimagemanager'})->id,
                           }
                       }
                    );


    waitForWorkflow($operation);

    my $openstack = Entity::ServiceProvider::Cluster->find(
                    hash => { cluster_name => 'Openstack' }
                );
    $instances->{iaas}->{openstack} = $openstack;
    
    # Configuring OpenStack #

    my $sql = $openstack->getComponent(name => 'Mysql');
    my $amqp = $openstack->getComponent(name => 'Amqp');
    my $keystone = $openstack->getComponent(name => 'Keystone');
    my $nova_controller = $openstack->getComponent(name => "NovaController");
    my $glance = $openstack->getComponent(name => "Glance");
    my $quantum = $openstack->getComponent(name => "Quantum");

    Entity::Component::Linux::LinuxMount->new(
        linux_id               => $openstack->getComponent(category => 'System')->id,
        linux_mount_device     => '/dev/sda',
        linux_mount_point      => 'none',
        linux_mount_filesystem => 'swap',
        linux_mount_options    => 'sw',
        linux_mount_dumpfreq   => 0,
        linux_mount_passnum    => 0
    );

    Entity::Component::Linux::LinuxMount->new(
        linux_id               => $openstack->getComponent(category => 'System')->id,
        linux_mount_device     => $instances->{kanopya_master}->adminIp . ':/nfsexports/glance_repository',
        linux_mount_point      => '/var/lib/glance/images',
        linux_mount_filesystem => 'nfs',
        linux_mount_options    => 'defaults',
        linux_mount_dumpfreq   => 0,
        linux_mount_passnum    => 0
    );

    $keystone->setConf(conf => {
        mysql5_id   => $sql->id,
    });

    $nova_controller->setConf(conf => {
        mysql5_id    => $sql->id,
        keystone_id  => $keystone->id,
        amqp_id      => $amqp->id,
        repositories => [ { "repository_name" => "ImageRepository",
                            "container_access_id" => $instances->{'openstack_fast_nfs'}->id } ],
    });

    $glance->setConf(conf => {
        mysql5_id          => $sql->id,
        nova_controller_id => $nova_controller->id
    });

    $quantum->setConf(conf => {
        mysql5_id          => $sql->id,
        nova_controller_id => $nova_controller->id
    });    

    $operation = Entity::ServiceProvider::Cluster->create(
                       cluster_name         => 'Compute',
                       cluster_basehostname => 'compute',
                       masterimage_id       => $masterimage->id,
                       user_id              => $instances->{user}->id,
                       default_gateway_id   => ($instances->{adminnetconf}->poolips)[0]->network->id,
                       active               => 1,
                       cluster_min_node     => 1,
                       cluster_max_node      => 3,
                       cluster_priority      => "100",
                       cluster_si_shared     => 0,
                       cluster_si_persistent => 1,
                       cluster_domainname    => 'my.domain',
                       cluster_nameserver1   => '192.168.10.254',
                       cluster_nameserver2   => '194.158.122.10',
                       managers             => {
                           host_manager => {
                               manager_id     => $instances->{physical_hoster}->id,
                               manager_type   => "HostManager",
                               manager_params => {
                                   cpu => 1,
                                   ram => 2*1024*1024,
                               },
                           },
                           disk_manager => {
                               manager_id     => $instances->{disk_manager}->id,
                               manager_type   => "DiskManager",
                               manager_params => {
                                  vg_id => 1,
                                  systemimage_size => 4 * 1024 * 1024 * 1024,
                               },
                           },
                           export_manager => {
                              manager_id     => $instances->{iscsi_manager}->id,
                              manager_type   => "ExportManager",
                              manager_params => {
                                  iscsi_portals => $instances->{iscsi_portal_ids},
                              },
                           },
                       },
                       interfaces => {
                           admin => {
                               interface_netconfs  => { $instances->{adminnetconf}->id => $instances->{adminnetconf}->id },
                           },
                           vms => {
                               interface_netconfs => { $vms_os_netconf->id => $vms_os_netconf->id },
                           },
                       },
                       components => {
                           'novacompute' => {
                               component_type => ClassType::ComponentType->find(hash => {component_name => 'NovaCompute'})->id,
                               component_configuration => {
                                   mysql5_id          => $sql->id,
                                   nova_controller_id => $nova_controller->id,
                                   iaas_id            => $nova_controller->id
                               }
                           },
                       }
                    );


    waitForWorkflow($operation);

    my $compute = Entity::ServiceProvider::Cluster->find(
                      hash => { cluster_name => 'Compute' }
                  );
    $instances->{iaas}->{compute} = $compute;

    Entity::Component::Linux::LinuxMount->new(
        linux_id               => $compute->getComponent(category => 'System')->id,
        linux_mount_device     => '/dev/sda',
        linux_mount_point      => 'none',
        linux_mount_filesystem => 'swap',
        linux_mount_options    => 'sw',
        linux_mount_dumpfreq   => 0,
        linux_mount_passnum    => 0
    );

    Entity::Component::Linux::LinuxMount->new(
        linux_id               => $compute->getComponent(category => 'System')->id,
        linux_mount_device     => $instances->{kanopya_master}->adminIp . ':/nfsexports/openstack_fast_nfs',
        linux_mount_point      => '/var/lib/nova/instances',
        linux_mount_filesystem => 'nfs',
        linux_mount_options    => 'defaults',
        linux_mount_dumpfreq   => 0,
        linux_mount_passnum    => 0
    );

    $operation = Entity::ServiceProvider::Cluster->create(
                       cluster_name         => 'VSphere',
                       cluster_basehostname => 'vsphere',
                       masterimage_id       => $masterimage->id,
                       user_id              => $instances->{user}->id,
                       default_gateway_id   => ($instances->{adminnetconf}->poolips)[0]->network->id,
                       active               => 1,
                       cluster_min_node     => 1,
                       cluster_max_node      => 3,
                       cluster_priority      => "100",
                       cluster_si_shared     => 0,
                       cluster_si_persistent => 1,
                       cluster_domainname    => 'my.domain',
                       cluster_nameserver1   => '192.168.10.254',
                       cluster_nameserver2   => '194.158.122.10',
                       managers             => {
                           host_manager => {
                               manager_id     => $instances->{physical_hoster}->id,
                               manager_type   => "HostManager",
                               manager_params => {
                                   cpu => 1,
                                   ram => 2*1024*1024,
                               },
                           },
                           disk_manager => {
                               manager_id     => $instances->{disk_manager}->id,
                               manager_type   => "DiskManager",
                               manager_params => {
                                  vg_id => 1,
                                  systemimage_size => 4 * 1024 * 1024 * 1024,
                               },
                           },
                           export_manager => {
                              manager_id     => $instances->{iscsi_manager}->id,
                              manager_type   => "ExportManager",
                              manager_params => {
                                  iscsi_portals => $instances->{iscsi_portal_ids},
                              },
                           },
                       },
                       interfaces => {
                           admin => {
                               interface_netconfs  => { $instances->{adminnetconf}->id => $instances->{adminnetconf}->id },
                           },
                           vms => {
                               interface_netconfs => { $vms_os_netconf->id => $vms_os_netconf->id },
                           },
                       },
                       components => {
                           'opennebula' => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Opennebula'})->id,
                           },
                       }
                    );

    waitForWorkflow($operation);
}

sub iaas_monitoring_definition {
    my $monitor = $instances->{kanopya}->getComponent(name => 'Kanopyacollector');

    my $indicators_label = [
        'mem/Total',    'mem/Available',
        'mem/Buffered', 'mem/Cached',
        'cpu/User',     'cpu/Wait',
        'cpu/Nice',     'cpu/System',
        'cpu/Kernel',   'cpu/Interrupt',
        'cpu/Idle'];    

    my @indicators = $monitor->searchRelated(
        filters => ['collector_indicators'],
        hash    => { 'indicator.indicator_label' => {
                        -in => $indicators_label }
                   }
     );

    for my $iaas ('opennebula','openstack') {
        for my $i (@indicators) {
            Entity::Combination::NodemetricCombination->new(
                    nodemetric_combination_label   => $i->indicator->indicator_label,
                    nodemetric_combination_formula => 'id'.$i->id,
                    service_provider_id            => $instances->{iaas}->{$iaas}->id,
            );
        }
    }
}


1;
