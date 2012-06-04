# showMod.pm

package showMod;

use strict;

sub new
{
	my $strClass = shift;
	my $obj = {};
	bless $obj;
	
	my($strModName, $strModDesc, $strModVersion) = @_;
	
	$obj->{"name"} = $strModName;
	$obj->{"desc"} = $strModDesc;
	$obj->{"version"} = $strModVersion;
	
	return $obj;
}

sub getModSig
{
	my $obj = shift;
	return "\{\"" . $obj->{"name"} . " ### " . $obj->{"version"} . "\"\}";
}

sub getModName
{
	my $obj = shift;
	return $obj->{"name"} . " \(" . $obj->{"version"} . "\)";
}

sub getModDescList
{
	my $obj = shift;
	my @strModDescList = split /\\n/, $obj->{"desc"};
	return @strModDescList;
}

1;

