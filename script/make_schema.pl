=head1 NAME

make_schema - generates schema definition for Teng

=head1 SYNOPSIS

./bin/make_schema <options>

# or

perl scrip/make_schema.pl <options>

=head1 OPTIONS

=over4

=item --namespace=MyApp::DB [optional]

=item --inflate-dir=etc/schema/inflate [optional]

=back

=cut
use 5.16.0;
use warnings;
use Getopt::Long qw/:config posix_default no_ignore_case bundling/;
use Teng::Schema::Dumper;
use Text::Xslate qw/mark_raw/;
use File::Basename;
use Pod::Usage;
use Data::Section::Simple qw/get_data_section/;
use MyProject;

my $c = MyProject->bootstrap();

my %opts = (
    ns          => 'MyProject::DB',
    inflate_dir => $c->base_dir() . '/etc/schema/inflate',
);
GetOptions (
    'ns|namespace=s' => \$opts{ns},
    'inflate-dir=s'  => \$opts{inflate_dir},
) or pod2usage(1);

my $ns          = $opts{ns};
my $inflate_dir = $opts{inflate_dir};

my %inflate;
for my $f ( glob( "$inflate_dir/*.pl" ) ) {
    my $name = basename $f, '.pl';
    open my $fh, '<', $f or die $!;
    my $code = do { local $/; <$fh> };
    $code =~ s/^(.*\S)/    $1/mg;
    $inflate{$name} = $code;
}

my $schema = Teng::Schema::Dumper->dump(
    dbh       => $c->dbh(),
    namespace => $ns,
    inflate   => \%inflate,
);

my $out = Text::Xslate->new->render_string(
    get_data_section('template.tx'),
    {
        namespace => $ns,
        schema    => mark_raw( $schema ),
        plugins   => [],
    },
);

print $out;
__DATA__

@@ template.tx
package <: $namespace :>;
use 5.16.0;
use parent 'Teng';
: for $plugins -> $plugin {
__PACKAGE__->load_plugin('<: $plugin :>');
: }
1;

<: $schema :>
