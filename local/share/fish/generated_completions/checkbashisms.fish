# checkbashisms
# Autogenerated from man page /usr/share/man/man1/checkbashisms.1.gz
complete -c checkbashisms -l help -s h -d 'Show a summary of options'
complete -c checkbashisms -l newline -s n -d 'Check for "echo -n" usage (non POSIX but required by Debian Policy 10. 4. )'
complete -c checkbashisms -l posix -s p -d 'Check for issues which are non POSIX but required to be supported by Debian P…'
complete -c checkbashisms -l force -s f -d 'Force each script to be checked, even if it would normally not be (for instan…'
complete -c checkbashisms -l lint -s l -d 'Act like a linter, for integration into a text editor'
complete -c checkbashisms -l extra -s x -d 'Highlight lines which, whilst they do not contain bashisms, may be useful in …'
complete -c checkbashisms -l early-fail -s e -d 'Exit right after a first error is seen'
complete -c checkbashisms -l version -s v -d 'Show version and copyright information'

