
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "HTML forms using Moose",
  "AUTHOR" => "FormHandler Contributors - see HTML::FormHandler",
  "BUILD_REQUIRES" => {
    "PadWalker" => 0,
    "Test::Differences" => 0,
    "Test::Exception" => 0,
    "Test::Memory::Cycle" => "1.04",
    "Test::More" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "HTML-FormHandler",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormHandler",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => "0.06",
    "Data::Clone" => 0,
    "DateTime" => 0,
    "DateTime::Format::Strptime" => 0,
    "Email::Valid" => 0,
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "HTML::TreeBuilder" => "3.23",
    "Locale::Maketext" => "1.09",
    "Moose" => "2.0007",
    "MooseX::Getopt" => "0.16",
    "MooseX::Types" => "0.20",
    "MooseX::Types::Common" => 0,
    "MooseX::Types::LoadableClass" => "0.006",
    "Sub::Exporter" => 0,
    "Sub::Name" => 0,
    "Try::Tiny" => 0,
    "aliased" => 0,
    "namespace::autoclean" => "0.09"
  },
  "VERSION" => "0.40016",
  "test" => {
    "TESTS" => "t/*.t t/blocks/*.t t/bootstrap/*.t t/compound/*.t t/errors/*.t t/field_setup/*.t t/fields/*.t t/form_setup/*.t t/infl_defl/*.t t/moose/*.t t/render/*.t t/repeatable/*.t t/result/*.t t/validation/*.t t/wizard/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


