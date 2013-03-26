package KanopyaDemo::ServiceInstances;

use strict;
use warnings;
use KanopyaDemo::Config;

use Entity::ServiceProvider::Cluster;

sub run {
    
    # Himalaya Poker creation #
    himalaya_pocker_instance();
    
    # Himalaya CRM creation #
    himalaya_crm_instance();
    
    return 0;
}

sub himalaya_pocker_instance {
    my $name = 'HimalayaPoker';
    print "create $name service instance";

    my $operation = Entity::ServiceProvider::Cluster->create(
                        cluster_name         => $name,
                        cluster_desc         => '',
                        user_id              => $instances->{user}->id,
                        active               => 1,
                        service_template_id  => $instances->{templates}->{'Web service'}->id,
                        # missing policies/template attributes
                        systemimage_size     => 10 * 1024 *1024 *1024,
                        cluster_max_node     => 8,
                        cluster_basehostname => 'poker'                    
                 );  

    waitForWorkflow($operation);
    print "ok\n";
}

sub himalaya_crm_instance {
    my $name = 'HimalayaCRM';
    print "create $name service instance";

    my $operation = Entity::ServiceProvider::Cluster->create(
                        cluster_name         => $name,
                        cluster_desc         => '',
                        user_id              => $instances->{user}->id,
                        active               => 1,
                        service_template_id  => $instances->{templates}->{'HighAvailable VM'}->id,
                        # missing policies/template attributes
                        systemimage_size     => 10 * 1024 *1024 *1024,
                        cluster_basehostname => 'crm'
                 );

    waitForWorkflow($operation);
    print "ok\n";
}

1;
