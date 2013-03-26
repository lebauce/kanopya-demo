package KanopyaDemo::Policies;

use strict;
use warnings;
use KanopyaDemo::Config;

use ClassType::ComponentType;
use Entity::Network;
use Entity::Netconf;
use Entity::Masterimage;
use Entity::ContainerAccess;
use Entity::Component::Lvm2::Lvm2Vg;
use Entity::Policy::HostingPolicy;
use Entity::Policy::StoragePolicy;
use Entity::Policy::NetworkPolicy;
use Entity::Policy::SystemPolicy;
use Entity::Policy::ScalabilityPolicy;
use Entity::Policy::BillingPolicy;
use Entity::Policy::OrchestrationPolicy;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;
use Entity::CollectorIndicator;
use Entity::NodemetricCondition;
use Entity::Rule::NodemetricRule;

sub run {
    
    $instances->{networks}->{'admin'} = Entity::Network->find(hash => {network_name => 'admin'});
        
    # hosting policy #
    hosting_policies_creation();
    
    # storage policy #
    storage_policies_creation();
    
    # network policy #
    network_policies_creation();
    
    # system policy #
    system_policies_creation();
    
    # scalability policy #
    scalability_policies_creation();
    
    # billing policy #
    billing_policies_creation();
    
    # automation policy #
    automation_policies_creation();
    
    return 0;
}

sub hosting_policies_creation {
    my $name = 'Virtual Machine hosted on Opennebula';
    $instances->{hosting}->{$name} = Entity::Policy::HostingPolicy->new(
                                        policy_name     => $name,
                                        policy_desc     => 'Hosting policy for Opennebula vms',
                                        policy_type     => 'hosting',
                                        host_manager_id => $instances->{iaas}->{opennebula}->getComponent(category => 'HostManager')->id,
                                    );

    print "creating hosting policy : $name\n";


    $name = 'Virtual Machine hosted on Openstack';
    $instances->{hosting}->{$name} = Entity::Policy::HostingPolicy->new(
                                       policy_name     => $name,
                                       policy_desc     => 'Hosting policy for Openstack vms',
                                       policy_type     => 'hosting',
                                       host_manager_id => $instances->{iaas}->{openstack}->getComponent(category => 'HostManager')->id,
                                    );
    print "creating hosting policy : $name\n";
}

sub storage_policies_creation {
    my $fileimage = $instances->{iaas}->{openstack}->getComponent(name => 'Fileimagemanager');
    my $lvm = $instances->{kanopya}->getComponent(name => 'Lvm');
    my $iscsitarget = $instances->{kanopya}->getComponent(name => 'Iscsitarget');
    my $nfsd = $instances->{kanopya}->getComponent(name  => 'Nfsd');

    my $name = 'Fast NFS';
    $instances->{storage}->{$name} = Entity::Policy::StoragePolicy->new(
                                    policy_name         => $name,
                                    policy_desc         => 'High Performance NFS repository',
                                    policy_type         => 'storage',
                                    disk_manager_id     => $fileimage->id,
                                    container_access_id => Entity::ContainerAccess->find(
                                                               hash => { container_access_export => '10.0.0.1:/nfsexports/openstack_fast_nfs' } 
                                                           )->id,
                                    image_type          => "qcow2",
                                    export_manager_id   => $fileimage->id,
                                );

    print "creating storage policy : $name\n";

    $name = 'Block storage via ISCSI';
    $instances->{storage}->{$name} = Entity::Policy::StoragePolicy->new(
                                        policy_name         => $name,
                                        policy_desc         => '',
                                        policy_type         => 'storage',
                                        disk_manager_id     => $lvm->id,
                                        vg_id               => Entity::Component::Lvm2::Lvm2Vg->find(hash => {lvm2_vg_name => $config->{volume_group_name}})->id,
                                        export_manager_id   => $instances->{iscsi_manager}->id,
                                        iscsi_portals       => $instances->{iscsi_portal_ids}
                                    );
    print "creating storage policy : $name\n";

    $name = 'Low NFS';
    $instances->{storage}->{$name} = Entity::Policy::StoragePolicy->new(
                                        policy_name         => $name,
                                        policy_desc         => 'Low Performance NFS repository',
                                        policy_type         => 'storage',
                                        disk_manager_id     => $fileimage->id,
                                        container_access_id => Entity::ContainerAccess->find(
                                                                   hash => { container_access_export => '10.0.0.1:/nfsexports/openstack_low_nfs' }
                                                               )->id,
                                        image_type          => 'qcow2',
                                        export_manager_id   => $fileimage->id,
                                    );
    print "creating storage policy : $name\n";
}

