# openssl-enc.1ossl
# Autogenerated from man page /usr/share/man/man1/openssl-enc.1ossl.gz
complete -c 'openssl-enc.1ossl' -o help -d 'X Item "-help" Print out a usage message'
complete -c 'openssl-enc.1ossl' -o list -d 'X Item "-list" List all supported ciphers'
complete -c 'openssl-enc.1ossl' -o ciphers -d 'X Item "-ciphers" Alias of -list to display all supported ciphers'
complete -c 'openssl-enc.1ossl' -o in -d 'X Item "-in filename" The input filename, standard input by default'
complete -c 'openssl-enc.1ossl' -o out -d 'X Item "-out filename" The output filename, standard output by default'
complete -c 'openssl-enc.1ossl' -o pass -d 'X Item "-pass arg" The password source'
complete -c 'openssl-enc.1ossl' -s e -d 'X Item "-e" Encrypt the input data: this is the default'
complete -c 'openssl-enc.1ossl' -s d -d 'X Item "-d" Decrypt the input data'
complete -c 'openssl-enc.1ossl' -s a -d 'X Item "-a" Base64 process the data'
complete -c 'openssl-enc.1ossl' -o base64 -d 'X Item "-base64" Same as -a'
complete -c 'openssl-enc.1ossl' -s A -d 'X Item "-A" If the -a option is set then base64 process the data on one line'
complete -c 'openssl-enc.1ossl' -s k -d 'X Item "-k password" The password to derive the key from'
complete -c 'openssl-enc.1ossl' -o kfile -d 'X Item "-kfile filename" Read the password to derive the key from the first l…'
complete -c 'openssl-enc.1ossl' -o md -d 'X Item "-md digest" Use the specified digest to create the key from the passp…'
complete -c 'openssl-enc.1ossl' -o iter -d 'X Item "-iter count" Use a given number of iterations on the password in deri…'
complete -c 'openssl-enc.1ossl' -o pbkdf2 -d 'X Item "-pbkdf2" Use PBKDF2 algorithm with a default iteration count of 10000…'
complete -c 'openssl-enc.1ossl' -o nosalt -d 'X Item "-nosalt" Don\'t use a salt in the key derivation routines'
complete -c 'openssl-enc.1ossl' -o salt -d 'X Item "-salt" Use salt (randomly generated or provide with -S option) when e…'
complete -c 'openssl-enc.1ossl' -s S -d 'X Item "-S salt" The actual salt to use: this must be represented as a string…'
complete -c 'openssl-enc.1ossl' -s K -d 'X Item "-K key" The actual key to use: this must be represented as a string c…'
complete -c 'openssl-enc.1ossl' -o iv -d 'X Item "-iv IV" The actual IV to use: this must be represented as a string co…'
complete -c 'openssl-enc.1ossl' -s p -d 'X Item "-p" Print out the key and IV used'
complete -c 'openssl-enc.1ossl' -s P -d 'X Item "-P" Print out the key and IV used then immediately exit: don\'t do any…'
complete -c 'openssl-enc.1ossl' -o bufsize -d 'X Item "-bufsize number" Set the buffer size for I/O'
complete -c 'openssl-enc.1ossl' -o nopad -d 'X Item "-nopad" Disable standard block padding'
complete -c 'openssl-enc.1ossl' -s v -d 'X Item "-v" Verbose print; display some statistics about I/O and buffer sizes'
complete -c 'openssl-enc.1ossl' -o debug -d 'X Item "-debug" Debug the BIOs used for I/O'
complete -c 'openssl-enc.1ossl' -s z -d 'X Item "-z" Compress or decompress encrypted data using zlib after encryption…'
complete -c 'openssl-enc.1ossl' -o none -d 'X Item "-none" Use NULL cipher (no encryption or decryption of input)'
complete -c 'openssl-enc.1ossl' -o rand -o writerand -d 'X Item "-rand files, -writerand file" See "Random State Options" in openssl\\|…'
complete -c 'openssl-enc.1ossl' -o provider -d 'X Item "-provider name"'
complete -c 'openssl-enc.1ossl' -o provider-path -d 'X Item "-provider-path path"'
complete -c 'openssl-enc.1ossl' -o propquery -d 'X Item "-propquery propq" '
complete -c 'openssl-enc.1ossl' -o cipher
complete -c 'openssl-enc.1ossl' -o engine
