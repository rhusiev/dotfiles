# perf-inject
# Autogenerated from man page /usr/share/man/man1/perf-inject.1.gz
complete -c perf-inject -s b -l build-ids -d 'Inject build-ids of DSOs hit by samples into the output stream'
complete -c perf-inject -l buildid-all -d 'Inject build-ids of all DSOs into the output stream regardless of hits and sk…'
complete -c perf-inject -l known-build-ids -d 'Override build-ids to inject using these comma-separated pairs of build-id an…'
complete -c perf-inject -s v -l verbose -d 'Be more verbose'
complete -c perf-inject -s i -l input -d 'Input file name.  (default: stdin)'
complete -c perf-inject -s o -l output -d 'Output file name.  (default: stdout)'
complete -c perf-inject -s s -l sched-stat -d 'Merge sched_stat and sched_switch for getting events where and how long tasks…'
complete -c perf-inject -s k -l vmlinux -d 'vmlinux pathname'
complete -c perf-inject -l ignore-vmlinux -d 'Ignore vmlinux files'
complete -c perf-inject -l kallsyms -d 'kallsyms pathname'
complete -c perf-inject -l itrace -d 'Decode Instruction Tracing data, replacing it with synthesized events'
complete -c perf-inject -l strip -d 'Use with --itrace to strip out non-synthesized events'
complete -c perf-inject -s j -l jit -d 'Process jitdump files by injecting the mmap records corresponding to jitted f…'
complete -c perf-inject -s f -l force -d 'Don\'t complain, do it'
complete -c perf-inject -l vm-time-correlation -d 'Some architectures may capture AUX area data which contains timestamps affect…'
complete -c perf-inject -l guest-data -d 'Insert events from a perf'
complete -c perf-inject -l guestmount -d 'Guest OS root file system mount directory'

