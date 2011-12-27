package Xray::XDI::Version1_0;

use Moose::Role;
use MooseX::Aliases;
use Data::Dumper;

use vars qw($debug);
$debug = 0;  # 0 = no debug messages, 1 = debug headers, 2 = headers & data

has 'version'	         => (is => 'rw', isa => 'Str', default => q{1.0});

has 'applications'	 => (is => 'rw', isa => 'Str', default => q{});

has 'column'    => (metaclass => 'Collection::Hash',
		    is        => 'rw',
		    isa       => 'HashRef[Str]',
		    default   => sub { {} },
		    provides  => {
				  exists    => 'exists_in_column',
				  keys      => 'keys_in_column',
				  get       => 'get_column',
				  set       => 'set_column',
				 }
		   );
has 'scan'      => (metaclass => 'Collection::Hash',
		    is        => 'rw',
		    isa       => 'HashRef[Str]',
		    default   => sub { {} },
		    provides  => {
				  exists    => 'exists_in_scan',
				  keys      => 'keys_in_scan',
				  get       => 'get_scan',
				  set       => 'set_scan',
				 }
		   );
has 'mono'     => (metaclass => 'Collection::Hash',
		   is        => 'rw',
		   isa       => 'HashRef[Str]',
		   default   => sub { {} },
		   provides  => {
				 exists    => 'exists_in_mono',
				 keys      => 'keys_in_mono',
				 get       => 'get_mono',
				 set       => 'set_mono',
				}
		  );
has 'beamline' => (metaclass => 'Collection::Hash',
		   is        => 'rw',
		   isa       => 'HashRef[Str]',
		   default   => sub { {} },
		   provides  => {
				 exists    => 'exists_in_beamline',
				 keys      => 'keys_in_beamline',
				 get       => 'get_beamline',
				 set       => 'set_beamline',
				}
		  );
has 'facility' => (metaclass => 'Collection::Hash',
		   is        => 'rw',
		   isa       => 'HashRef[Str]',
		   default   => sub { {} },
		   provides  => {
				 exists    => 'exists_in_facility',
				 keys      => 'keys_in_facility',
				 get       => 'get_facility',
				 set       => 'set_facility',
				}
		  );
has 'detector' => (metaclass => 'Collection::Hash',
		   is        => 'rw',
		   isa       => 'HashRef[Str]',
		   default   => sub { {} },
		   provides  => {
				 exists    => 'exists_in_detector',
				 keys      => 'keys_in_detector',
				 get       => 'get_detector',
				 set       => 'set_detector',
				}
		  );
has 'sample'   => (metaclass => 'Collection::Hash',
		   is        => 'rw',
		   isa       => 'HashRef[Str]',
		   default   => sub { {} },
		   provides  => {
				 exists    => 'exists_in_sample',
				 keys      => 'keys_in_sample',
				 get       => 'get_sample',
				 set       => 'set_sample',
				}
		  );

# has 'extensions' => (metaclass => 'Collection::Array',
# 		     is        => 'rw',
# 		     isa       => 'ArrayRef[Str]',
# 		     default   => sub { [] },
# 		     provides  => {
# 				   'push'  => 'push_extension',
# 				   'pop'   => 'pop_extension',
# 				   'clear' => 'clear_extensions',
# 				  }
# 		    );


has 'order' 	   => (is => 'rw', isa => 'ArrayRef',
		       default => sub{ ['column',
					'scan',
					'mono',
					'beamline',
					'facility',
					'detector',
					'sample',]
				     });





