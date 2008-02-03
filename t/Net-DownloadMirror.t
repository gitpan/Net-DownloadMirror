# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DownloadMirror.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# use Test::More "no_plan";
 use Test::More tests => 54;
BEGIN { use_ok('Net::DownloadMirror') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#-------------------------------------------------
# this section will test the methods in the baseclass Net::MirrorDir
 my $mirror = Net::DownloadMirror->new(
 	localdir		=> "TestA",
 	remotedir	=> "TestD",
 	ftpserver		=> "www.net.de",
 	usr		=> 'e-mail@address.de',
 	pass		=> "xyz", 	
 	);
#-------------------------------------------------
# can we use the functions from base class Net::MirrorDir
 isa_ok($mirror, "Net::MirrorDir");
 can_ok($mirror, "Connect");
 can_ok($mirror, "IsConnection");
 can_ok($mirror, "Quit");
 can_ok($mirror, "ReadLocalDir");
 ok($mirror->ReadLocalDir('.'));
 can_ok($mirror, "ReadRemoteDir");
 can_ok($mirror, "LocalNotInRemote");
 ok($mirror->LocalNotInRemote({}, {}));
 can_ok($mirror, "RemoteNotInLocal");
 ok($mirror->RemoteNotInLocal({}, {}));
 can_ok($mirror, "AUTOLOAD");
 can_ok($mirror, "DESTROY");
#-------------------------------------------------
 ok($mirror->Set_Remotedir("TestA"));
 ok("TestA" eq $mirror->get_remotedir());
 ok($mirror->SetLocaldir("TestB"));
 ok("TestB" eq $mirror->GetLocaldir());
#-------------------------------------------------
# test attribute "subset"
 ok($mirror->SetSubset([]));
 ok($mirror->AddSubset("test_1"));
 ok("test_1" eq $mirror->GetSubset()->[0]);
 ok($mirror->AddSubset("test_2"));
 ok("test_2" eq $mirror->GetSubset()->[1]);
 ok($mirror->add_subset("test_3"));
 ok("test_3" eq $mirror->get_subset()->[2]);
 my $count = 0;
 for my $regex (@{$mirror->{_regex_subset}})
 	{
 	for("---test_1---", "---test_2---", "---test_3---")
 		{
 		$count++ if(/$regex/)
 		}
 	}
 ok($count == 3);
#-------------------------------------------------
# test attribute "exclusions"
 ok($mirror->SetExclusions([qr/test_1/]));
 ok($mirror->AddExclusions(qr/test_2/));
 ok($mirror->add_exclusions(qr/test_3/));
 $count = 0;
 for my $regex (@{$mirror->get_regex_exclusions()})
 	{
 	for("xxxtest_1xxx", "xxxtest_2xxx", "xxxtest_3xxx")
 		{
 		$count++ if(/$regex/);
 		}
 	}
 ok($count == 3);
#-------------------------------------------------
# tests for "filename"
 ok($mirror->GetFileName() eq "lastmodified_remote");
 ok($mirror->SetFileName("modtime"));
 ok($mirror->GetFileName() eq "modtime");
 ok(unlink("lastmodified_remote"));
 ok(unlink("modtime"));
#-------------------------------------------------
# tests for Net::DownloadMirror methods
 isa_ok($mirror, "Net::MirrorDir");
 isa_ok($mirror, "Net::DownloadMirror");
 can_ok($mirror, "_Init");
 ok($mirror->_Init());
 can_ok($mirror, "Update");
 can_ok($mirror, "StoreFiles");
 ok(!$mirror->StoreFiles([]));
 can_ok($mirror, "CheckIfModified");
 ok($mirror->CheckIfModified({}));
 can_ok($mirror, "MakeDirs");
 ok(!$mirror->MakeDirs([]));
 can_ok($mirror, "DeleteFiles");
 ok($mirror->SetDelete("enable"));
 ok(!$mirror->DeleteFiles([]));
 can_ok($mirror, "RemoveDirs");
 ok(!$mirror->RemoveDirs([]));
 ok($mirror->SetDelete("disabled"));
#-------------------------------------------------
 SKIP:
 	{
	print(STDERR "\nWould you like to  test the module with a ftp-server?[y|n]: ");
 	my $response = <STDIN>;
 	skip("no tests with ftp-server\n", 2) if(!($response =~ m/^y/i));
 	print(STDERR "\nPlease enter the hostname of the ftp-server: ");
 	my $s = <STDIN>;
 	chomp($s);
 	print(STDERR "\nPlease enter your user name: ");
 	my $u = <STDIN>;
 	chomp($u);
 	print(STDERR "\nPlease enter your password : ");
 	my $p = <STDIN>;
 	chomp($p);
	print(STDERR "\nPlease enter the local-directory : ");
 	my $l = <STDIN>;
 	chomp($l);
 	print(STDERR "\nPease enter the remote-directory : ");
 	my $r = <STDIN>;
 	chomp($r);
 	ok(my $m = Net::DownloadMirror->new(
 		localdir		=> $l,
 		remotedir	=> $r,
 		ftpserver		=> $s,
 		usr		=> $u,
 		pass		=> $p, 	
 		filename		=> "mtimes"
 		));
 	ok($m->Update());
 	};
#-------------------------------------------------

