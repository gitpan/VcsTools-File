use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	   => 'VcsTools-File',
   'VERSION' => '1.004',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   ($] >= 5.005 ?
    (ABSTRACT   => 'VCS file management tools',
     AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)') : ()),
   'PREREQ_PM' =>
   {
    'Getopt::Long' => 0,
    'Puppet::Body' => '1.013',
    'VcsTools::History' => '1.007',
    'VcsTools::LogParser' => '1.003',
    'VcsTools::Version' => '1.006',
    'File::chmod' => '0.31',
    'Time::Local' => 0,
    'MLDBM' => 0,
    'DB_File' =>0,
    'Storable' => 0,
    'String::ShellQuote' => 0
   }
  );