## note that the MooseX::Aliases 0.08 pod is incorrect in how to get
## an alias applied in a role.  the following works, but was a bit
## hard to figure out.  version 0.09 does *not* fix the problem
## (although it might with Moose 1.24)
has 'comment_character'  => (is => 'rw', isa => 'Str', default => q{#},
			     traits => ['MooseX::Aliases::Meta::Trait::Attribute'],
			     alias=>'cc');
has 'field_end'          => (is => 'rw', isa => 'Str', default => q{#}.'/' x 3,
			     traits => ['MooseX::Aliases::Meta::Trait::Attribute'],
			     alias=>'fe');
has 'header_end'         => (is => 'rw', isa => 'Str', default => q{#}.'-' x 60,
			     traits => ['MooseX::Aliases::Meta::Trait::Attribute'],
			     alias=>'he');
has 'record_separator'   => (is => 'rw', isa => 'Str', default => "\t",
			     traits => ['MooseX::Aliases::Meta::Trait::Attribute'],
			     alias=>'rs');


sub define_grammar {
  return <<'_EOGRAMMAR_';
XDI: <skip: qr/[ \t]*/> VERSION(?) FIELDS(?) COMMENTS(?) LABELS(?) DATA

UPALPHA:    /[A-Z]+/
LOALPHA:    /[a-z]+/
ALPHA:      /[a-zA-Z]+/
DIGIT:      /[0-9]/
WORD:       /[-a-zA-Z0-9_]+/
PROPERWORD: /[a-zA-Z][-a-zA-Z0-9_]+/
NOTDASH:    /^[#;][ \t]*(?!-+)/
## including # in ANY is problematic
#ANY:        /[^\#; \t\n\r]+/
ANY:        /\A(?!-{3,})[^ \t\n\r]+/
COMM:       /^[\#;]/

CR:         /\n/
LF:         /\r/
CRLF:       CR LF
#EOL:        CRLF | CR | LF
EOL:        /[\n\r]+/
SP:         / \t/
WS:         SP(s)
TEXT:       WORD
MATH:       /(?:ln)?[-+\*\$\/\(\)\d]+/
EXPRESSION: WORD | MATH | SP

#SIGN:       /[-+]/
INTEGER:    /\d+/
#EXPONENT:   /[eEdD]/  SIGN(?)  INTEGER
#NUMBER:     DIGIT(s)  ("."  DIGIT(s))(?)  EXPONENT(?)
#INF:        /inf/i
#NAN:        /nan/i
FLOAT:      /[+-]?\ *(\d+(\.\d*)?|\.\d+)([eEdD][+-]?\d+)?/  # see perlretut
## what about nan and inf?

FIELD_END:  COMM  /\/+/ EOL
HEADER_END: COMM  /-{2,}/ EOL

XDI_VERSION:   "XDI/"  INTEGER  "."  INTEGER 
## this action is not quite right, indeed specifying a version format is probably a bad idea
APPLICATIONS:  WORD  "/"   INTEGER  ("." INTEGER)(s) {
  	        $Xray::XDI::object->applications(join("", @item[1..3]).'.'.join('.', @{$item[4]}));
	        1;
	       }
VERSION: COMM XDI_VERSION  APPLICATIONS(s?) EOL

#CUT:            DIGIT(3)
REFLECTION:     /\d{3}/
MATERIAL:       ("Si" | "Ge" | "Diamond" | "YB66" | "InSb" | "Beryl" | "Multilayer")
DATETIME:       /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
HARMONIC_VALUE: /\d{1,2}/

BEAMLINE:    COMM  "Beamline" "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_beamline($item[4], join(" ", @{$item[6]}));
            }

COLUMN:      COMM  "Column" "." INTEGER(s) ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_column(join("", @{$item[4]}), join(" ", @{$item[6]}));
            }

DETECTOR:    COMM  "Detector" "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_detector($item[4], join(" ", @{$item[6]}));
            }

FACILITY:    COMM  "Facility" "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_facility($item[4], join(" ", @{$item[6]}));
            }

MONO:        COMM  "Mono"     "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_mono($item[4], join(" ", @{$item[6]}));
            }

SAMPLE:      COMM  "Sample"   "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_sample($item[4], join(" ", @{$item[6]}));
            }

