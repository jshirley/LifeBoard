use strict;
use warnings;

use Test::More;

use KiokuDB;
use DateTime;
use KiokuX::User::Util 'crypt_password';

use_ok 'LifeBoard::Schema::Person';

my $person = LifeBoard::Schema::Person->new(
    name        => 'Test McTesty',
    id          => 'tester',
    password    => crypt_password('tester'),
);

isa_ok( $person, 'LifeBoard::Schema::Person' );

my $d = KiokuDB->connect(
    'dbi:SQLite:dbname=var/lifeboard.db',
    create => 1,
    columns => [
        name => { data_type => 'varchar', is_nullable => 1 }
    ]
);

my $uuid;
{
    my $s = $d->new_scope;
    $uuid = $d->store( $person );
    ok($uuid, 'stored user');

    my $stream = $d->search({ name => 'Test McTesty' });
    my $block  = $stream->next;

    foreach my $object ( @$block ) {
        is_deeply( $object, $person, 'search returned person' );
    }
}

exit;

$person = $d->lookup( $uuid );
my $note;
{
    my $s = $d->new_scope;
    
    ok( $person, 'got person from lookup' );

    my $note = $person->add_note(
        date     => DateTime->now,
        contents => "Just a test note"
    );
    $d->store( $person );
    is_deeply( [ $person->notes->members ], [ $note ], 'got note after store' )
}

is( $person->notes->members->contents, 'Just a test note', 'have one note' );

done_testing;
