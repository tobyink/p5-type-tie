# Hash::Util::FieldHash was first released with perl v5.9.4
if ( $] < 5.009004 ) {
	$meta->{prereqs}{runtime}{recommends}{'Hash::FieldHash'} = 0;
	$meta->{prereqs}{runtime}{requires}{'Hash::Util::FieldHash::Compat'} = 0;
}
