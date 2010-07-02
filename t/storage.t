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

$person = $d->lookup( $uuid );
ok($d->exists($uuid), 'exists is ok');
ok(!$d->exists($uuid . "blahblah"), '!exists is ok');

my $note_id;
{
    my $s = $d->new_scope;
    
    ok( $person, 'got person from lookup' );
    my $now  = DateTime->now;
    my $note = $person->add_note(
        date     => $now,
        contents => "Just a test note"
    );
    is_deeply( $person->notes, [ $note ], 'got note after store' );
    cmp_ok( $person->get_calendar( $now->year )->get_month( $now->month )->get_day( $now->day )->has_notes, '==', 1, 'right note count' );

    $d->store( $person );
    $note_id = $note->id;
}

{
    $d->live_objects->clear;
    my $s = $d->new_scope;
    diag( $note_id );
    my $fresh_note = $d->lookup( $note_id );
    diag( $fresh_note );
    ok( $fresh_note, 'got fresh note' );
}

done_testing;