sub network_policies_creation {
    my $adminnetconf = Entity::Netconf->find(hash => { netconf_name => 'Kanopya admin' });
    
    #my $dmznetconf = Entity::Netconf->find(hash => { netconf_name => 'Hederatech DMZ access' });

    my $name = "n1";    
    $instances->{network}->{$name} = Entity::Policy::NetworkPolicy->new(
                               policy_name         => $name,
                               policy_desc         => 'admin and public interfaces',
                               policy_type         => 'network',
                               cluster_nameserver1 => '192.168.10.254',
                               cluster_nameserver2 => '192.168.10.254',
                               cluster_domainname  => 'my.domain.com',
                               default_gateway_id  => $instances->{networks}->{admin}->id,
                               interfaces          => [ { netconfs => [ $instances->{adminnetconf}->id ] },
                                                       # { netconfs => [ $dmznetconf->id ]   },
                                                      ]
                          );

    print "creating network policy : $name\n";


    $name = "n2";
    $instances->{network}->{$name} = Entity::Policy::NetworkPolicy->new(
                               policy_name         => $name,
                               policy_desc         => 'admin access only',
                               policy_type         => 'network',
                               cluster_nameserver1 => '192.168.10.254',
                               cluster_nameserver2 => '192.168.10.254',
                               cluster_domainname  => 'my.domain.com',
                               default_gateway_id  => $instances->{networks}->{admin}->id,
                               interfaces          => [ { netconfs => [ $instances->{adminnetconf}->id ] } ]
                           );

    print "creating network policy : $name\n";
}

sub system_policies_creation {
    my $name = "Empty vm";    
    $instances->{system}->{$name} = Entity::Policy::SystemPolicy->new(
                policy_name           => $name,
                policy_desc           => '',
                policy_type           => 'system',
                cluster_si_shared     => 0,
                cluster_si_persistent => 1,
            );

    print "creating system policy : $name\n";


    $name = "LAMP stack";
    $instances->{system}->{$name} = Entity::Policy::SystemPolicy->new(
                policy_name           => $name,                   
                policy_desc           => '',
                policy_type           => 'system',
                cluster_si_shared     => 0,
                cluster_si_persistent => 1,
                masterimage_id        => Entity::Masterimage->find(
                                             hash => { masterimage_name => 'Ubuntu Precise - Simple host' }
                                         )->id,
                components            => {
                    apache     => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Apache'})->id },
                    keepalived => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Keepalived'})->id },
                    php        => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Php'})->id },
                    mysql      => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Mysql'})->id },
                    memcached  => { component_type => ClassType::ComponentType->find(hash => {component_name => 'Memcached'})->id },
                }
            );

    print "creating system policy : $name\n";

    $name = "Simple linux";
    $instances->{system}->{$name} = Entity::Policy::SystemPolicy->new(
                policy_name           => $name,
                policy_desc           => '',
                policy_type           => 'system',
                cluster_si_shared     => 0,
                cluster_si_persistent => 1,

            );
    print "creating system policy : $name\n";
}

sub scalability_policies_creation {
    my $name = "Simple vm";
    $instances->{scalability}->{$name} = Entity::Policy::ScalabilityPolicy->new(
                                            policy_name      => $name,
                                            policy_desc      => '',
                                            policy_type      => 'scalability',
                                            cluster_min_node => 1,
                                            cluster_max_node => 1,
                                            cluster_priority => 300    
                                        );

    print "creating scalability policy : $name\n";

    $name = "HA vm";
    $instances->{scalability}->{$name} = Entity::Policy::ScalabilityPolicy->new(
                                            policy_name      => $name,
                                            policy_desc      => '',
                                            policy_type      => 'scalability',
                                            cluster_min_node => 2,
                                            cluster_max_node => 2,
                                            cluster_priority => 500
                                        );
    print "creating scalability policy : $name\n";

    $name = "Scalable";
    $instances->{scalability}->{$name} = Entity::Policy::ScalabilityPolicy->new(
                                            policy_name      => $name,
                                            policy_desc      => '',
                                            policy_type      => 'scalability',
                                            cluster_min_node => 1,
                                            cluster_priority => 600
                                        );
    print "creating scalability policy : $name\n";
}

sub billing_policies_creation {
    my $name = "Simple vm metering";
    $instances->{billing}->{$name} = Entity::Policy::BillingPolicy->new(
                                        policy_name => $name,
                                        policy_desc => '',
                                        policy_type => 'billing',
                                        limits      => { l1 => { start => '01/01/2013', ending => '31/12/2013', soft => 1, value => 2 },
                                                         l2 => { start => '01/01/2013', ending => '31/12/2013', soft => 1, value => 4 },
                                                         l3 => { start => '01/01/2013', ending => '31/12/2013', soft => 0, value => 8 }, 
                                                       }
                                    );

    print "creating billing policy : $name\n";

    $name = "Poker web site";
    $instances->{billing}->{$name} = Entity::Policy::BillingPolicy->new(
                                        policy_name => $name,
                                        policy_desc => '',
                                        policy_type => 'billing',
                                        limits      => { l1 => { start => '01/01/2013', ending => '31/12/2013', soft => 0, type => 'ram', value => 2 },
                                                         l2 => { start => '01/01/2013', ending => '31/12/2013', soft => 0, type => 'ram', value => 4 },
                                                       }
                                    );
    print "creating billing policy : $name\n";
}

