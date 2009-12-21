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

=method digest

    digest <seq> <enzyme>

Digest C<seq> with C<enzyme>. DNA digestion is done using
L<Bio::Restriction::Analysis>, and protein digestion with
L<Bio::Protease>. See their respective docs for a list of available
enzymes. Casing doesn't matter.

Returns a list of fragments after being cut but the enzyme specified.

=cut

sub digest_protein {
    my ($seq, $enzyme) = @_;

    state $specificities = [ keys %{Bio::Protease->Specificities} ];

    $enzyme = lc $enzyme;
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

This L<Bot::BasicBot::Pluggable::Module> plugin will allow your bot to
digest protein and DNA sequences with a large set of different enzymes.

The bot should always be addressed directly.

=cut
