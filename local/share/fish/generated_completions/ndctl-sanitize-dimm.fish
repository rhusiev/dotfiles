# ndctl-sanitize-dimm
# Autogenerated from man page /usr/share/man/man1/ndctl-sanitize-dimm.1.gz
complete -c ndctl-sanitize-dimm -s b -l bus -d 'A bus id number, or a provider string (e. g.  "ACPI. NFIT")'
complete -c ndctl-sanitize-dimm -s c -l crypto-erase -d 'Replace the media encryption key on the NVDIMM causing all existing data to r…'
complete -c ndctl-sanitize-dimm -s o -l overwrite -d 'Wipe the entire DIMM, including label data'
complete -c ndctl-sanitize-dimm -s m -l master-passphrase -d 'Indicate that we are using the master passphrase to perform the erase'
complete -c ndctl-sanitize-dimm -s z -l zero-key -d 'Passing in a key with payload that is just 0\'s'
complete -c ndctl-sanitize-dimm -l verbose -d 'Emit debug messages'

