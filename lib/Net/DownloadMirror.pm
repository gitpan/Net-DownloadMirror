#*** DownloadMirror.pm ***#
# Copyright (C) 2006 - 2008 by Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#------------------------------------------------
 package Net::DownloadMirror;
#------------------------------------------------
 use strict;
 use Net::MirrorDir;
 use File::Basename;
 use File::Path;
 use Storable;
#------------------------------------------------
 @Net::DownloadMirror::ISA = qw(Net::MirrorDir);
 $Net::DownloadMirror::VERSION = '0.05';
#-------------------------------------------------
 sub _Init
 	{
 	my ($self, %arg) = @_;
 	$self->{_file_name} = $arg{file_name} || "lastmodified_remote";
 	if(-f $self->{_file_name})
 		{
 		$self->{_last_modified} = retrieve($self->{_file_name});
 		}
 	else
 		{
 		$self->{_last_modified} = {};
 		store($self->{_last_modified}, $self->{_file_name});
 		warn("\nno information of the files last modified times\n");
 		return(0);
 		}
 	return(1);
 	}
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
 	return(1);
 	}
#-------------------------------------------------
 sub CheckIfModified
 	{
 	my ($self, $ref_h_remote_files) = @_;
 	my (@modified_files, $ref_last_modified, $modified_time);
 	return(0) if(!(defined($self->{_connection})));
 	for(keys(%{$ref_h_remote_files}))
 		{
 		$modified_time = $self->{_connection}->mdtm($_);
 		if(defined($self->{_last_modified}{$_}) and $modified_time)
 			{
 			next if($self->{_last_modified}{$_} eq $modified_time);
 			}
 		push(@modified_files, $_) if($modified_time);
 		}
 	return(\@modified_files);
 	}
#-------------------------------------------------
 sub StoreFiles
 	{
 	my ($self, $ref_a_files) = @_;
 	my ($l_path, $r_path, $value, $ref_last_modified);
 	return(0) if(!(defined($self->{_connection})));
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
 		$self->{_last_modified}{$r_path} = $self->{_connection}->mdtm($r_path);
 		}
 	store($self->{_last_modified}, $self->{_file_name});
 	return(1);
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
 	return(1);
 	}
#-------------------------------------------------
 sub DeleteFiles
 	{
 	my ($self, $ref_a_files) = @_;
	my ($l_path, $r_path, $ref_last_modified);
 	return(0) if(!($self->{_delete} eq "enable"));
 	for(@{$ref_a_files})
 		{
 		$l_path = $r_path = $_; 
 		$r_path =~ s!^$self->{_localdir}!$self->{_remotedir}!;
 		next if(!(-f $l_path));
 		warn("can not unlink : $l_path\n") if(!(unlink($l_path)));
 		delete($self->{_last_modified}{$r_path}) if(defined($self->{_last_modified}{$r_path}));
 		}
 	store($self->{_last_modified}, $self->{_file_name});
 	return(1);
 	} 
#-------------------------------------------------
 sub RemoveDirs
 	{
 	my ($self, $ref_a_files) = @_;
 	return(0) if(!($self->{_delete} eq "enable"));
 	for(@{$ref_a_files})
 		{
 		next if(!(-d $_));
 		rmtree($_, $self->{_debug}, 1);
 		}
 	return(1);
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
 my $md = Net::DownloadMirror->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	localdir		=> "home/nameA/homepageA",
 	remotedir	=> "public",
 	debug		=> 1 # 1 for yes, 0 for no
 	timeout		=> 60 # default 30
 	delete		=> "enable" # default "disabled"
 	connection	=> $ftp_object, # default undef
# "exclusions" default empty arrayreferences [ ]
 	exclusions	=> ["private.txt", "Thumbs.db", ".sys", ".log"],
# "subset" default empty arrayreferences [ ]
 	subset		=> [".txt, ".pl", ".html", "htm", ".gif", ".jpg", ".css", ".js", ".png"],
# or substrings in pathnames
#	exclusions	=> ["psw", "forbidden_code"]
#	subset		=> ["name", "my_files"]
# or you can use regular expressions
# 	exclusinos	=> [qr/SYSTEM/i, $regex]
# 	subset		=> {qr/(?i:HOME)(?i:PAGE)?/, $regex]
 	file_name	=> "modified_times",
 	);
 $um->Update();

=head1 DESCRIPTION

This module is for mirroring a remote location to a local directory via FTP.
For example websites, documentations or developmentstuff which ones were
uploaded or changed in the net. It is not developt for mirroring large archivs.
But there are not in principle any limits.

=head1 Constructor and Initialization
=item (object) new (options)
 Net::DownloadMirror is a derived class from Net::MirrorDir.
 For detailed information about constructor or options
 read the documentation of Net::MirrorDir.

=head2 methods

=item (1) _Init(%arg)
 This function is called by the constructor.
 You do not need to call this function by yourself.

=item (1) Update (void)
 Call this function for mirroring automatically, recommended!!!

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

=head2 optional optiones

=item file_name
 The name of the file in which the last modified times will be stored.
 default = "lastmodified_remote"
 
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

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

=head1 AUTHOR

Torsten Knorr, E<lt>create-soft@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2008 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut


