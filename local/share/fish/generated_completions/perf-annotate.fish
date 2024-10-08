# perf-annotate
# Autogenerated from man page /usr/share/man/man1/perf-annotate.1.gz
complete -c perf-annotate -s i -l input -d 'Input file name.  (default: perf. data unless stdin is a fifo)'
complete -c perf-annotate -s d -l dsos -d 'Only consider symbols in these dsos'
complete -c perf-annotate -s s -l symbol -d 'Symbol to annotate'
complete -c perf-annotate -s f -l force -d 'Don\'t do ownership validation'
complete -c perf-annotate -s v -l verbose -d 'Be more verbose.  (Show symbol address, etc)'
complete -c perf-annotate -s q -l quiet -d 'Do not show any warnings or messages.  (Suppress -v)'
complete -c perf-annotate -s n -l show-nr-samples -d 'Show the number of samples for each symbol'
complete -c perf-annotate -s D -l dump-raw-trace -d 'Dump raw trace in ASCII'
complete -c perf-annotate -s k -l vmlinux -d 'vmlinux pathname'
complete -c perf-annotate -l ignore-vmlinux -d 'Ignore vmlinux files'
complete -c perf-annotate -l itrace -d 'Options for decoding instruction tracing data.  The options are: . sp '
complete -c perf-annotate -s m -l modules -d 'Load module symbols.  WARNING: use only with -k and LIVE kernel'
complete -c perf-annotate -s l -l print-line -d 'Print matching source lines (may be slow)'
complete -c perf-annotate -s P -l full-paths -d 'Don\'t shorten the displayed pathnames'
complete -c perf-annotate -l stdio -d 'Use the stdio interface'
complete -c perf-annotate -l stdio2 -d 'Use the stdio2 interface, non-interactive, uses the TUI formatting'
complete -c perf-annotate -l stdio-color -d 'always, never or auto, allowing configuring color output via the command line…'
complete -c perf-annotate -l tui -d 'Use the TUI interface'
complete -c perf-annotate -l gtk -d 'Use the GTK interface'
complete -c perf-annotate -s C -l cpu -d 'Only report samples for the list of CPUs provided'
complete -c perf-annotate -l asm-raw -d 'Show raw instruction encoding of assembly instructions'
complete -c perf-annotate -l show-total-period -d 'Show a column with the sum of periods'
complete -c perf-annotate -l source -d 'Interleave source code with assembly code'
complete -c perf-annotate -l symfs -d 'Look for files with symbols relative to this directory'
complete -c perf-annotate -s M -l disassembler-style -d 'Set disassembler style for objdump'
complete -c perf-annotate -l addr2line -d 'Path to addr2line binary'
complete -c perf-annotate -l objdump -d 'Path to objdump binary'
complete -c perf-annotate -l prefix -l prefix-strip -d 'Remove first N entries from source file path names in executables and add PRE…'
complete -c perf-annotate -l skip-missing -d 'Skip symbols that cannot be annotated'
complete -c perf-annotate -l group -d 'Show event group information together'
complete -c perf-annotate -l demangle -d 'Demangle symbol names to human readable form'
complete -c perf-annotate -l demangle-kernel -d 'Demangle kernel symbol names to human readable form (for C++ kernels)'
complete -c perf-annotate -l percent-type -d 'Set annotation percent type from following choices: global-period, local-peri…'
complete -c perf-annotate -l percent-limit -d 'Do not show functions which have an overhead under that percent on stdio or s…'
complete -c perf-annotate -l data-type -d 'Display data type annotation instead of code'
complete -c perf-annotate -l type-stat -d 'Show stats for the data type annotation'