sub automation_policies_creation {
    my $serviceprovider = Entity::ServiceProvider->new();
    my $collector = $instances->{kanopya}->getComponent(name => 'Kanopyacollector');
    $serviceprovider->addManager(manager_id => $collector->id, 
                                 manager_type => 'CollectorManager');
    
    my $workflow_manager = $instances->{kanopya}->getComponent(name => 'Kanopyaworkflow');
    my $indic = Entity::CollectorIndicator->find(hash =>
                    { collector_manager_id => $collector->id,
                      'indicator.indicator_label' => 'mem/Available' }
                );

    # service metrics
    my $cm1 = Entity::Clustermetric->new(
                  clustermetric_service_provider_id       => $serviceprovider->id,
                  clustermetric_indicator_id              => $indic->id,
                  clustermetric_label                     => 'Total Memory Available',
                  clustermetric_statistics_function_name  => 'sum',
                  clustermetric_window_time               => '600',
             );

    my $cm2 = Entity::Clustermetric->new(
                  clustermetric_service_provider_id       => $serviceprovider->id,
                  clustermetric_indicator_id              => $indic->id,
                  clustermetric_label                     => 'Mean Memory Available',
                  clustermetric_statistics_function_name  => 'mean',
                  clustermetric_window_time               => '600',
             );

    my $cm3 = Entity::Clustermetric->new(
                  clustermetric_service_provider_id       => $serviceprovider->id,
                  clustermetric_indicator_id              => $indic->id,
                  clustermetric_label                     => 'Memory Available Variance',
                  clustermetric_statistics_function_name  => 'variance',
                  clustermetric_window_time               => '600',
             );

    # service metric combinations
    my $acomb1 = Entity::Combination::AggregateCombination->new(
                    service_provider_id           => $serviceprovider->id,
                    aggregate_combination_label   => 'Total Memory Available',
                    aggregate_combination_formula => 'id'.$cm1->id
                );

    my $acomb2 = Entity::Combination::AggregateCombination->new(
                    service_provider_id           => $serviceprovider->id,
                    aggregate_combination_label   => 'Mean Memory Available',
                    aggregate_combination_formula => 'id'.$cm2->id
                );

    my $acomb3 = Entity::Combination::AggregateCombination->new(
                    service_provider_id           => $serviceprovider->id,
                    aggregate_combination_label   => 'Memory Available Variance',
                    aggregate_combination_formula => 'id'.$cm3->id
                );


    # node metric 
    my $nmcomb1 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $serviceprovider->id,
        nodemetric_combination_label    => 'Memory Available',
        nodemetric_combination_formula  => 'id'.$indic->id
    );

    $indic = Entity::CollectorIndicator->find(hash =>
                    { collector_manager_id => $collector->id,
                      'indicator.indicator_label' => 'cpu/Idle' }
             );

    my $nmcomb2 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $serviceprovider->id,
        nodemetric_combination_label    => 'CPU Idle',
        nodemetric_combination_formula  => 'id'.$indic->id
    );

    $indic = Entity::CollectorIndicator->find(hash =>
                    { collector_manager_id => $collector->id,
                      'indicator.indicator_label' => 'network interface/In Octets' }
             );

    my $nmcomb3 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $serviceprovider->id,
        nodemetric_combination_label    => 'Network interface input',
        nodemetric_combination_formula  => 'id'.$indic->id
    );

    # Node conditions
    my $nmcond1 = Entity::NodemetricCondition->new(
                      left_combination_id                 => $nmcomb1->id,
                      nodemetric_condition_label          => 'Memory available vs total',
                      nodemetric_condition_comparator     => '<',
                      right_combination_id                => $acomb1->id,
                      nodemetric_condition_service_provider_id => $serviceprovider->id,
    );

    my $nmcond2 = Entity::NodemetricCondition->new(
                      left_combination_id                 => $nmcomb2->id,
                      nodemetric_condition_label          => 'MEmavailable',
                      nodemetric_condition_comparator     => '<',
                      nodemetric_condition_threshold      => 526000,
                      nodemetric_condition_service_provider_id => $serviceprovider->id,
    );

    # Node rules
    my $nmr1 = Entity::Rule::NodemetricRule->new(
                formula             => 'id'.$nmcond1->id,
                rule_name           => 'Memory available vs total',
                description         => '',
                state               => 'enabled',
                service_provider_id => $serviceprovider->id,
    );

    my $nmr2 = Entity::Rule::NodemetricRule->new(
                formula             => 'id'.$nmcond2->id,
                rule_name           => 'MEmavailable',
                description         => '',
                state               => 'enabled',
                service_provider_id => $serviceprovider->id,
    );


    my $name = "Rules";
    $instances->{orchestration}->{$name} = Entity::Policy::OrchestrationPolicy->new(
                                              policy_name         => $name,
                                              policy_desc         => '',
                                              policy_type         => 'orchestration',
                                              orchestration_service_provider_id => $serviceprovider->id 
                                          );

    print "creating automation policy : $name\n";
}

1;