SCAN:        COMM  "Scan"     "." PROPERWORD ":"  ANY(s) {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
	     $Xray::XDI::object->set_scan($item[4], join(" ", @{$item[6]}));
            }




EXT_FIELD_NAME:  PROPERWORD
EXT_FIELD:  COMM  EXT_FIELD_NAME '.' PROPERWORD ":"  ANY(s?)  EOL {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug; 
             $Xray::XDI::object->push_extension(join("", @item[2..4]) . ': ' . join(" ", @{$item[6]}));
            }

FIELD_LINE: DEFINEDFIELDS
DEFINEDFIELDS: (  BEAMLINE | COLUMN | DETECTOR | FACILITY | MONO | SAMPLE | SCAN ) EOL

FIELDS:  (FIELD_LINE | EXT_FIELD)(s) FIELD_END

COMMENT_LINE: NOTDASH  ANY(s?) EOL {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
             $Xray::XDI::object->push_comment(join(" ", @{$item[2]}));
            }
COMMENTS:     COMMENT_LINE(s?)  HEADER_END

LABEL:    ANY
LABELS:   COMM  LABEL(s) EOL {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug;
             $Xray::XDI::object->push_label(@{$item[2]});
            }

DATA_LINE: FLOAT(s) EOL {
             Xray::XDI::Version1_0::dumpit(\@item) if $Xray::XDI::Version1_0::debug > 1;
             $Xray::XDI::object->add_data_point(@{$item[1]})  if $#{$item[1]}>-1;
            }
DATA:      DATA_LINE(s?)

_EOGRAMMAR_
}

sub dumpit {
  local $Data::Dumper::Indent = 0;
  my $line = Data::Dumper->Dump($_[0]);
  $line =~ s{\$VAR\d+ =}{}g;
  $line =~ s{;}{}g;
  $line =~ s{\n}{\\n}g;
  print $line, $/;
};

1;

=head1 NAME

Xray::XDI::Version1_0 - XDI 1.0 grammar definition

=head1 VERSION

This role defines version 1.0 of the XAS Data Interchange grammar.

=head1 ATTRIBUTES

=head2 Defined fields

One attribute is provided for each defined field in the grammar.  Each
attribute is spelled exactly the same as it is expected in an XDI
header, except that XDI headers are specified to be first-letter
capitalized while attribute names are all lower case.

=head2 Attribute order

The C<order> attribute defines the recommended order of namespaces in
an exported XDI file:

    column
    scan
    mono
    beamline
    facility
    detector
    sample

=head2 Structural elements

The following attributes defines XDI-complient character sequences for
use in exported files.  A compliantly exported file can be imported as
an XDI-compliant file.

=over 4

=item C<comment_character> (alias: C<cc>)

The character or character sequence which begins an exported comment
line.  The default is C<#>.

=item C<field_end> (alias: C<fe>)

The character sequence which marks the end of the defined and
extension fields.  The default is C<#//>.

=item C<header_end> (alias: C<he>)

The character sequence which marks the end of the header.  It follows
the user comment section.  The default is C<#> followed by 60 dashes
(C<->).

=item C<record_separator> (alias: C<rs>)

The white space which separates labels in the label line and numbers
in the data lines.  The default is a single tab.

=back

=head1 BNF GRAMMAR

