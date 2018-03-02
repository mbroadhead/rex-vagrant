package Rex::Vagrant;
use Rex::Commands;
use Rex::Config;

use strict;
use 5.008_005;
our $VERSION = '0.01';

our $VAGRANT_SSH_CONFIG_FOR;

sub import {
  my ( $class, $what, $addition ) = @_;
  $what =~ s/^-//;

  if ( $what =~ /^env(ironment)?$/ ) {
    $addition //= "vagrant";
    $class->setup_environment($addition);
  }
  elsif ( $what eq "groups" ) {
    $class->setup_ssh_config;
    $class->setup_groups;
  }
}

sub ssh_config {
  my ( $class, $refetch ) = @_;
  if ( $refetch || !defined $VAGRANT_SSH_CONFIG_FOR ) {
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
  my $class      = shift;
  my $ssh_config = $class->ssh_config;
  group $_ => $_ for keys %{$ssh_config};
  group "all" => keys %{$ssh_config};
}

sub setup_environment {
  my ( $class, $env_name ) = @_;
  environment $env_name => sub {

    $class->setup_ssh_config;
    $class->setup_groups;
  };
}

1;
__END__

=encoding utf-8

=head1 NAME

Rex::Vagrant - Blah blah blah

=head1 SYNOPSIS

  use Rex::Vagrant;

=head1 DESCRIPTION

Rex::Vagrant is

=head1 AUTHOR

Mitch Broadhead E<lt>mitch.broadhead@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Mitch Broadhead

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
