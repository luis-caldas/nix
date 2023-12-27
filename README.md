# My NIX

Personal configuration for NixOS for all my systems

# Understanding it

Most of the configuration that is repetitive is done for all the systems with a configuration system, so new systems need a minimal Nix file to configure it

## How it works

A new set of configuration arguments were create to aid the systems, they are located in `config/defaults.nix`

Using these new arguments then the systems can be dynamically built to preferred configurations

These configurations are like macros that do a lot on the systems

## Folders

`common` - Here are all the commonly evaluated files for all the systems, inside configuration specifics will be determined by the newly created configuration variables

`config` - All the possible default configurations that will help the common files

`docs` - Documentation for creating systems

`lib` - Library with my custom functions

`pkgs` - Custom options and packages for the systems

`start` - Startup files used to organise building the systems

`systems` - Folder containing all the possible systems that will be built

## Systems

Systems can be created by creating a folder with its name on the `systems` folder, within it then a `default.nix` file should be present

This file will contain the minimal configuration then for the system

Finally, the system must be selected by putting its name on the file `system` at the root, so when it is built the system knows which one to use

# Installing

To install it we need to reference the `start.nix` file from the main NixOS configuration file, which is normally located at `/etc/nixos/configuration.nix`

It should look something like this

```

{ ... }:
{
  imports = [ /path/to/the/start.nix ];
}

```

The `system` file must also be present with the name of the system that will be built, this system then must be present in the `systems` folder

# Building

All the normally used command for building it will work