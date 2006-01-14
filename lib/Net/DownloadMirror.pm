#*** DownloadMirror.pm ***#
# Copyright (C) 2006 Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#------------------------------------------------
 package Net::DownloadMirror;
#------------------------------------------------
 use strict;
 use warnings;
 use Net::MirrorDir;
 use File::Basename;
 use File::Path;
 use Storable;
#------------------------------------------------
 @Net::DownloadMirror::ISA = qw(Exporter Net::MirrorDir);
 $Net::DownloadMirror::VERSION = '0.02';
#-------------------------------------------------
 sub Update
 	{
 	my ($self) = @_;
 	$self->Connect() if(!(defined($self->{_connection})));
 	my ($ref_h_local_files, $ref_h_local_dirs) = $self->ReadLocalDir();
 	if($self->{_debug})
 		{
 		print("local files : $_\n") for(sort keys %{$ref_h_local_files});
 		print("local dirs : $_\n") for(sort keys %{$ref_h_local_dirs});
 		}
 	my ($ref_h_remote_files, $ref_h_remote_dirs) = $self->ReadRemoteDir();
 	if($self->{_debug})
 		{
 		print("remote files : $_\n") for(sort keys %{$ref_h_remote_files});
 		print("remote dirs : $_\n") for(sort keys %{$ref_h_remote_dirs});
 		}
 	my $ref_a_new_remote_files = $self->RemoteNotInLocal(
 		$ref_h_local_files, $ref_h_remote_files);
 	if($self->{_debug})
 		{
 		print("new remote files : $_\n") for(@{$ref_a_new_remote_files});
 		}
 	$self->StoreFiles($ref_a_new_remote_files) if(@{$ref_a_new_remote_files});
 	my $ref_a_new_remote_dirs = $self->RemoteNotInLocal(
 		$ref_h_local_dirs, $ref_h_remote_dirs);
 	if($self->{_debug})
 		{
 		print("new remote dirs : $_\n") for(@{$ref_a_new_remote_dirs});
 		}
 	$self->MakeDirs($ref_a_new_remote_dirs);
 	if($self->{_delete} eq "enable")
 		{
 		my $ref_a_deleted_remote_files = $self->LocalNotInRemote(
 			$ref_h_local_files, $ref_h_remote_files);
 		if($self->{_debug})
 			{
 			print("deleted remote files : $_\n") for(@{$ref_a_deleted_remote_files});
 			}
 		my $ref_a_deleted_remote_dirs = $self->LocalNotInRemote(
 			$ref_h_local_dirs, $ref_h_remote_dirs);
 		if($self->{_debug})
 			{
 			print("deleted remote files : $_\n") for(@{$ref_a_deleted_remote_dirs});
 			}
 		$self->DeleteFiles($ref_a_deleted_remote_files);
 		$self->RemoveDirs($ref_a_deleted_remote_dirs);
 		}
 	delete($ref_h_remote_files->{$_}) for(@{$ref_a_new_remote_files});
 	my $ref_a_modified_remote_files = $self->CheckIfModified($ref_h_remote_files);
 	if($self->{_debug})
 		{
 		print("modified remote files : $_\n") for(@{$ref_a_modified_remote_files});
 		}
 	$self->StoreFiles($ref_a_modified_remote_files);
 	$self->Quit();
 	return 1;
 	}
#-------------------------------------------------
 sub CheckIfModified
 	{
 	my ($self, $ref_h_remote_files) = @_;
 	my (@modified_files, $ref_last_modified, $modified_time);
 	return if(!(defined($self->{_connection})));
 	if(-f "lastmodified_remote")
 		{
 		$ref_last_modified = retrieve("lastmodified_remote");
 		}
 	else
 		{
 		warn("no information of the last modified time");
 		return [keys(%{$ref_h_remote_files})];
 		}
 	for(keys(%{$ref_h_remote_files}))
 		{
 		$modified_time = $self->{_connection}->mdtm($_);
 		if(defined($ref_last_modified->{$_}) and $modified_time)
 			{
 			if(!($ref_last_modified->{$_} eq $modified_time))
 				{
 				push(@modified_files, $_) ;
 				}
 			}
 		elsif($modified_time)
 			{
 			push(@modified_files, $_);
 			}
 		}
 	return \@modified_files;
 	}
