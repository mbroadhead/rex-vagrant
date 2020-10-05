package Rex::Vagrant;
use Rex::Commands;
use Rex::Config;
use Path::Tiny ();
use Data::Dumper;

use strict;
use 5.008_005;
our $VERSION = '0.03';

our (
  $VAGRANT_SSH_CONFIG_FOR,
  $cache_ssh_config,
  $cache_timeout,
);

# Anytime you import Rex::Config it re-reads the default ssh config file and
# stomps on our custom settings. To prevent this, we add a monkey-patch that
# re-adds our custom vagrant ssh-config anytime this module gets imported.
my $rex_config_import = \&Rex::Config::import;
*Rex::Config::import = sub {
  $rex_config_import->(@_);
  if ( defined $VAGRANT_SSH_CONFIG_FOR ) {
    @Rex::Config::SSH_CONFIG_FOR{ keys %$VAGRANT_SSH_CONFIG_FOR } =
      values %$VAGRANT_SSH_CONFIG_FOR;
  }
};

sub import {
  my ( $class, @opts ) = @_;

  my ($env_opts, $group_opts);

  while ( my $feature = shift @opts ) {
    $feature =~ s/^-//;
    my $feature_opts = ref $opts[0] eq "HASH" ? shift @opts : {};
    if ( $feature =~ qr/^env(ironment)?$/ ) {
      $env_opts = $feature_opts;
    }
    elsif ( $feature =~ qr/^groups$/ ) {
      $group_opts = $feature_opts;
    }
    elsif ($feature =~ qr/^cache$/) {
      $cache_ssh_config = $feature_opts->{enabled};
      $cache_timeout = $feature_opts->{timeout};
    }
  }

  $class->setup_environment(%$env_opts) if defined $env_opts;
  $class->setup_groups(%$group_opts) if defined $group_opts;

}

sub vagrant_ssh_config {
  my $class = shift;

  return $VAGRANT_SSH_CONFIG_FOR if defined $VAGRANT_SSH_CONFIG_FOR;

  die
    "\$::rexfile not defined. This module should only be used inside a Rexfile!"
    unless defined $::rexfile;

  my $app_dir = Path::Tiny::path($::rexfile)->parent->absolute;

  if ($cache_ssh_config) {
    my $vagrant_dir = $app_dir->child('.vagrant');
    die "Cannot cache `vagrant ssh-config`: no such directory: $vagrant_dir."
      unless $vagrant_dir->is_dir;
    $vagrant_dir->child('.rex')->mkpath;
    my $cache_file = $vagrant_dir->child('.rex/ssh-config');
    if (
      !$cache_file->is_file
      || ( defined $cache_timeout
        && (time - $cache_file->stat->mtime) >= $cache_timeout )
      )
    {
      my @cfg = `cd $app_dir && vagrant ssh-config`;
      $cache_file->spew(@cfg);
      return $VAGRANT_SSH_CONFIG_FOR = { Rex::Config->_parse_ssh_config(@cfg) };
    }
    else {
      return $VAGRANT_SSH_CONFIG_FOR = { Rex::Config->_parse_ssh_config($cache_file->lines) };
    }
  }

  my @cfg = `cd $app_dir && vagrant ssh-config`;
  return $VAGRANT_SSH_CONFIG_FOR = { Rex::Config->_parse_ssh_config(@cfg) };
}

sub setup_ssh_config {
  my ($class, %opt) = @_;
  my $ssh_config = $class->vagrant_ssh_config(%opt);
  for my $host (keys %$ssh_config) {
    $Rex::Config::SSH_CONFIG_FOR{$host} = $ssh_config->{$host};
  }

  # @TODO: Set these based on values from $cfg and only if rex is using openssh
  # Rex::Config->set_openssh_opt(
  #   StrictHostKeyChecking => "no",
  #   UserKnownHostsFile    => "/dev/null",
  #   LogLevel              => "QUIET"
  # );
}

sub setup_groups {
  my ( $class, %opt ) = @_;
  my $ssh_config = $class->vagrant_ssh_config(%opt);

  $class->setup_ssh_config();

  # We have to create groups that point to the host from the ssh config, not
  # the hostname. That way rex can find the ssh config for it.
  my %groups = map { $_ => $_ } keys %$ssh_config;

  # Create the group with all hosts
  # Dont create the group if { all => undef } is supplied.
  if ( !exists $opt{all} || defined $opt{all} ) {
    my $name = $opt{all} || "all";
    group $name => values %groups;
  }

  # create group for each host
  group $_ => $groups{$_} for keys %groups;
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

  # Setup the default environment and cache the `vagrant ssh-config` for
  # 5 minutes. This helps speed up running `rex -T`, or any other rex
  # invocation when the ssh-config is cached.
  use Rex::Vagrant
    -env => {},
    -cache => { enabled => 1, timeout => 300 };

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
