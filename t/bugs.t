#!/usr/bin/env perl

use lib 'lib', 't/lib';
use MyTests tests => 8;

{

    package RoleC;
    use Role::Basic;
    sub baz { 'baz' }
    ::fake_load;
}
{

    package RoleB;
    use Role::Basic;
    with 'RoleC';
    sub bar { 'bar' }
    ::fake_load;
}
{

    package RoleA;
    use Role::Basic;
    with 'RoleC';
    sub foo { 'foo' }
    ::fake_load;
}
eval <<'END';
package Foo;
use strict;
use warnings;
use Role::Basic 'with';
with 'RoleA', 'RoleB';
sub new { bless {} => shift }
END
my $error = $@;
ok !$error,
  'Composing multiple roles which use the same role should not have conflicts'
  or diag $error;

my $object = Foo->new;
foreach my $method (qw/foo bar baz/) {
    can_ok $object, $method;
    is $object->$method, $method,
      '... and all methods should be composed in correctly';
}

{
    no warnings 'redefine';
    local *UNIVERSAL::can = sub { 1 };
    eval <<'    END';
    package Can::Can;
    use Role::Basic 'with';
    with 'A::NonExistent::Role';
    END
    my $error = $@ || '';
    like $error, qr{^Can't locate A/NonExistent/Role.pm},
        'If ->can always returns true, we should still not think we loaded the role'
            or diag "Error found: $error";
}
