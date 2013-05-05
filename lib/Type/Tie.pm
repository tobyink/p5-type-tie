use 5.008005;
use strict;
use warnings;

use Carp ();
use Tie::Array ();
use Tie::Hash ();
use Tie::Scalar ();

++$Carp::CarpInternal{"Type::Tie::$_"} for qw( BASE SCALAR ARRAY HASH );

BEGIN
{
	package Type::Tie;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use base "Exporter::TypeTiny";
	our @EXPORT = qw(ttie);
	
	sub ttie (\[$@%]$;@)#>&%*/&<%\$[]^!@;@)
	{
		my ($ref, $type, @vals) = @_;
		
		if (ref($ref) eq "HASH")
		{
			tie(%$ref, "Type::Tie::HASH", $type);
			%$ref = @vals if @vals;
		}
		elsif (ref($ref) eq "ARRAY")
		{
			tie(@$ref, "Type::Tie::ARRAY", $type);
			@$ref = @vals if @vals;
		}
		else
		{
			tie($$ref, "Type::Tie::SCALAR", $type);
			$$ref = $vals[-1] if @vals;
		}
		return $ref;
	}
};

BEGIN
{
	package Type::Tie::BASE;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use Hash::FieldHash qw(fieldhash);
	fieldhash(my %TYPE);
	
	sub _set_type
	{
		my $self = shift;
		$TYPE{$self} = $_[0];
	}
	
	sub type
	{
		my $self = shift;
		$TYPE{$self};
	}
	
	sub _dd
	{
		my $value = @_ ? $_[0] : $_;
		!defined $value ? 'Undef' :
		!ref $value     ? sprintf('Value %s', B::perlstring($value)) :
		do {
			require Data::Dumper;
			local $Data::Dumper::Indent   = 0;
			local $Data::Dumper::Useqq    = 1;
			local $Data::Dumper::Terse    = 1;
			local $Data::Dumper::Sortkeys = 1;
			local $Data::Dumper::Maxdepth = 2;
			Data::Dumper::Dumper($value)
		}
	}
	
	sub store_value
	{
		my $self = shift;
		my $type = $TYPE{$self};
		my $val  = $type->has_coercion ? $type->coerce($_[0]) : $_[0];
		Carp::croak(sprintf "%s does not meet type constraint $type", _dd($_[0]))
			unless $type->check($val);
		return $val;
	}
};

BEGIN
{
	package Type::Tie::ARRAY;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use base qw( Tie::StdArray Type::Tie::BASE );
	
	sub TIEARRAY
	{
		my $class = shift;
		my $self = $class->SUPER::TIEARRAY;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE
	{
		my $self = shift;
		$self->SUPER::STORE($_[0], $self->store_value($_[1]));
	}
	
	sub PUSH
	{
		my $self = shift;
		$self->SUPER::PUSH(map $self->store_value($_), @_);
	}
	
	sub UNSHIFT
	{
		my $self = shift;
		$self->SUPER::UNSHIFT(map $self->store_value($_), @_);
	}
};

BEGIN
{
	package Type::Tie::HASH;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use base qw( Tie::StdHash Type::Tie::BASE );
	
	sub TIEHASH
	{
		my $class = shift;
		my $self = $class->SUPER::TIEHASH;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE
	{
		my $self = shift;
		$self->SUPER::STORE($_[0], $self->store_value($_[1]));
	}
};

BEGIN
{
	package Type::Tie::SCALAR;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use base qw( Tie::StdScalar Type::Tie::BASE );
	
	sub TIESCALAR
	{
		my $class = shift;
		my $self = $class->SUPER::TIESCALAR;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE
	{
		my $self = shift;
		$self->SUPER::STORE( $self->store_value($_[0]) );
	}
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tie - tie a variable to a type constraint

=head1 SYNOPSIS

Type::Tie is a response to this sort of problem...

   use strict;
   use warnings;
   
   {
      package Local::Testing;
      use Moose;
      has numbers => ( is => "ro", isa => "ArrayRef[Num]" );
   }
   
   # Nice list of numbers.
   my @N = ( 1, 2, 3, 3.14159 );
   
   # Create an object with a reference to that list.
   my $object = Local::Testing->new(numbers => \@N);
   
   # Everything OK so far...
   
   # Now watch this!
   push @N, "Monkey!";
   print $object->dump;
   
   # Houston, we have a problem!

Just declare C<< @N >> like this:

   use Type::Tie;
   use Types::Standard qw( Num );
   
   ttie my @N, Num, ( 1, 2, 3, 3.14159 );

Now any attempt to add a non-numeric value to C<< @N >> will die.

=head1 DESCRIPTION

This module exports a single function: C<ttie>. C<ttie> ties a variable
to a type constraint, ensuring that whatever values stored in the variable
will conform to the type constraint. If the type constraint has coercions,
these will be used if necessary to ensure values assigned to the variable
conform.

   use Type::Tie;
   use Types::Standard qw( Int Num );
   
   ttie my $count, Int->plus_coercions(Num, 'int $_'), 0;
   
   $count++;            # ok
   $count = 2;          # ok
   $count = 3.14159;    # ok, coerced to 3
   $count = "Monkey!";  # dies

While the examples in documentation (and the test suite) show type
constraints from L<Types::Standard>, but any L<Type::Library>-based or
L<MooseX::Types>-based type constraints should work.

=begin trustme

=item ttie

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tie>.

=head1 SEE ALSO

L<Type::Tiny>.

L<Moose::Manual::Types>,
L<Moose::Meta::TypeConstraint>,
L<Moose::Util::TypeConstraints>.

L<MooseX::Lexical::Types>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

