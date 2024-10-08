# pkcs15-init
# Autogenerated from man page /usr/share/man/man1/pkcs15-init.1.gz
complete -c pkcs15-init -l version -d 'Print the OpenSC package release version'
complete -c pkcs15-init -l card-profile -s c -d 'Tells pkcs15-init to load the specified card profile option'
complete -c pkcs15-init -l create-pkcs15 -s C -d 'This tells pkcs15-init to create a PKCS #15 structure on the card, and initia…'
complete -c pkcs15-init -l serial -d 'Specify the serial number of the card'
complete -c pkcs15-init -l erase-card -s E -d 'This will erase the card prior to creating the PKCS #15 structure, if the car…'
complete -c pkcs15-init -l erase-application -d 'This will erase the application with the application identifier AID'
complete -c pkcs15-init -l generate-key -s G -d 'Tells the card to generate new key and store it on the card'
complete -c pkcs15-init -l pin -l puk -l so-pin -l so-puk -d 'These options can be used to specify the PIN/PUK values on the command line'
complete -c pkcs15-init -l no-so-pin -d 'Do not install a SO PIN, and do not prompt for it'
complete -c pkcs15-init -l profile -s p -d 'Tells pkcs15-init to load the specified general profile'
complete -c pkcs15-init -l secret-key-algorithm -d 'keyspec describes the algorithm and length of the key to be created or downlo…'
complete -c pkcs15-init -l store-certificate -s X -d 'Tells pkcs15-init to store the certificate given in filename on the card, cre…'
complete -c pkcs15-init -l store-pin -s P -d 'Store a new PIN/PUK on the card'
complete -c pkcs15-init -l store-public-key -d 'Tells pkcs15-init to download the specified public key to the card and create…'
complete -c pkcs15-init -l store-private-key -s S -d 'Tells pkcs15-init to download the specified private key to the card'
complete -c pkcs15-init -l store-secret-key -d 'Tells pkcs15-init to download the specified secret key to the card'
complete -c pkcs15-init -l store-data -s W -d 'Store a data object'
complete -c pkcs15-init -l update-certificate -s U -d 'Tells pkcs15-init to update the certificate object with the ID specified via …'
complete -c pkcs15-init -l delete-objects -s D -d 'Tells pkcs15-init to delete the specified object'
complete -c pkcs15-init -l change-attributes -s A -d 'Tells pkcs15-init to change the specified attribute'
complete -c pkcs15-init -l use-default-transport-keys -s T -d 'Tells pkcs15-init to not ask for the transport keys and use default keys, as …'
complete -c pkcs15-init -l sanity-check -d 'Tells pkcs15-init to perform a card specific sanity check and possibly update…'
complete -c pkcs15-init -l reader -s r -d 'Number of the reader to use'
complete -c pkcs15-init -l verbose -s v -d 'Causes pkcs15-init to be more verbose'
complete -c pkcs15-init -l wait -s w -d 'Causes pkcs15-init to wait for a card insertion'
complete -c pkcs15-init -l use-pinpad -d 'Do not prompt the user; if no PINs supplied, pinpad will be used'
complete -c pkcs15-init -l auth-id -s a -d 'Specify ID of PIN to use/create'
complete -c pkcs15-init -l puk-id -d 'Specify ID of PUK to use/create'
complete -c pkcs15-init -l label -d 'Specify label for a PIN, key, certificate or data object when creating a new …'
complete -c pkcs15-init -l puk-label -d 'Specify label of PUK'
complete -c pkcs15-init -l public-key-label -d 'Specify public key label (use with --generate-key)'
complete -c pkcs15-init -l cert-label -d 'Specify user cert label (use with --store-private-key)'
complete -c pkcs15-init -l application-name -d 'Specify application name of data object (use with --store-data-object)'
complete -c pkcs15-init -l aid -d 'Specify AID of the on-card PKCS#15 application to be binded to (in hexadecima…'
complete -c pkcs15-init -l output-file -s o -d 'Output public portion of generated key to file'
complete -c pkcs15-init -l passphrase -d 'Specify passphrase for unlocking secret key'
complete -c pkcs15-init -l authority -d 'Mark certificate as a CA certificate'
complete -c pkcs15-init -l key-usage -s u -d 'Specifies the X. 509 key usage'
complete -c pkcs15-init -l finalize -s F -d 'Finish initialization phase of the smart card'
complete -c pkcs15-init -l update-last-update -d 'Update \\*(AqlastUpdate\\*(Aq attribute of tokenInfo'
complete -c pkcs15-init -l ignore-ca-certificates -d 'When storing PKCS#12 ignore CA certificates'
complete -c pkcs15-init -l update-existing -d 'Store or update existing certificate'
complete -c pkcs15-init -l extractable -d 'Private key stored as an extractable key'
complete -c pkcs15-init -l user-consent -d 'Specify user-consent.  arg is an integer value'
complete -c pkcs15-init -l insecure -d 'Insecure mode: do not require a PIN for private key'
complete -c pkcs15-init -l md-container-guid -d 'For a new key specify GUID for a MD container'
complete -c pkcs15-init -l help -s h -d 'Display help message'
complete -c pkcs15-init -l verify-pin -d 'has to be used.  MODES OF OPERATION Initialization'
complete -c pkcs15-init -l id -d 'option in the pkcs15-init commands to generate or to import a new key is depr…'
complete -c pkcs15-init -l format -d 'option, pkcs15-init will assume PEM format'
complete -c pkcs15-init -l store-data-object

