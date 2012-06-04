# showModChanger.pl

use strict;
use showModChanger qw(getAppPath getModList getProfileList);
use Tk;
require Tk::BrowseEntry;
require Tk::ROText;
use Win32::Process;

my $MainWindow = new MainWindow;
$MainWindow->title("Soldiers: Heroes of World War II - ModChanger");
my $fMain = $MainWindow->Frame()->pack(-padx => 5, -pady => 5);

my $strErrMsg = "";

my $strAppPath = getAppPath();
my @objModList = getModList($strAppPath);
my @objProfileList = getProfileList($strAppPath);

if(!$strAppPath)
{
	$strErrMsg = "Unable to retrieve \"Application Path\" from Registry!";
}
elsif(($#objModList == 0) && ($objModList[0] == 0))
{
	$strErrMsg = "Directory \"mods\" not found!";
}
elsif($#objModList == -1)
{
	$strErrMsg = "No \"Mods\" installed!";
}
elsif(($#objProfileList == 0) && ($objProfileList[0] == 0))
{
	$strErrMsg = "Directory \"profiles\" not found!";
}
elsif($#objProfileList == -1)
{
	$strErrMsg = "No \"Profiles\" available!";
}

my($fTop, $fMiddle, $fMLeft, $fMCenter, $fMRight, $fBottom, $fBLeft, $fBRight, $beProfiles, $beProfile, $lbMods, $lbProfiles, $rotModDesc, $lHelp, $objSelectedProfile, @objNotSelectedMods, @objSelectedMods);

if($strErrMsg)
{
	$MainWindow->minsize(qw(381 71));
	$MainWindow->maxsize(qw(381 71));
	
	$fMain->Label(-text => $strErrMsg)->pack;
	$fMain->Button(-text => "EXIT", -command => sub{$MainWindow->destroy;})->pack;
	$lHelp = $fMain->Label(-text => "?", -foreground => "blue")->pack;
	$lHelp->bind("<ButtonRelease-1>", \&showInfo);
}
else
{
	$MainWindow->minsize(qw(435 350));
	$MainWindow->maxsize(qw(435 350));
	
	$fTop = $fMain->Frame()->pack(-padx => 5, -pady => 5, -fill => "x");
	$fTop->Label(-text => "MODS SETUP")->pack(-side => "left");
	$beProfiles = $fTop->BrowseEntry(-label => "PROFILE", -variable => \$beProfile, -browsecmd => \&selectProfile, -state => "readonly")->pack(-side => "right");
	for(my $i = 0; $i <= $#objProfileList; $i++)
	{
		$beProfiles->insert("end", $objProfileList[$i]->getProfileName);
	}
	
	$fMiddle = $fMain->Frame()->pack(-padx => 5, -pady => 5);
	
	$fMLeft = $fMiddle->Frame()->pack(-side => "left");
	$fMLeft->Label(-text => "Installed mods:")->pack;
	$lbMods = $fMLeft->Scrolled("Listbox", -scrollbars => "osoe", -height => 8)->pack;
	$lbMods->bind("<ButtonPress-1>", [\&setModDesc, "mods"]);
	
	$fMCenter = $fMiddle->Frame()->pack(-side => "left");
	$fMCenter->Button(-text => ">", -command => \&shiftRight)->pack;
	$fMCenter->Button(-text => "<", -command => \&shiftLeft)->pack;
	
	$fMRight = $fMiddle->Frame()->pack(-side => "left");
	$fMRight->Label(-text => "Selected mods:")->pack;
	$lbProfiles = $fMRight->Scrolled("Listbox", -scrollbars => "osoe", -height => 8)->pack;
	$lbProfiles->bind("<ButtonPress-1>", [\&setModDesc, "profiles"]);
	
	$fBottom = $fMain->Frame()->pack;
	
	$fBLeft = $fBottom->Frame()->pack(-padx => 5, -pady => 5, -side => "left");
	$fBLeft->Label(-text => "Mod info:")->pack;
	$rotModDesc = $fBLeft->Scrolled("ROText", -wrap => "none", -scrollbars => "osoe", -width => 48, -height => 8)->pack;
	
	$fBRight = $fBottom->Frame()->pack(-padx => 5, -pady => 5, -side => "left");
	$fBRight->Button(-text => "APPLY", -command => \&apply, -width => 6)->pack;
	$fBRight->Button(-text => "EXIT", -command => sub{$MainWindow->destroy;}, -width => 6)->pack;
	$lHelp = $fBRight->Label(-text => "?", -foreground => "blue")->pack;
	$lHelp->bind("<ButtonRelease-1>", \&showInfo);
	
	my($objProfileLastUser) = grep {$_->isLastUser;} @objProfileList;
	if($objProfileLastUser)
	{
		$beProfile = $objProfileLastUser->getProfileName;
		selectProfile();
	}
}

MainLoop;

sub selectProfile
{
	($objSelectedProfile) = grep {$_->getProfileName eq $beProfile;} @objProfileList;
	
	my @strSelectedMods = $objSelectedProfile->getSelectedMods;
	
	@objNotSelectedMods = ();
	@objSelectedMods = ();
	
	@objNotSelectedMods = @objModList;
	
	for(my $i = 0; $i <= $#strSelectedMods; $i++)
	{
		for(my $j = 0; $j <= $#objNotSelectedMods; $j++)
		{
			if($strSelectedMods[$i] eq $objNotSelectedMods[$j]->getModSig)
			{
				push @objSelectedMods, splice @objNotSelectedMods, $j, 1;
				last;
			}
		}
	}
	
	reBuildListBox();
}

sub setModDesc
{
	my($lb, $lbID) = @_;
	my $strModName;
	
	if($lbID eq "mods")
	{
		$strModName = $lbMods->get("anchor");
	}
	elsif($lbID eq "profiles")
	{
		$strModName = $lbProfiles->get("anchor");
	}
	
	if($strModName)
	{
		my($objSelectedMod) = grep {$_->getModName eq $strModName;} @objModList;
		my @strModDescList = $objSelectedMod->getModDescList;
		
		$rotModDesc->delete(0.1, "end");
		
		foreach my $strModDescLine (@strModDescList)
		{
			$rotModDesc->insert("end", $strModDescLine);
			$rotModDesc->openLine;
			$rotModDesc->SetCursor("end");
		}
	}
}

sub shiftRight
{
	if(@objNotSelectedMods)
	{
		my $strSelectedModName = $lbMods->get("anchor");
		if($strSelectedModName)
		{
			push @objSelectedMods, grep {$_->getModName eq $strSelectedModName} @objNotSelectedMods;
			@objNotSelectedMods = grep {$_->getModName ne $strSelectedModName} @objNotSelectedMods;
			reBuildListBox();
		}
	}
}

sub shiftLeft
{
	if(@objSelectedMods)
	{
		my $strSelectedModName = $lbProfiles->get("anchor");
		if($strSelectedModName)
		{
			push @objNotSelectedMods, grep {$_->getModName eq $strSelectedModName} @objSelectedMods;
			@objSelectedMods = grep {$_->getModName ne $strSelectedModName} @objSelectedMods;
			reBuildListBox();
		}
	}
}

sub apply
{
	if($objSelectedProfile)
	{
		$objSelectedProfile->setSelectedMods(@objSelectedMods);
		$objSelectedProfile->storeOptionsInfo($strAppPath);
	}
}

sub reBuildListBox
{
	for(my $i = 0; $i <= $#objNotSelectedMods; $i++)
	{
		for(my $j = 0; $j <= ($#objNotSelectedMods - 1); $j++)
		{
			if($objNotSelectedMods[$j]->getModName gt $objNotSelectedMods[$j + 1]->getModName)
			{
				my $objTemp = $objNotSelectedMods[$j];
				$objNotSelectedMods[$j] = $objNotSelectedMods[$j + 1];
				$objNotSelectedMods[$j + 1] = $objTemp;
			}
		}
	}
	
	$lbMods->delete(0, "end");
	map {$lbMods->insert("end", $_->getModName);} @objNotSelectedMods;
	
	$lbProfiles->delete(0, "end");
	map {$lbProfiles->insert("end", $_->getModName);} @objSelectedMods;
	
	$rotModDesc->delete(0.1, "end");
}

sub showInfo
{
	Win32::Process::Create(my $objProcess, $ENV{"SYSTEMROOT"} . "\\system32\\notepad.exe", "notepad.exe showModChanger.txt", 0, NORMAL_PRIORITY_CLASS, ".") || die Win32::FormatMessage(Win32::GetLastError());
	$objProcess->Wait(0);
}

