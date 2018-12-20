use strict;

package WebService::Tag::DB;
use 5.006;
use warnings;
use base qw(Class::Accessor);

=head1 NAME

	WebService::Tag::DB - 'This Subject Has These Tags' in module/microservice form

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

	Base class for tracking $tags against $subjects

=head1 EXPORT

	None

=head1 SUBROUTINES/METHODS
=head2 Critical Path
=cut

=head2 new
	
=cut

sub new {
	my ( $class, $conf ) = @_;
	my $self = {};
	bless $self, $class;
	my $initresult = $self->_init( $conf );
	die $initresult->{fail} unless $initresult->{pass};
	return $self;
}

sub _init {
	my ( $self, $conf ) = @_;

	return {fail => "Non useful init"};
}

=head2
	transfer $conf keys to $self, or the corresponding accessor
=cut

sub configure {
	my ( $self, $conf, $keys ) = @_;
	$keys = [] unless $keys;
	for ( @{$keys} ) {
		if ( exists( $conf->{$_} ) ) {
			if ( $self->can( $_ ) ) {
				$self->$_( $conf->{$_} );
			} else {
				$self->{$_} = $conf->{$_};
			}
		}
	}
}

=head2

=cut

sub set_subject_2d_tags_arref {
	my ( $self, $subject_id, $arref, $params ) = @_;
	die "not implemented";

}

sub create_2d_tag {
	my ( $self, $tag_string ) = @_;
	die "not implemented";
}

sub add_2d_tag_to_subject {
	my ( $self, $subject_id, $tag_id ) = @_;
	die "not implemented";
}

sub remove_other_2d_tags_from_subject {
	my ( $self, $subject_id, $tag_id ) = @_;
	die "not implemented";
}

sub cached_value_id {
	my ( $self, $tag_id ) = @_;
	die "not implemented";
}

sub new_value_id {
	my ( $self, $tag_id ) = @_;
	die "not implemented";
}

sub set_subject_2d_tags_string {
	my ( $self, $subject_id, $tag_string ) = @_;
	my @tag_id_arref;
	for my $string ( split( $self->tag_divider, $tag_string ) ) {
		my $id = $self->cached_value_id( '2d_tags', $string );
		unless ( $id ) {
			my $id = $self->new_value_id( '2d_tags', $string );
		}

		push( @tag_id_arref, $id );
	}
	$self->set_subject_2d_tags( $subject_id, \@tag_id_arref );
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
