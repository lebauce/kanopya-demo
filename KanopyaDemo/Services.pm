package KanopyaDemo::Services;

use strict;
use warnings;
use KanopyaDemo::Config;
use Entity::ServiceTemplate;

sub run {
    
    print "####################################\n";
    print "# Kanopya Demo : services creation #\n";
    print "####################################\n";
    
    my $name = 'Web service';
    my $servicetemplate = Entity::ServiceTemplate->new(
                          service_name            => $name,
                          service_desc            => '',
                          hosting_policy_id       => $instances->{hosting}->{'Virtual Machine hosted on Openstack'}->id,
                          storage_policy_id       => $instances->{storage}->{'Block storage via ISCSI'}->id,
                          network_policy_id       => $instances->{network}->{'n1'}->id,
                          scalability_policy_id   => $instances->{scalability}->{'Scalable'}->id,
                          system_policy_id        => $instances->{system}->{'LAMP stack'}->id,
                          billing_policy_id       => $instances->{billing}->{'Poker web site'}->id,
                          orchestration_policy_id => $instances->{orchestration}->{'Rules'}->id,
                          # missing policy attributes
                          core                    => 1,
                          ram                     => 1073741824                          
                      );
    print "creating $name service\n";
    $instances->{templates}->{$name} = $servicetemplate;
    
    $name = 'HighAvailable VM';
    $servicetemplate = Entity::ServiceTemplate->new(
                          service_name            => $name,
                          service_desc            => '',
                          hosting_policy_id       => $instances->{hosting}->{'Virtual Machine hosted on Openstack'}->id,
                          storage_policy_id       => $instances->{storage}->{'Low NFS'}->id,
                          network_policy_id       => $instances->{network}->{'n2'}->id,
                          scalability_policy_id   => $instances->{scalability}->{'HA vm'}->id,
                          system_policy_id        => $instances->{system}->{'Simple linux'}->id,
                          billing_policy_id       => $instances->{billing}->{'Simple vm metering'}->id,
                          orchestration_policy_id => $instances->{orchestration}->{'Rules'}->id,
                          # missing policy attributes
                          core                    => 1,
                          ram                     => 1073741824
                      );
    print "creating $name service\n";
    $instances->{templates}->{$name} = $servicetemplate;
        
    return 0;
}

1;