#-------------------------------------------------
 sub StoreFiles
 	{
 	my ($self, $ref_a_files) = @_;
 	my ($l_path, $r_path, $value, $ref_last_modified);
 	return if(!(defined($self->{_connection})));
 	if(-f "lastmodified_remote")
 		{
 		$ref_last_modified = retrieve("lastmodified_remote");
 		}
 	else
 		{
 		$ref_last_modified = {};
 		}
 	for(@{$ref_a_files})
 		{
 		$l_path = $r_path = $_;
 		$self->{_connection}->cwd();
 		$value = $self->{_connection}->get($r_path);
 		$l_path =~ s!^$self->{_remotedir}!$self->{_localdir}!;
 		my ($name, $path, $sufix) = fileparse($l_path);
 		mkpath($path) if(!(-d $path));
 		open(F, ">$l_path") or
 			warn("error in open $l_path at Net::DownloadMirror::StoreFiles() : $!\n");
 		binmode(F);
 		print(F $value);
 		close(F);
 		$ref_last_modified->{$r_path} = $self->{_connection}->mdtm($r_path);
 		}
 	store($ref_last_modified, "lastmodified_remote");
 	return 1;
 	}
#-------------------------------------------------
 sub MakeDirs
 	{
 	my ($self, $ref_a_dirs) = @_;
 	my ($l_dir, $r_dir);
 	for(@{$ref_a_dirs})
 		{
 		$l_dir = $r_dir = $_;
 		$l_dir =~ s!^$self->{_remotedir}!$self->{_localdir}!;
 		mkpath($l_dir) if(!(-d $l_dir));
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub DeleteFiles
 	{
 	my ($self, $ref_a_files) = @_;
	my ($l_path, $r_path, $ref_last_modified);
 	return if(!($self->{_delete} eq "enable"));
 	if(-f "lastmodified_remote")
 		{ 
 		$ref_last_modified = retrieve("lastmodified_remote");
 		}
 	else
 		{
 		$ref_last_modified = {};
 		}
 	for(@{$ref_a_files})
 		{
 		$l_path = $r_path = $_; 
 		$r_path =~ s!^$self->{_localdir}!$self->{_remotedir}!;
 		next if(!(-f $l_path));
 		warn("can not unlink : $l_path\n") if(!(unlink($l_path)));
 		delete($ref_last_modified->{$r_path}) if(defined($ref_last_modified->{$r_path}));
 		}
 	store($ref_last_modified, "lastmodified_remote");
 	return 1;
 	} 
#-------------------------------------------------
 sub RemoveDirs
 	{
 	my ($self, $ref_a_files) = @_;
 	return if(!($self->{_delete} eq "enable"));
 	for(@{$ref_a_files})
 		{
 		next if(!(-d $_));
 		rmtree($_, $self->{_debug}, 1);
 		}
 	return 1;
 	}
#------------------------------------------------
1;
#------------------------------------------------
__END__

=head1 NAME

Net::DownloadMirror - Perl extension for mirroring a remote location via FTP to the local directory

=head1 SYNOPSIS

  use Net::DownloadMirror;
  my $um = Net::DownloadMirror->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	);
 $um->Update();
 
 or more detailed
 my $um = Net::DownloadMirror->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	localdir		=> "home/nameA/homepageA",
 	remotedir	=> "public",
 	debug		=> 1 # 1 for yes, 0 for no
 	timeout		=> 60 # default 30
 	delete		=> "enable" # default "disabled"
 	connection	=> $ftp_object, # default undef
 	exclusions	=> ["private.txt", "Thumbs.db", ".sys", ".log"],
 	);
 $um->SetLocalDir("home/nameB/homepageB");
 print("hostname : ", $um->get_ftpserver(), "\n");
 $um->Update();

