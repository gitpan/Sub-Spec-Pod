
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Generate POD documentation for subs',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Sub-Spec-Pod',
  'dist_version' => '0.07',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::Pod',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Clone::Any' => '0',
    'Data::Dump::Partial' => '0',
    'JSON' => '0',
    'List::MoreUtils' => '0',
    'Log::Any' => '0',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
