#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'LifeBoard-Web';
all_from 'lib/LifeBoard/Web.pm';

requires 'Catalyst::Runtime' => '5.80024';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'YAML';

requires 'KiokuDB';
requires 'KiokuX::User';
requires 'KiokuX::Model';
requires 'KiokuDB::Backend::DBI';
requires 'Catalyst::Model::KiokuDB';
requires 'Catalyst::Authentication::Store::KiokuDB';

requires 'Message::Stack';
requires 'Data::Verifier';
requires 'Data::Manager';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