=head1 DESCRIPTION

This module is for mirroring a remote location to a local directory via FTP.
For example websites, documentations or developmentstuff which ones were
uploaded or changed in the net. It is not developt for mirroring large archivs.
But there are not in principle any limits.

=head1 Constructor and Initialization

=item (object) new (options)

=head2 required optines

=item ftpserver
the hostname of the ftp-server

=item usr	
the username for authentification

=item pass
password for authentification

=head2 optional optiones

=item localdir
local directory where the downloaded or updated files are stored, default '.'

=item remotedir
remote location from where the files are downloaded, default '/' 

=item debug
set it true for more information about the download-process, default 1 

=item timeout
the timeout for the ftp-serverconnection

=item delete
if you want files or directories removed on the remote server also removed 
from the local directory set this attribute to "enable", default "disabled"

=item connection
takes a Net::FTP-object you should not use that,
it is produced automatically by the NetMirrorDir-object

=item exclusions
a reference to a list of strings interpreted as regular-expressios ("regex") 
matching to something in the local pathnames, 
you do not want to delete, default empty list [ ]
It is recommended that the local directory no critical files contains!!!

=item (value) get_option (void)
=item (1)  set_option (value)
The functions are generated by AUTOLOAD for all options.
The syntax is not case-sensitive and the character '_' is optional.

=head2 methods

=item (1) Update (void)
call this function for mirroring automatically, recommended!!!

=item (ref_hash_local_files, ref_hash_local_dirs) ReadLocalDir (void)
Returns two hashreferences first  the local-files, second the local-directorys
found in the directory, given by the DownloadMirror-object,
uses the attribute "localdir". 
The values are in the keys.

=item (ref_hash_remotefiles, ref_hash_remote_dirs) ReadRemoteDir (void)
Returns two hashreferences first the remote-files, second the remote-directorys
found in the directory, given by the DownloadMirror-object,
uses the attribute "remotedir". 
The values are in the keys.

=item (1) Connect (void)
Makes the connection to the ftp-server.
uses the attributes "ftpserver", "usr" and "pass",
given by the DownloadMirror-object.

=item (1) Quit (void)
Closes the connection with the ftp-server.

=item (ref_hash_local_paths, ref_hash_remote_paths) LocalNotInRemote (ref_list_new_paths)
Takes two hashreferences, given by the functions ReadLocalDir(); and ReadRemoteDir();
to compare with each other. Returns a reference of a list with files or directorys found in 
the local directory but not in the remote location. Uses the attribute "localdir" and 
"remotedir", given by the DownloadMirror-object.

=item (ref_hash_local_paths, ref_hash_remote_paths) RemoteNotInLocal (ref_list_deleted_paths)
Takes two hashreferences, given by the functions ReadLocalDir(); and ReadRemoteDir();
to compare with each other. Returns a reference of a list with files or directorys found in 
the remote location but not in the local directory. Uses the attribure "localdir" and 
"remotedir" given by the DownloadMirror-object.

=item (ref_hash_modified_files) CheckIfModified (ref_list_local_files)
Takes a hashreference of remote files to compare the last modification stored in a file
"lastmodified_remote" while downloading. Returns a reference of a list.

=item (1) StoreFiles (ref_list_paths)
Takes a listreference of remote-paths to download via FTP.

=item (1) MakeDirs (ref_list_paths)
Takes a listreference of directorys to make in the local directory.

=item (1) DeleteFiles (ref_list_paths)
Takes a listreference of files to delete in the local directory.

=item (1) RemoveDirs (ref_list_paths)
Takes a listreference of directories to remove in the local directory.


=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::MirrorDir
Net::UploadMirror
Tk::Mirror
http://www.planet-interkom.de/t.knorr/index.html

=head1 FILES

Net::MirrorDir
Storable
File::Basename
File::Path

=head1 BUGS

Maybe you'll find some. Let me know.

=head1 AUTHOR

Torsten Knorr, E<lt>knorrcpan@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut







