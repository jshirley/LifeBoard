use strict;
use warnings;

use Test::More 'no_plan';

use KiokuX::User::Util 'crypt_password';

use_ok 'LifeBoard::Schema::Person';

my $person = LifeBoard::Schema::Person->new(
    name        => 'Test McTesty',
    id          => 'tester',
    password    => crypt_password('tester')
);

isa_ok( $person, 'LifeBoard::Schema::Person' );

is( $person->name, 'Test McTesty', 'name attribute' );

ok(  $person->check_password('tester'), 'positive password check' );
ok( !$person->check_password('negative'), 'negative password check' );

my $note = $person->add_note(
    contents => 'This is a simple test note',
    date     => DateTime->now,
);

is_deeply( $person->notes,  [ $note ], 'note added' );

