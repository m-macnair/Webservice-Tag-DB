use strict;

package WebService::Tag::DB::DBI;
use Module::Runtime;
use 5.006;
use warnings;
use base qw(WebService::Tag::DB);

=head1 NAME

	WebService::Tag::DB::DBI - 'This Subject Has These Tags' in a db

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

	Wrapper around a database that tracks $tags against $subjects

=head1 EXPORT

	None
=head1 TODO
	table prefix / custom table defs
	forking 
	
	
=head1 SUBROUTINES/METHODS
=head2 Critical Path
=cut

=head2 new
=cut

sub _init {
	my ( $self, $conf ) = @_;

	my @cache_names;
	for (
		qw/
		2d_tags
		3d_tags
		shared_tag_types
		subject_3d_tag_ints
		subject_3d_tag_strings
		subject_has_2d
		tag_delimiter
		/
	  )
	{
		push( @cache_names, "$_\_id_cache" );
	}

	my @accessors = ( qw/dbh  last_insert_sth tag_delimiter /, @cache_names );
	__PACKAGE__->mk_accessors( @accessors );

	$self->SUPER::configure( $conf, [@accessors] );
	unless ( $self->dbh ) {
		unless ( ref( $conf->{dsn} ) eq 'ARRAY' ) {
			return {fail => "No DBH and no DSN provided - can't connect to database"};
		}
		use DBI;
		my $dbh = DBI->connect( @{$conf->{dsn}} ) or die $DBI::errstr;
		$self->dbh( $dbh );
	}

	for ( @cache_names ) {
		unless ( $self->$_ ) {
			Module::Runtime::require_module( "Cache::Memory" );
			my $cache = Cache::Memory->new( namespace => $_, default_expires => '100 sec' );
			$self->$_( $cache );
		}
	}

	return {pass => 1};
}

sub clean_finish {
	my ( $self ) = @_;
	$self->_commit();
	delete( $self->{sths} );
	$self->last_insert_sth( '' );
	$self->dbh->disconnect();
}

sub find_or_create_subject {


	my ( $self, $id ) = @_;

	unless ( $self->{sths}->{find_subject_sth} ) {
		$self->{sths}->{find_subject_sth} = $self->dbh->prepare( "select id from subjects where id = ?" ) or die $DBI::errstr;
	}
	$self->{sths}->{find_subject_sth}->execute($id);
	if(my $row = $self->{sths}->{find_subject_sth}->fetchrow_arrayref){
		return $id;
	}
	
	
	unless ( $self->{sths}->{new_subject_sth} ) {
		$self->{sths}->{new_subject_sth} = $self->dbh->prepare( "insert into subjects values ()" ) or die $DBI::errstr;
	}
	$self->{sths}->{new_subject_sth}->execute();
	return $self->last_insert

}

sub set_subject_2d_tags_string {
	my ( $self, $subject_id, $tag_string ) = @_;
	my @strings = split( $self->tag_delimiter(), $tag_string );
	my @tag_ids;
	for ( @strings ) {
		push( @tag_ids, $self->get_2dtag_for_string( $_ ) );
	}

	for ( @tag_ids ) {

	}
}

sub get_2dtag_for_string {
	my ( $self, $value ) = @_;
	my $v = $self->cached_value_id( '2d_tags', $value, );

	#implies we need a new one
	unless ( $v ) {
		$v = $self->new_value_id( '2d_tags', $value );
	}
	return $v;
}

sub cached_value_id {
	my ( $self, $table, $value, $cache ) = @_;
	$cache ||= $self->_cache_id_name( $table );
	my $v = $self->$cache->get( $value );
	return $v if $v;

	my $sth = $self->id_from_value_sth( $table );
	$sth->execute( $value );
	if ( my $row = $sth->fetchrow_hashref() ) {
		$self->$cache->set( $value, $row->{id} );
		return $row->{id};
	}

	return;
}

sub set_subject_2d_tags_arref {
	my ( $self, $subject_id, $tag_arref ) = @_;
	for my $tag_id ( @{$tag_arref} ) {
		next if ( $self->subject_has_2d( $tag_id ) );
		$self->add_2d_tag_to_subject( $tag_id );
		$self->remove_other_2d_tags_from_subject( $subject_id, $tag_arref );
	}
}

sub remove_other_2d_tags_from_subject {
	my ( $self, $subject_id, $tag_arref ) = @_;

	# TODO
}

sub subject_has_2d {
	my ( $self, $subject_id, $tag_id ) = @_;

	# TODO
	return 0;
}

sub cache_subject_2d_tags {

	# TODO - ideally as a forked process , possibly using its own cache
}

sub new_value_id {
	my ( $self, $table, $value, $cache ) = @_;
	$cache ||= $self->_cache_id_name( $table );

	my $sth = $self->new_id_from_value_sth( $table );
	$sth->execute( $value );

	my $v = $self->last_insert();
	$self->$cache->set( $value, $v );
	return $v;
}

#mysql specific
sub last_insert {

	unless ( $_[0]->last_insert_sth ) {
		my $sth = $_[0]->dbh->prepare( "SELECT LAST_INSERT_ID() as id" );
		$_[0]->last_insert_sth( $sth );
	}

	$_[0]->last_insert_sth->execute();
	if ( my $row = $_[0]->last_insert_sth->fetchrow_hashref() ) {
		return $row->{id};
	} else {
		die "failed to create new entry : $DBI::errstr";
	}
}

sub _cache_id_name {
	my ( $self, $table ) = @_;
	my $cache = "$table\_id_cache";
	unless ( $self->can( $cache ) && $self->$cache ) {
		die "Cache not implemented for $table";
	}
	return $cache;
}

# TODO refactor to switch ( id else new id)

=head3 id_from_value_sth
	Persist the 'get id from row value column $value' sth for a table 
=cut

sub id_from_value_sth {
	my ( $self, $table ) = @_;

	unless ( $self->{sths}->{id_from_value_sth}->{$table} ) {
		$self->{sths}->{id_from_value_sth}->{$table} = $self->dbh->prepare( "select id from $table where value = ?" ) or die $DBI::errstr;
	}
	return $self->{sths}->{id_from_value_sth}->{$table};
}

sub new_id_from_value_sth {
	my ( $self, $table ) = @_;

	unless ( $self->{sths}->{new_id_from_value_sth}->{$table} ) {
		$self->{sths}->{new_id_from_value_sth}->{$table} = $self->dbh->prepare( "insert into $table (value) values (?) " ) or die $DBI::errstr;
	}
	return $self->{sths}->{new_id_from_value_sth}->{$table};
}

sub _commit_maybe {
	my ( $self, $counter, $limit ) = @_;
	if ( $self->dbh->{AutoCommit} == 0 ) {
		$counter ||= $self->sth_write_counter;
		$limit   ||= $self->sth_write_limit;
		$$counter++;
		if ( $$counter >= $limit ) {
			return $self->_commit( $counter );
		}
		return 2;
	}
	return 3;
}

sub _commit {
	my ( $self, $counter ) = @_;
	if ( $self->dbh->{AutoCommit} == 0 ) {
		$self->debug( " COMMIT " );
		$self->dbh->commit();
		$$counter = 0;

		return 1;
	}
	return 3;
}

sub debug {
}

# TODO this, properly

=head1 AUTHOR

mmacnair, C<< <mmacnair at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-tag-db at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Tag-DB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Tag::DB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Tag-DB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Tag-DB>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-Tag-DB>

=item * Search CPAN

L<https://metacpan.org/release/WebService-Tag-DB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 mmacnair.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Tag::DB
