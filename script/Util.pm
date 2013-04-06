package script::Util;
use 5.16.0;
use warnings;
use utf8;
use parent 'Exporter';
use File::Spec;
use File::Basename;
use Encode;
use Data::Recursive::Encode;
use DBI;
use DBIx::TransactionManager;
use Data::Section::Simple qw//;
use Scope::Container qw/scope_container/;
use Text::Xslate;
use Data::Validator;
use Data::Dumper qw//;
use Data::Dump qw//;

my $root = File::Spec->catdir( dirname(__FILE__), '..' );

our @EXPORT = qw/
    D Dc
    d dc
    en
    de
    get_config
    get_dbh
    get_txn_manager
    get_data_section
    get_xslate
    validator
    start_scope_container
/;

$Data::Dumper::Terse = 1;

sub D  { Data::Dumper::Dumper(@_) }
sub Dc { "[32m" . Data::Dumper::Dumper(@_) . "[0m" }
sub d  { Data::Dump::dump(@_) }
sub dc { "[32m" . Data::Dump::dump(@_) . "[0m" }

sub en { Data::Recursive::Encode->encode_utf8(@_) }
sub de { Data::Recursive::Encode->decode_utf8(@_) }


sub get_config {
    if ( my $conf = scope_container('config') ) {
        return $conf;
    }
    else {
        my $env = $ENV{PLACK_ENV} // 'development';
        my $conf = do "${root}/config/${env}.pl" or die $!;
        scope_container('config', $conf);
        return $conf;
    }
}


sub get_dbh {
    if ( my $dbh = scope_container('dbh') ) {
        return $dbh;
    }
    else {
        my $conf = get_config();
        my $dbh = DBI->connect(@{$conf->{DBI}}) or DBI::errstr;
        scope_container('dbh', $dbh);
        return $dbh;
    }
}


sub get_txn_manager {
    if ( my $tm = scope_container('txn_manager') ) {
        return $tm;
    }
    else {
        my $tm = DBIx::TransactionManager->new( get_dbh() );
        scope_container('txn_manager', $tm);
        return $tm;
    }
}


sub get_data_section {
    my ($name) = @_;
    my $caller = caller;
    return Data::Section::Simple->new($caller)->get_data_section($name);
}


sub get_xslate {
    if ( my $tx = scope_container('xslate') ) {
        return $tx;
    }
    else {
        my $tx = Text::Xslate->new(
            %{ get_config()->{'Text::Xslate'} // {} },
        );
        scope_container('xslate', $tx);
        return $tx;
    }
}


sub validator { Data::Validator->new(@_) }


sub start_scope_container { Scope::Container::start_scope_container() }


1;
