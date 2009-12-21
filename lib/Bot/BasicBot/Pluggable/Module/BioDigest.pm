package Bot::BasicBot::Pluggable::Module::BioDigest;

# ABSTRACT: Have your bot chop your DNA and Protein with enzymes!

use base 'Bot::BasicBot::Pluggable::Module';
use Modern::Perl;
use Try::Tiny;
use Bio::Seq;
use Bio::Protease;
use Bio::Restriction::Analysis;

sub told {
    my ($self, $msg) = @_;

    # Unless they address us specifically, do nothing.
    return unless $msg->{address};

    my ($command, $seq, $enzyme) = split /\s+/, $msg->{body}, 3;

    return unless ($command eq 'digest' and $seq);

    if (not $enzyme) { return 'Digest it with what?' }

    if    (is_dna    ($seq)) { return digest_dna     ($seq, $enzyme) }
    elsif (is_protein($seq)) { return digest_protein ($seq, $enzyme) }
    else                     { return invalid_seq_msg()              }

}

sub digest_protein {
    my ($seq, $enzyme) = @_;

    state $specificities = [ keys %{Bio::Protease->Specificities} ];

    unless ( $enzyme ~~ @$specificities ) {
        return "$enzyme is not a valid Protease. See http://search.cpan.org/perldoc?Bio::Protease";
    }

    my @peptides = try {
        Bio::Protease->new( specificity => $enzyme )->digest($seq);
    } catch { return "Something went wrong: $_" };

    return "@peptides";
}

sub digest_dna {
    my ($seq, $enzyme) = @_;

    my $Enzyme = _valid_RE_name($enzyme)
        or return "$enzyme is not a valid Restriction Enzyme. See http://search.cpan.org/perldoc?Bio::Restriction::EnzymeCollection";


    my @oligos = try {
        Bio::Restriction::Analysis->new(
            -seq => Bio::Seq->new( -seq => $seq, -type => 'dna' )
        )->fragments($Enzyme)
    } catch { return "Something went wrong" };

    return "@oligos";

}

sub _valid_RE_name {
    my $enzyme = shift;

    state $enzymes
        = [ Bio::Restriction::EnzymeCollection->new->available_list ];

    # given an ill-cased enzyme name, get the correct one.
    # Neccesary because ::Restriction::Analysis only accepts correctly
    # cased enzyme names.

    my ($correct_name) = grep { lc $_ eq lc $enzyme } @$enzymes;

    return $correct_name;
}

sub is_dna {
    my $seq = shift;
    return $seq !~ /[^ACGTUacgtu]/;
}

sub is_protein {
    my $seq = shift;

    return $seq !~ /[^ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy]/;

}

sub invalid_seq_msg {

    state $messages = [
        "Your input is ALL WRONG!",
        "I.. I think that's not quite right.",
        "Mmh. Please check that sequence, I don't like it.",
        "Dude. Check your purines, a restriction enzyme would laugh at that sequence.",
        "Check your aminoacids, a protease would slap you if you gave her that",
        "No, no NOOO! Horrible input. I'm ashamed for both of us.",
        "If that's supposed to represent a polymer of nucleotides or aminoacids, then I'm the digital reincarnation of Napoleon.",
    ];

    return $messages->[rand @$messages];
}

sub help {

    my $usage = <<END;
Digest DNA or Protein with hydrolytic enzymes
Usage: digest <seq> <enzyme>
END

    return $usage;
}

1;

__END__

=head1 DESCRIPTION

This plugin will give your L<Bot::BasicBot::Pluggable> bot the ability
to perform the most common conversions and analysis on DNA/RNA/Protein
sequences.

The bot should always be addressed directly.

=head1 NESTABLE COMMANDS

Whenever it makes sense, commands can be nested. If one command returns
a DNA sequence, it can be put as an argument of an outer command, as so:

    command1 command2 <seq>

This is parsed as:

    command1( command2( <seq> ) )

For example, you can do:

    composition complement GGGGGG
    C: 100.0%

However, currently only the innermost command can take optional
arguments. So this:

    translate reverse GATTCCG 2

Will be parsed as:

    translate( reverse GATTCCG 2 )

instead of:

    translate( reverse(GATTCCG), 2 )

If the need arises, it'll be fixed in the future.

=cut
