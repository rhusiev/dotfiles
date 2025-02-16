# perf-top
# Autogenerated from man page /usr/share/man/man1/perf-top.1.gz
complete -c perf-top -s a -l all-cpus -d 'System-wide collection.  (default)'
complete -c perf-top -s c -l count -d 'Event period to sample'
complete -c perf-top -s C -l cpu -d 'Monitor only on the list of CPUs provided'
complete -c perf-top -s d -l delay -d 'Number of seconds to delay between refreshes'
complete -c perf-top -s e -l event -d 'Select the PMU event'
complete -c perf-top -s E -l entries -d 'Display this many functions'
complete -c perf-top -s f -l count-filter -d 'Only display functions with more events than this'
complete -c perf-top -l group-sort-idx -d 'Sort the output by the event at the index n in group'
complete -c perf-top -s F -l freq -d 'Profile at this frequency'
complete -c perf-top -s i -l inherit -d 'Child tasks do not inherit counters'
complete -c perf-top -s k -l vmlinux -d 'Path to vmlinux.  Required for annotation functionality'
complete -c perf-top -l ignore-vmlinux -d 'Ignore vmlinux files'
complete -c perf-top -l kallsyms -d 'kallsyms pathname'
complete -c perf-top -s m -l mmap-pages -d 'Number of mmap data pages (must be a power of two) or size specification with…'
complete -c perf-top -s p -l pid -d 'Profile events on existing Process ID (comma separated list)'
complete -c perf-top -s t -l tid -d 'Profile events on existing thread ID (comma separated list)'
complete -c perf-top -s u -l uid -d 'Record events in threads owned by uid.  Name or number'
complete -c perf-top -s r -l realtime -d 'Collect data with this RT SCHED_FIFO priority'
complete -c perf-top -l sym-annotate -d 'Annotate this symbol'
complete -c perf-top -s K -l hide_kernel_symbols -d 'Hide kernel symbols'
complete -c perf-top -s U -l hide_user_symbols -d 'Hide user symbols'
complete -c perf-top -l demangle-kernel -d 'Demangle kernel symbols'
complete -c perf-top -s D -l dump-symtab -d 'Dump the symbol table used for profiling'
complete -c perf-top -s v -l verbose -d 'Be more verbose (show counter open errors, etc)'
complete -c perf-top -s z -l zero -d 'Zero history across display updates'
complete -c perf-top -s s -l sort -d 'Sort by key(s): pid, comm, dso, symbol, parent, srcline, weight, local_weight…'
complete -c perf-top -l fields -d 'Specify output field - multiple keys can be specified in CSV format'
complete -c perf-top -s n -l show-nr-samples -d 'Show a column with the number of samples'
complete -c perf-top -l show-total-period -d 'Show a column with the sum of periods'
complete -c perf-top -l dsos -d 'Only consider symbols in these dsos'
complete -c perf-top -l comms -d 'Only consider symbols in these comms'
complete -c perf-top -l symbols -d 'Only consider these symbols'
complete -c perf-top -s M -l disassembler-style -d 'Set disassembler style for objdump'
complete -c perf-top -l addr2line -d 'Path to addr2line binary'
complete -c perf-top -l objdump -d 'Path to objdump binary'
complete -c perf-top -l prefix -l prefix-strip -d 'Remove first N entries from source file path names in executables and add PRE…'
complete -c perf-top -l source -d 'Interleave source code with assembly code'
complete -c perf-top -l asm-raw -d 'Show raw instruction encoding of assembly instructions'
complete -c perf-top -s g -d 'Enables call-graph (stack chain/backtrace) recording'
complete -c perf-top -l call-graph -d 'Setup and enable call-graph (stack chain/backtrace) recording, implies -g'
complete -c perf-top -l children -d 'Accumulate callchain of children to parent entry so that then can show up in …'
complete -c perf-top -l max-stack -d 'Set the stack depth limit when parsing the callchain, anything beyond the spe…'
complete -c perf-top -l ignore-callees -d 'Ignore callees of the function(s) matching the given regex'
complete -c perf-top -l percent-limit -d 'Do not show entries which have an overhead under that percent.  (Default: 0)'
complete -c perf-top -l percentage -d 'Determine how to display the overhead percentage of filtered entries'
complete -c perf-top -s w -l column-widths -d 'Force each column width to the provided list, for large terminal readability'
complete -c perf-top -l proc-map-timeout -d 'When processing pre-existing threads /proc/XXX/mmap, it may take a long time,…'
complete -c perf-top -s b -l branch-any -d 'Enable taken branch stack sampling.  Any type of taken branch may be sampled'
complete -c perf-top -s j -l branch-filter -d 'Enable taken branch stack sampling'
complete -c perf-top -l branch-history -d 'Add the addresses of sampled taken branches to the callstack'
complete -c perf-top -l raw-trace -d 'When displaying traceevent output, do not use print fmt or plugins'
complete -c perf-top -l hierarchy -d 'Enable hierarchy output'
complete -c perf-top -l overwrite -d 'Enable this to use just the most recent records, which helps in high core cou…'
complete -c perf-top -l force -d 'Don\'t do ownership validation'
complete -c perf-top -l num-thread-synthesize -d 'The number of threads to run when synthesizing events for existing processes'
complete -c perf-top -l namespaces -d 'Record events of type PERF_RECORD_NAMESPACES and display it with the cgroup_i…'
complete -c perf-top -s G -l cgroup -d 'monitor only in the container (cgroup) called "name"'
complete -c perf-top -l all-cgroups -d 'Record events of type PERF_RECORD_CGROUP and display it with the cgroup sort …'
complete -c perf-top -l switch-on -d 'Only consider events after this event is found. sp . if n \\{\\'
complete -c perf-top -l switch-off -d 'Stop considering events after this event is found'
complete -c perf-top -l show-on-off-events -d 'Show the --switch-on/off events too'
complete -c perf-top -l stitch-lbr -d 'Show callgraph with stitched LBRs, which may have more complete callgraph'

