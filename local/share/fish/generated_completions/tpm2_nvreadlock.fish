# tpm2_nvreadlock
# Autogenerated from man page /usr/share/man/man1/tpm2_nvreadlock.1.gz
complete -c tpm2_nvreadlock -s C -l hierarchy
complete -c tpm2_nvreadlock -s P -l auth -d 'Specifies the authorization value for the hierarchy'
complete -c tpm2_nvreadlock -l cphash -d 'File path to record the hash of the command parameters'
complete -c tpm2_nvreadlock -l rphash -d 'File path to record the hash of the response parameters'
complete -c tpm2_nvreadlock -s S -l session -d 'The session created using tpm2_startauthsession'
complete -c tpm2_nvreadlock -s n -l name -d 'The name of the NV index that must be provided when only calculating the cpHa…'
complete -c tpm2_nvreadlock -s h -l help -d manpage
complete -c tpm2_nvreadlock -s v -l version -d 'this tool, supported tctis and exit.  [bu] 2'
complete -c tpm2_nvreadlock -s V -l verbose -d 'tool prints to the console during its execution'
complete -c tpm2_nvreadlock -s Q -l quiet -d 'stdout.  [bu] 2'
complete -c tpm2_nvreadlock -s Z -l enable-errata -d 'errata fixups'
complete -c tpm2_nvreadlock -s a