This grammar is expressed in BNF form as:

   ;; augmented BNF grammar for the XAS Data Interchange format
   ;; see RFC 5234, http://tools.ietf.org/html/rfc5234, for grammar syntax

   ;; start rule
   XDI            = [VERSION] [FIELDS] [COMMENTS] [LABELS] 1DATA

   ;; core rules
   OCTET          = %x00-FF             ; 8 bits of data
   UPALPHA        = %x41-5A             ; upper case letters A - Z
   LOALPHA        = %x61-7A             ; lower case letters a - z
   CHAR           = %x01-7F             ; any 7-bit US-ASCII character, excluding NUL
   VCHAR          = %x21-7E             ; visible (printing) characters, 7-bit (US-ASCII)
   ALPHA          = UPALPHA / LOALPHA   ; US-ASCII letters
   DIGIT          = %x30-39             ; digits 0 - 9
   CTL            = %x00-1F / %x7F      ; control characters (octets 0 - 31) and DEL (127)
   CR             = %x0D                ; carriage return
   LF             = %x0A                ; line feed
   CRLF           = CR LF               ; MS newline = carriage return line feed
   SP             = %x20                ; space
   HT             = %x09                ; horizontal tab
   WS             = SP  /  HT           ; white space
   EOL            = CR  /  LF  /  CRLF  ; cross-platform end-of-line 

   ;; Basic Constructs
   SIGN           = "+"  /  "-"
   EXPONENT       = ("e"  /  "E"  /  "d"  /  "D")  [SIGN]  1*DIGIT
   NUMBER         = 1*DIGIT  ["."  *DIGIT]  [EXPONENT]
   INF            = ("i"  /  "I")  ("n"  /  "N")  ("f"  /  "F")
   NAN            = ("n"  /  "N")  ("a"  /  "A")  ("n"  /  "N")
   FLOAT          = [SIGN]  (NUMBER  /  INF  / NAN )

   TEXT           = %09 / %x20-FF        ; any OCTET except CTLs, including WS
   COMM           = "#" / ";"
   PROPERWORD     = ALPHA  *(ALPHA  /  DIGIT  /  "_")
   WORD           = *(ALPHA  /  DIGIT  /  "_")
   MATH           = ["ln"] *("-"  /  "+"  /  "*"  /  "$"  /  "/"  /  "("  /  ")"  DIGIT)

   FIELD-END      = "#"  1*"/"  EOL
   HEADER-END     = "#"  2*"-"  EOL

   ;; Version Information
   XDI-VERSION    = "XDI/"  1*DIGIT  ". " 1*DIGIT
   APPLICATIONS   = VCHAR
   VERSION        = "#"  XDI-VERSION  *APPLICATIONS  EOL

   ;; Defined Fields
   REFLECTION     = 3DIGIT
   ELEMENT        = ("Si" / "Ge" / "Diamond" / "YB66" / "InSb" / "Beryl" / "Multilayer")
   DATETIME       = 4DIGIT  "-"  2DIGIT  "-"  2DIGIT "T" 2DIGIT  ":"  2DIGIT  ":"  2DIGIT
   HARMONIC-VALUE = 1*2DIGIT

   BEAMLINE       =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   COLUMN         =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   DETECTOR       =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   FACILITY       =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   MONO           =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   SAMPMLE        =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)
   SCAN           =    COMM  "Beamline" "." PROPERWORD ":"  ANY(s)

   DEFINEDFIELDS  = (  BEAMLINE / COLUMN / DETECTOR / FACILITY / MONO / SAMPLE / SCAN ) EOL
   FIELD-LINE     = DEFINEDFIELDS

   ;; Extension Fields
   EXT-FIELD-NAME = PROPERWORD  "."  WORD
   EXT-FIELD      = "#"  EXT-FIELD-NAME  ": "  *VCHAR  EOL

   ;; All Fields
   FIELDS         =  (FIELD-LINE / EXT-FIELD)(s) FIELD_END


   ;; User Comments
   COMMENT-LINE   = "#"  *VCHAR  EOL
   COMMENTS       = *COMMENT-LINE  HEADER-END

   ;; Column Labels
   LABEL          = PROPERWORD
   LABELS         = "#" 1*LABEL  EOL

   ;; Data Section
   DATA-LINE      = *FLOAT EOL
   DATA           = *DATA-LINE

=head1 BUGS AND LIMITATIONS

=over 4

=item *

INF and NAN are not supported in this implementation

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


