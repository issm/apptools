package main;
use 5.12.0;
use warnings;
use utf8;
use Encode;
use File::Spec;
use File::Basename;
use File::Find qw//;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib' );
use Time::Piece;
use Log::Minimal;
use script::Util;


my $env = $ENV{PLACK_ENV} // 'development';
infof 'ENV: %s', $env;
infof 'db migration started.';

my $basedir     = File::Spec->catdir( dirname(__FILE__), '..' );
my $sqldir      = "${basedir}/etc/sql/patch";
my $migratefile = "${sqldir}/_migrate.${env}.pl";

my $container = start_scope_container();
my $dbh = get_dbh();

infof 'reading migrate file.';
my $migrate = eval { do $migratefile } // +{};
File::Find::find(
    sub{
        my ($f, $file) = ($_, $File::Find::name);
        $f =~ /^\d+\.sql$/  or  return;
        $migrate->{$f} //= [ 0, [] ];
    },
    $sqldir,
);

for my $f ( sort keys %$migrate ) {
    $migrate->{$f}[0]  &&  next;
    my $sql = do {
        local $/;
        open my $fh, '<', "$sqldir/$f";
        de <$fh>;
    };
    #infof '[%s] applying %s...', $f, $f;
    #$dbh->do($sql) or croakf $!;
    my @sqls = split /\s*;\s*/, $sql;

    my $i = 0;
    while ( my $sql = shift @sqls ) {
        $migrate->{$f}[1][$i]  &&  next;
        (my $sql_nonl = $sql) =~ s/\s*\n\s*/ /g;
        infof '[%s][%d] applying %s-%d...', $f, $i, $f, $i;
        $dbh->do($sql) or croakf '[%s][%d] failed', $f, $i;
        $migrate->{$f}[1][$i] = localtime->epoch;
        $i++;
    }
    $migrate->{$f}[0] = localtime->epoch;
}

infof 'saving migrate file.';
open my $fh, '>', $migratefile;
$fh->print( D $migrate );
close $fh;

infof 'db migration finished.';
