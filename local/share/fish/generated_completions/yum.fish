# yum
# Autogenerated from man page /usr/share/man/man8/yum.8.gz
complete -c yum -s 4 -d 'Resolve to IPv4 addresses only'
complete -c yum -s 6 -d 'Resolve to IPv6 addresses only'
complete -c yum -l advisory -l advisories -d 'Include packages corresponding to the advisory ID, Eg.  FEDORA-2201-123'
complete -c yum -l allowerasing -d 'Allow erasing of installed packages to resolve dependencies'
complete -c yum -l assumeno -d 'Automatically answer no for all questions'
complete -c yum -s b -l best -d 'Try the best available package versions in transactions'
complete -c yum -l bugfix -d 'Include packages that fix a bugfix issue'
complete -c yum -l bz -l bzs -d 'Include packages that fix a Bugzilla ID, Eg.  123123'
complete -c yum -s C -l cacheonly -d 'Run entirely from system cache, don\'t update the cache and use it even in cas…'
complete -c yum -l color -d 'Control whether color is used in terminal output'
complete -c yum -l comment -d 'Add a comment to the transaction history'
complete -c yum -s c -l config -d 'Configuration file location'
complete -c yum -l cve -l cves -d 'Include packages that fix a CVE (Common Vulnerabilities and Exposures) ID (\\%…'
complete -c yum -s d -l debuglevel -d 'Debugging output level'
complete -c yum -l debugsolver -d 'Dump data aiding in dependency solver debugging into . /debugdata'
complete -c yum -l disable -l set-disabled -d 'Disable specified repositories (automatically saves)'
complete -c yum -l disableplugin -d 'Disable the listed plugins specified by names or globs'
complete -c yum -l disablerepo -d 'Temporarily disable active repositories for the purpose of the current dnf co…'
complete -c yum -l downloaddir -l destdir -d 'Redirect downloaded packages to provided directory'
complete -c yum -l downloadonly -d 'Download the resolved package set without performing any rpm transaction (ins…'
complete -c yum -s e -l errorlevel -d 'Error output level'
complete -c yum -l enable -l set-enabled -d 'Enable specified repositories (automatically saves)'
complete -c yum -l enableplugin -d 'Enable the listed plugins specified by names or globs'
complete -c yum -l enablerepo -d 'Temporarily enable additional repositories for the purpose of the current dnf…'
complete -c yum -l enhancement -d 'Include enhancement relevant packages'
complete -c yum -s x -l exclude -d 'Exclude packages specified by <package-file-spec> from the operation'
complete -c yum -l excludepkgs -d 'Deprecated option.  It was replaced by the -\\%-exclude option'
complete -c yum -l forcearch -d 'Force the use of an architecture.  Any architecture can be specified'
complete -c yum -s h -l help -l help-cmd -d 'Show the help'
complete -c yum -l installroot -d 'Specifies an alternative installroot, relative to where all packages will be …'
complete -c yum -l releasever -d 'Permanently sets the releasever of the system in the <installroot> directory …'
complete -c yum -l setopt -d 'Upgrades packages inside the installroot from a repository described by --set…'
complete -c yum -l newpackage -d 'Include newpackage relevant packages'
complete -c yum -l noautoremove -d 'Disable removal of dependencies that are no longer used'
complete -c yum -l nobest -d 'Set best option to False, so that transactions are not limited to best candid…'
complete -c yum -l nodocs -d 'Do not install documentation.  Sets the rpm flag \'RPMTRANS_FLAG_NODOCS\''
complete -c yum -l nogpgcheck -d 'Skip checking GPG signatures on packages (if RPM policy allows)'
complete -c yum -l noplugins -d 'Disable all plugins'
complete -c yum -l obsoletes -d 'This option has an effect on an install/update, it enables dnf\'s obsoletes pr…'
complete -c yum -s q -l quiet -d 'In combination with a non-interactive command, shows just the relevant content'
complete -c yum -s R -l randomwait -d 'Maximum command wait time'
complete -c yum -l refresh -d 'Set metadata as expired before running the command'
complete -c yum -l repofrompath -d 'Specify a repository to add to the repositories for this query'
complete -c yum -l repo -l repoid -d 'Enable just specific repositories by an id or a glob'
complete -c yum -l rpmverbosity -d 'RPM debug scriptlet output level'
complete -c yum -l sec-severity -l secseverity -d 'Includes packages that provide a fix for an issue of the specified severity'
complete -c yum -l security -d 'Includes packages that provide a fix for a security issue'
complete -c yum -l skip-broken -d 'Resolve depsolve problems by removing packages that are causing problems from…'
complete -c yum -l showduplicates -d 'Show duplicate packages in repositories'
complete -c yum -s v -l verbose -d 'Verbose operation, show debug messages'
complete -c yum -l version -d 'Show DNF version and exit'
complete -c yum -s y -l assumeyes -d 'Automatically answer yes for all questions'
complete -c yum -l disableexcludes -l disableexcludepkgs -d 'Disable the configuration file excludes'
complete -c yum -l duplicates -l obsoleted -l provides -d 'check everything).  Check-Update Command'
complete -c yum -l reverse -d 'The order of history list output is printed in reverse order'
complete -c yum -l ignore-installed -d 'Don\'t check for the installed packages being in the same state as those recor…'
complete -c yum -l ignore-extras -d 'Don\'t check for extra packages pulled into the transaction on the target syst…'
complete -c yum -l skip-unavailable -d 'In case some packages stored in the transaction are not available on the targ…'
complete -c yum -s o -l output -d 'Store the serialized transaction into <output-file.  Default is transaction'
complete -c yum -o '%-skip-broken'
complete -c yum -s a -l all -d 'Query all packages (for rpmquery compatibility, also a shorthand for repoquer…'
complete -c yum -l arch -l archlist -d 'Limit the resulting set only to packages of selected architectures (default i…'
complete -c yum -l unneeded -d 'Limit the resulting set to leaves packages that were installed as dependencie…'
complete -c yum -l available -d 'Limit the resulting set to available packages only (set by default)'
complete -c yum -l disable-modular-filtering -d 'Disables filtering of modular packages, so that packages of inactive module s…'
complete -c yum -l extras -d 'Limit the resulting set to packages that are not present in any of the availa…'
complete -c yum -s f -l file -d 'Limit the resulting set only to the package that owns <file>'
complete -c yum -l installed -d 'Limit the resulting set to installed packages only'
complete -c yum -l installonly -d 'Limit the resulting set to installed installonly packages'
complete -c yum -l latest-limit -d 'Limit the resulting set to <number> of latest packages for every package name…'
complete -c yum -l recent -d 'Limit the resulting set to packages that were recently edited'
complete -c yum -l unsatisfied -d 'Report unsatisfied dependencies among installed packages (i. e'
complete -c yum -l upgrades -d 'Limit the resulting set to packages that provide an upgrade for some already …'
complete -c yum -l userinstalled -d 'Limit the resulting set to packages installed by the user'
complete -c yum -l whatdepends -d 'Limit the resulting set only to packages that require, enhance, recommend, su…'
complete -c yum -l whatconflicts -d 'Limit the resulting set only to packages that conflict with any of <capabilit…'
complete -c yum -l whatenhances -d 'Limit the resulting set only to packages that enhance any of <capabilities>'
complete -c yum -l whatobsoletes -d 'Limit the resulting set only to packages that obsolete any of <capabilities>'
complete -c yum -l whatprovides -d 'Limit the resulting set only to packages that provide any of <capabilities>'
complete -c yum -l whatrecommends -d 'Limit the resulting set only to packages that recommend any of <capabilities>'
complete -c yum -l whatrequires -d 'Limit the resulting set only to packages that require any of <capabilities>'
complete -c yum -l whatsuggests -d 'Limit the resulting set only to packages that suggest any of <capabilities>'
complete -c yum -l whatsupplements -d 'Limit the resulting set only to packages that supplement any of <capabilities>'
complete -c yum -l alldeps -d 'This option is stackable with --whatrequires or -%-whatdepends only'
complete -c yum -l exactdeps -d 'This option is stackable with --whatrequires or -%-whatdepends only'
complete -c yum -l srpm -d 'Operate on the corresponding source RPM'
complete -c yum -s i -l info -d 'Show detailed information about the package'
complete -c yum -s l -l list -d 'Show the list of files in the package'
complete -c yum -s s -l source -d 'Show the package source RPM name'
complete -c yum -l changelogs -d 'Print the package changelogs'
complete -c yum -l conflicts -d 'Display capabilities that the package conflicts with'
complete -c yum -l depends -d 'Display capabilities that the package depends on, enhances, recommends, sugge…'
complete -c yum -l enhances -d 'Display capabilities enhanced by the package.  Same as --qf "%{enhances}""'
complete -c yum -l location -d 'Show a location where the package could be downloaded from'
complete -c yum -l recommends -d 'Display capabilities recommended by the package'
complete -c yum -l requires -d 'Display capabilities that the package depends on.  Same as --qf "%{requires}"'
complete -c yum -l requires-pre -d 'Display capabilities that the package depends on for running a %pre script'
complete -c yum -l suggests -d 'Display capabilities suggested by the package.  Same as --qf "%{suggests}"'
complete -c yum -l supplements -d 'Display capabilities supplemented by the package'
complete -c yum -l tree -d 'Display a recursive tree of packages with capabilities specified by one of th…'
complete -c yum -l deplist -d 'Produce a list of all direct dependencies and what packages provide those dep…'
complete -c yum -l nvr -d 'Show found packages in the name-version-release format.  Same as'
complete -c yum -l qf
complete -c yum -l nevra -d 'Show found packages in the name-epoch:version-release. architecture format'
complete -c yum -l envra -d 'Show found packages in the epoch:name-version-release. architecture format'
complete -c yum -l queryformat -d 'Custom display format'
complete -c yum -l recursive -d 'Query packages recursively'
complete -c yum -l resolve
complete -c yum -l with-bz -d 'of the --list is altered - the ID of the CVE or the bugzilla is printed inste…'

