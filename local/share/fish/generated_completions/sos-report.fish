# sos-report
# Autogenerated from man page /usr/share/man/man1/sos-report.1.gz
complete -c sos-report -s l -l list-plugins -d 'List all available plugins and their options'
complete -c sos-report -s n -l skip-plugins -d 'Disable the specified plugin(s)'
complete -c sos-report -s e -l enable-plugins -d 'Enable the specified plugin(s) that would otherwise be disabled'
complete -c sos-report -s o -l only-plugins -d 'Enable the specified plugin(s) only (all other plugins should be disabled)'
complete -c sos-report -s k -l plugin-option -d 'Specify plug-in options'
complete -c sos-report -s a -l alloptions -d 'Set all boolean options to True for all enabled plug-ins'
complete -c sos-report -s v -l verbose -d 'Increase logging verbosity'
complete -c sos-report -s q -l quiet -d 'Only log fatal errors to stderr'
complete -c sos-report -l no-report -d 'Disable HTML report writing'
complete -c sos-report -l config-file -d 'Specify alternate configuration file'
complete -c sos-report -l no-postproc -d 'Disable postprocessing globally for all plugins'
complete -c sos-report -l preset -d 'Specify an existing preset to use for sos options'
complete -c sos-report -l add-preset -d 'Add a preset with name ADD_PRESET that enables [options] when called'
complete -c sos-report -l del-preset -d 'Deletes the preset with name DEL_PRESET from the filesystem so that it can no…'
complete -c sos-report -l list-presets -d 'Display a list of available presets and what options they carry'
complete -c sos-report -l desc -d 'When using --add-preset use this option to add a description of the preset th…'
complete -c sos-report -s s -l sysroot -d 'Specify an alternate root file system path'
complete -c sos-report -s c -l chroot -d 'Set the chroot mode'
complete -c sos-report -l tmp-dir -d 'Specify alternate temporary directory to copy data as well as the compressed …'
complete -c sos-report -l list-profiles -d 'Display a list of available profiles and the plugins that they enable'
complete -c sos-report -s p -l profile -l profiles -d 'Only run plugins that correspond to the given profile'
complete -c sos-report -l verify -d 'Instructs plugins to perform plugin-specific verification during data collect…'
complete -c sos-report -l log-size -d 'Places a limit on the size of collected logs and output in MiB'
complete -c sos-report -l journal-size -d 'Places a limit on the size of journals collected in MiB'
complete -c sos-report -l all-logs -d 'Tell plugins to collect all possible log data ignoring any size limits and in…'
complete -c sos-report -l since -d 'Limits the collection of log archives to those newer than this date'
complete -c sos-report -l skip-commands -d 'A comma delimited list of commands to skip execution of, but still allowing t…'
complete -c sos-report -l skip-files -d 'A comma delimited list of files or filepath wildcard matches to skip collecti…'
complete -c sos-report -l allow-system-changes -d 'Run commands even if they can change the system (e. g.  load kernel modules)'
complete -c sos-report -l low-priority -d 'Set sos to execute as a low priority process so that is does not interfere wi…'
complete -c sos-report -l encrypt -d 'Encrypt the resulting archive, and determine the method by which that encrypt…'
complete -c sos-report -l encrypt-key -d 'Encrypts the resulting archive that sosreport produces using GPG'
complete -c sos-report -l encrypt-pass -d 'The same as --encrypt-key, but use the provided PASS for symmetric encryption…'
complete -c sos-report -l batch -d 'Generate archive without prompting for interactive input'
complete -c sos-report -l name -d 'Deprecated.  See --label'
complete -c sos-report -l label -d 'Specify an arbitrary identifier to associate with the archive'
complete -c sos-report -l threads -d 'Specify the number of threads sosreport will use for concurrency'
complete -c sos-report -l plugin-timeout -d 'Specify a timeout in seconds to allow each plugin to run for'
complete -c sos-report -l cmd-timeout -d 'Specify a timeout limit in seconds for a command execution'
complete -c sos-report -l namespaces -d 'For plugins that iterate collections over namespaces that exist on the system…'
complete -c sos-report -l container-runtime -d 'Force the use of the specified RUNTIME as the default runtime that plugins wi…'
complete -c sos-report -l case-id -d 'Specify a case identifier to associate with the archive'
complete -c sos-report -l build -d 'Do not archive copied data'
complete -c sos-report -l debug -d 'Enable interactive debugging using the python debugger'
complete -c sos-report -l dry-run -d 'Execute plugins as normal, but do not collect any file content, command outpu…'
complete -c sos-report -l estimate-only -d 'Estimate disk space requirements when running sos report'
complete -c sos-report -l upload -d 'If specified, attempt to upload the resulting archive to a vendor defined loc…'
complete -c sos-report -l upload-url -d 'If a vendor does not provide a default upload location, or if you would like …'
complete -c sos-report -l upload-user -d 'If a vendor does not provide a default user for uploading, specify the userna…'
complete -c sos-report -l upload-pass -d 'Specify the password to use for authentication with the destination server'
complete -c sos-report -l upload-directory -d 'Specify a directory to upload to, if one is not specified by a vendor default…'
complete -c sos-report -l upload-method -d 'Specify the HTTP method to use for uploading to the provided --upload-url'
complete -c sos-report -l upload-no-ssl-verify -d 'Disable SSL verification for HTTPS uploads'
complete -c sos-report -l upload-protocol -d 'Manually specify the protocol to use for uploading to the target upload-url'
complete -c sos-report -l experimental -d 'Enable plugins marked as experimental'
complete -c sos-report -s z -l compression-type -d 'Override the default compression type specified by the active policy'
complete -c sos-report -l help -d 'Display usage message.  SEE ALSO sos (1) sos-clean (1) sos-collect (1) sos'

