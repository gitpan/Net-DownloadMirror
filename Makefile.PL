use 5.009002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::DownloadMirror',
    VERSION_FROM      => 'lib/Net/DownloadMirror.pm', # finds $VERSION
    PREREQ_PM         => {
 		"Net::MirrorDir", 
 		"File::Basename",
 		"File::Path",
 		"Storable",
 		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/DownloadMirror.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Knorr <knorrcpan@tiscali.de>') : ()),
);

