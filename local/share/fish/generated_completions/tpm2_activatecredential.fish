# tpm2_activatecredential
# Autogenerated from man page /usr/share/man/man1/tpm2_activatecredential.1.gz
complete -c tpm2_activatecredential -s c -l credentialedkey-context -d 'Object associated with the created certificate by CA'
complete -c tpm2_activatecredential -s C -l credentialkey-context -d 'The loaded object used to decrypt the random seed'
complete -c tpm2_activatecredential -s p -l credentialedkey-auth -d 'The auth value of the credentialed object specified with -c'
complete -c tpm2_activatecredential -s P -l credentialkey-auth -d 'The auth value of the credential object specified with -C'
complete -c tpm2_activatecredential -s i -l credential-blob -d 'The input file path containing the credential blob and secret created with th…'
complete -c tpm2_activatecredential -s o -l certinfo-data -d 'The output file path to save the decrypted credential secret information'
complete -c tpm2_activatecredential -l cphash -d 'File path to record the hash of the command parameters'
complete -c tpm2_activatecredential -l rphash -d 'File path to record the hash of the response parameters'
complete -c tpm2_activatecredential -s S -l session -d 'The session created using tpm2_startauthsession'
complete -c tpm2_activatecredential -s h -l help -d manpage
complete -c tpm2_activatecredential -s v -l version -d 'this tool, supported tctis and exit.  [bu] 2'
complete -c tpm2_activatecredential -s V -l verbose -d 'tool prints to the console during its execution'
complete -c tpm2_activatecredential -s Q -l quiet -d 'stdout.  [bu] 2'
complete -c tpm2_activatecredential -s Z -l enable-errata -d 'errata fixups'
complete -c tpm2_activatecredential -s n
