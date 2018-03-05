# NAME

Rex::Vagrant - Easily interact with your Vagrant boxes through Rex.

# SYNOPSIS

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

# DESCRIPTION

Rex::Vagrant is a module that makes it easy to interact with virtual machines created by Vagrant directly in Rex.

# AUTHOR

Mitch Broadhead <mitch.broadhead@gmail.com>

# COPYRIGHT

Copyright 2018- Mitch Broadhead

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
