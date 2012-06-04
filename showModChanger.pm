# showModChanger.pm

package showModChanger;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(getAppPath getModList getProfileList);

use strict;
use Win32::TieRegistry (Delimiter => "/", ArrayValues => 1);
use showMod;
use showProfile;

sub getAppPath
{
	my $refStrRegList = $Registry->{"LMachine/SOFTWARE/Codemasters/Soldiers - Heroes of World War II"}->{"INSTALL_PATH"};
	unless($refStrRegList)
	{
		return "";
	}
	my $strAppPath = $refStrRegList->[0];
	if($strAppPath =~ m/\\$/)
	{
		chop $strAppPath;
	}
	return $strAppPath;
}

sub getModList
{
	my $strAppPath = shift;
	my $strModDir = $strAppPath . "\\mods";
	my @strModDirList;
	
	if(-d $strModDir)
	{
		@strModDirList = getDirList($strModDir);
	}
	else
	{
		return 0;
	}
	
	my @objModList;
	
	foreach my $strCurDir (@strModDirList)
	{
		my $strModInfoFile = $strCurDir . "\\info.mod";
		if(-f $strModInfoFile)
		{
			my $strModInfo = getFileContent($strModInfoFile);
			if($strModInfo =~ m/^\s*\{\s*mod/)
			{
				if($strModInfo =~ m/\{\s*name\s+\"(.*)\"\s*\}/)
				{
					my($strModName, $strModDesc, $strModVersion);
					
					$strModName = $1;
					
					if($strModInfo =~ m/\{\s*desc\s+\"(.*)\"\s*\}/)
					{
						$strModDesc = $1;
					}
					else
					{
						$strModDesc = "";
					}
					if($strModInfo =~ m/\{\s*version\s+\"(.*)\"\s*\}/)
					{
						$strModVersion = $1;
					}
					else
					{
						$strModVersion = "";
					}
					
					my $objMod = showMod->new($strModName, $strModDesc, $strModVersion);
					push @objModList, $objMod;
				}
			}
		}
	}
	
	return @objModList;
}

sub getProfileList
{
	my $strAppPath = shift;
	my $strProfileDir = $strAppPath . "\\profiles";
	my @strProfileDirList;
	my $strLastUser;
	
	if(-d $strProfileDir)
	{
		my $strLastUserFile = $strProfileDir . "\\lastuser";
		if(-f $strLastUserFile)
		{
			my $strLastUserInfo = getFileContent($strLastUserFile);
			if($strLastUserInfo =~ m/\"(.*)\"/)
			{
				$strLastUser = $1;
			}
			else
			{
				$strLastUser = "";
			}
		}
		else
		{
			$strLastUser = "";
		}
		
		@strProfileDirList = getDirList($strProfileDir);
	}
	else
	{
		return 0;
	}
	
	my @objProfileList;
	
	foreach my $strCurDir (@strProfileDirList)
	{
		my $strOptionsFile = $strCurDir . "\\options";
		if(-f $strOptionsFile)
		{
			my $strOptionsInfo = getFileContent($strOptionsFile);
			if($strOptionsInfo =~ m/^\s*\{\s*options/)
			{
				my @strSelectedMods;
				if($strOptionsInfo =~ s/\s*\{\s*mods\s*(\s*\{\s*\".*\"\s*\}\s*)*\s*\}\s*/\r\n\t\{mods\}\r\n/)
				{
					my $strSelectedMods = $&;
					while($strSelectedMods =~ s/\{\s*\".*\"\s*\}//)
					{
						push @strSelectedMods, $&;
					}
				}
				else
				{
					$strOptionsInfo =~ s/\s*(\}\s*)$/\r\n\t\{mods\}\r\n/;
					$strOptionsInfo .= $1;
				}
				
				my $objProfile = showProfile->new($strOptionsFile, $strOptionsInfo, $strLastUser, @strSelectedMods);
				push @objProfileList, $objProfile;
			}
		}
	}
	
	return @objProfileList;
}

sub getDirList
{
	my $strPath = shift;
	my @strDirList;
	opendir(DH, $strPath) || die $!;
	while(my $strCurItem = readdir DH)
	{
		my $strItemPath = $strPath . "\\" . $strCurItem;
		if(($strCurItem ne ".") && ($strCurItem ne "..") && (-d $strItemPath))
		{
			push @strDirList, $strItemPath;
		}
	}
	closedir(DH) || die $?;
	return @strDirList;
}

sub getFileContent
{
	my $strFile = shift;
	open(FH, "<", $strFile) || die $!;
	binmode FH;
	read FH, my $strFileContent, -s $strFile;
	close(FH) || die $?;
	return $strFileContent;
}

1;

