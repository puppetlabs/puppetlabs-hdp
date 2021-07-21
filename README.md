
# hdp

This module will help you setup HDP's report processor on a PE Primary or Compiler. It will also help you setup a node to host the HDP application stack.

- [Description](#description)
- [Setup](#setup)
  - [What hdp affects](#what-hdp-affects)
  - [Setup Requirements](#setup-requirements)
- [Usage](#usage)
- [Reference](#reference)
- [Changelog](#changelog)

## Description

There are two parts to getting started with HDP:

1. Setting up a node to run HDP itself (`hdp::app_stack`)
2. Configuring your PE Master and any Compilers to send data to HDP (`hdp::report_processor`)

## Setup

### What hdp affects

This module will modify the puppet.conf configuration of any master or compiler that it is applied to. Additionally, it will install and configure Docker on the node running HDP.

### Setup Requirements

HDP only works with Puppet Enterprise.

## Usage

See [REFERENCE.md](REFERENCE.md) for example usage.

## Reference

A custom fact named `hdp-health` is included as part of this module. It is a structured fact that returns information about the currently running instance of HDP.
Also, if this module is installed on a node, an `hdp` fact is included that will collect unmanaged resource information, but not land in PuppetDB.

This module is documented via `pdk bundle exec puppet strings generate --format markdown`. Please see [REFERENCE.md](REFERENCE.md) for more info.

## Changelog

[CHANGELOG.md](CHANGELOG.md) is generated prior to each release via `pdk bundle exec rake changelog`. This process relies on labels that are applied to each pull request.
