use Test::More;
use Test::Exception;
use Test::Bot::BasicBot::Pluggable;

my $bot = Test::Bot::BasicBot::Pluggable->new();
lives_ok { $bot->load('BioDigest') };

is $bot->tell_direct('digest GAATTC EcoRI'), 'G AATTC';

is $bot->tell_direct('digest GAATTC ecoRI'), 'G AATTC';

is $bot->tell_direct('digest GAATTC ecori'), 'G AATTC';

like $bot->tell_direct('digest GAATTC Foo'), qr/.*is not a valid.*/;

is $bot->tell_direct('digest MAAELL hcl'), 'M A A E L L';

like $bot->tell_direct('digest MAAELL foo'), qr/.*is not a valid.*/;

like $bot->tell_direct('digest GAATTC'), qr/.*with what.*/;

like $bot->tell_direct('help biodigest'), qr/^Digest.*/;

done_testing();
