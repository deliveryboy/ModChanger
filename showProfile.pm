# showProfile.pm

package showProfile;

use strict;

sub new
{
	my $strClass = shift;
	my $obj = {};
	bless $obj;
	
	my($strOptionsFile, $strOptionsInfo, $strLastUser, @strSelectedMods) = @_;
	
	$obj->{"OptionsFile"} = $strOptionsFile;
	$obj->{"OptionsInfo"} = $strOptionsInfo;
	$obj->{"SelectedMods"} = \@strSelectedMods;
	
	if($obj->getProfileName eq $strLastUser)
	{
		$obj->{"LastUser"} = 1;
	}
	else
	{
		$obj->{"LastUser"} = 0;
	}
	
	return $obj;
}

sub getProfileName
{
	my $obj = shift;
	my @strOptionsFilePath = split /\\/, $obj->{"OptionsFile"};
	return $strOptionsFilePath[$#strOptionsFilePath - 1];
}

sub isLastUser
{
	my $obj = shift;
	if($obj->{"LastUser"})
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub getSelectedMods
{
	my $obj = shift;
	return @{$obj->{"SelectedMods"}};
}

sub setSelectedMods
{
	my($obj, @objSelectedMods) = @_;
	my $strSelectedMods;
	
	$strSelectedMods = "\r\n\t\{mods\r\n";
	foreach my $objMod (@objSelectedMods)
	{
		$strSelectedMods .= "\t\t" . $objMod->getModSig . "\r\n";
	}
	$strSelectedMods .= "\t\}\r\n";
	
	$obj->{"OptionsInfo"} =~ s/\s*\{\s*mods\s*(\s*\{\s*\".*\"\s*\}\s*)*\s*\}\s*/${strSelectedMods}/;
}

sub storeOptionsInfo
{
	my($obj, $strAppPath) = @_;
	
	my $strLastUserFile = $strAppPath . "\\profiles\\lastuser";
	open(FH, ">", $strLastUserFile) || die $!;
	binmode FH;
	print FH "\"" . $obj->getProfileName . "\"";
	close(FH) || die $?;
	
	open(FH, ">", $obj->{"OptionsFile"}) || die $!;
	binmode FH;
	print FH $obj->{"OptionsInfo"};
	close(FH) || die $?;
}

1;

