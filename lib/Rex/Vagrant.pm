package Rex::Vagrant;
use Rex::Commands;
use Rex::Config;

use strict;
use 5.008_005;
our $VERSION = '0.01';

our $VAGRANT_SSH_CONFIG_FOR;

sub import {
  my ( $class, @opts ) = @_;

  while ( my $feature = shift @opts ) {
    $feature =~ s/^-//;
    my $feature_opts = ref $opts[0] eq "HASH" ? shift @opts : {};
    if ( $feature =~ qr/^env(ironment)?$/ ) {
      $class->setup_environment(%$feature_opts);
    }
    elsif ( $feature =~ qr/^groups$/ ) {
      $class->setup_ssh_config;
      $class->setup_groups(%$feature_opts);
    }
  }
}

sub ssh_config {
  my ( $class, %opt ) = @_;
  if ( $opt{refetch} || !defined $VAGRANT_SSH_CONFIG_FOR ) {
    my @cfg = `vagrant ssh-config`;
    die "failed to obtain vagrant ssh-config!" unless $? == 0;
    $VAGRANT_SSH_CONFIG_FOR = { Rex::Config->_parse_ssh_config(@cfg) };
  }
  return $VAGRANT_SSH_CONFIG_FOR;
}

sub setup_ssh_config {
  my $class      = shift;
  my $ssh_config = $class->ssh_config;
  @Rex::Config::SSH_CONFIG_FOR{ keys %{$ssh_config} } = values %{$ssh_config};

  # @TODO: Set these based on values from $cfg and only if rex is using openssh
  Rex::Config->set_openssh_opt(
    StrictHostKeyChecking => "no",
    UserKnownHostsFile    => "/dev/null",
    LogLevel              => "QUIET"
  );
}

sub setup_groups {
  my ( $class, %opt ) = @_;
  my $ssh_config = $class->ssh_config;

  # Create the group with all hosts
  # Dont create the group if { all => undef } is supplied.
  if ( !exists $opt{all} || defined $opt{all} ) {
    my $name = $opt{all} || "all";
    group $name => keys %{$ssh_config};
  }

  # create group for each host
  group $_ => $_ for keys %{$ssh_config};
}

sub setup_environment {
  my ( $class, %opt ) = @_;
  my $name = $opt{name} // "vagrant";
  my $group_opts = $opt{groups} // {};
  environment $name => sub {
    $class->setup_ssh_config;
    $class->setup_groups( %{$group_opts} );
  };
}

1;
__END__

=encoding utf-8

=head1 NAME

Rex::Vagrant - Easily interact with your Vagrant boxes through Rex.

=head1 SYNOPSIS

  # Creates an environment named "vagrant" with the correct ssh auth for each
  # vagrant box in your Vagrantfile. When the environment is called, creates
  # one group per vagrant host and a group named "all" that contains all
  # vagrant host(s).
  use Rex::Vagrant -env;

  # Same as above but customize the environment name and the "all" group name
  use Rex::Vagrant -env =>
    { name => "my-env", groups => { all => "all-my-vagrant-boxes" } };

  # Create groups and correct auth for all vagrant hosts directly without using
  # an environment. This makes interacting with rex slow because it has to
  # obtain the vagrant ssh-config each time you run rex. To solve this, use an
  # environment instead.
  use Rex::Vagrant -groups;

  # Same as above but name the "all" group something else.
  use Rex::Vagrant -groups => { all => "all-my-vagrant-boxes" };

  # Instead of using import options, you can just call the class methods directly:
  use Rex::Vagrant;
  Rex::Vagrant->setup_groups( all => "all-my-vagrant-boxes" );
  Rex::Vagrant->setup_environment( name => "my-vagrant-env" );

=head1 DESCRIPTION

Rex::Vagrant is a module that makes it easy to interact with virtual machines created by Vagrant directly in Rex.

=head1 AUTHOR

Mitch Broadhead E<lt>mitch.broadhead@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Mitch Broadhead

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
