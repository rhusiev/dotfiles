# perf-trace
# Autogenerated from man page /usr/share/man/man1/perf-trace.1.gz
complete -c perf-trace -s a -l all-cpus -d 'System-wide collection from all CPUs'
complete -c perf-trace -s e -l expr -l event -d 'List of syscalls and other perf events (tracepoints, HW cache events, etc) to…'
complete -c perf-trace -l filter -d 'Event filter'
complete -c perf-trace -s D -l delay -d 'After starting the program, wait msecs before measuring'
complete -c perf-trace -s o -l output -d 'Output file name'
complete -c perf-trace -s p -l pid -d 'Record events on existing process ID (comma separated list)'
complete -c perf-trace -s t -l tid -d 'Record events on existing thread ID (comma separated list)'
complete -c perf-trace -s u -l uid -d 'Record events in threads owned by uid.  Name or number'
complete -c perf-trace -s G -l cgroup -d 'Record events in threads in a cgroup. sp . if n \\{\\'
complete -c perf-trace -l filter-pids -d 'Filter out events for these pids and for trace itself (comma separated list)'
complete -c perf-trace -s v -l verbose -d 'Increase the verbosity level'
complete -c perf-trace -l no-inherit -d 'Child tasks do not inherit counters'
complete -c perf-trace -s m -l mmap-pages -d 'Number of mmap data pages (must be a power of two) or size specification with…'
complete -c perf-trace -s C -l cpu -d 'Collect samples only on the list of CPUs provided'
complete -c perf-trace -l duration -d 'Show only events that had a duration greater than N. M ms'
complete -c perf-trace -l sched -d 'Accrue thread runtime and provide a summary at the end of the session'
complete -c perf-trace -l failure -d 'Show only syscalls that failed, i. e.  that returned < 0'
complete -c perf-trace -s i -l input -d 'Process events from a given perf data file'
complete -c perf-trace -s T -l time -d 'Print full timestamp rather time relative to first sample'
complete -c perf-trace -l comm -d 'Show process COMM right beside its ID, on by default, disable with --no-comm'
complete -c perf-trace -s s -l summary -d 'Show only a summary of syscalls by thread with min, max, and average times (i…'
complete -c perf-trace -s S -l with-summary -d 'Show all syscalls followed by a summary by thread with min, max, and average …'
complete -c perf-trace -l errno-summary -d 'To be used with -s or -S, to show stats for the errnos experienced by syscall…'
complete -c perf-trace -l tool_stats -d 'Show tool stats such as number of times fd\\(->pathname was discovered thru ho…'
complete -c perf-trace -s f -l force -d 'Don\'t complain, do it'
complete -c perf-trace -s F -l pf -d 'Trace pagefaults'
complete -c perf-trace -l syscalls -d 'Trace system calls'
complete -c perf-trace -l call-graph -d 'Setup and enable call-graph (stack chain/backtrace) recording'
complete -c perf-trace -l kernel-syscall-graph -d 'Show the kernel callchains on the syscall exit path'
complete -c perf-trace -l max-events -d 'Stop after processing N events'
complete -c perf-trace -l switch-on -d 'Only consider events after this event is found'
complete -c perf-trace -l switch-off -d 'Stop considering events after this event is found'
complete -c perf-trace -l show-on-off-events -d 'Show the --switch-on/off events too'
complete -c perf-trace -l max-stack -d 'Set the stack depth limit when parsing the callchain, anything beyond the spe…'
complete -c perf-trace -l min-stack -d 'Set the stack depth limit when parsing the callchain, anything below the spec…'
complete -c perf-trace -l print-sample -d 'Print the PERF_RECORD_SAMPLE PERF_SAMPLE_ info for the raw_syscalls:sys_{ente…'
complete -c perf-trace -l proc-map-timeout -d 'When processing pre-existing threads /proc/XXX/mmap, it may take a long time,…'
complete -c perf-trace -l sort-events -d 'Do sorting on batches of events, use when noticing out of order events that m…'
complete -c perf-trace -l libtraceevent_print -d 'Use libtraceevent to print tracepoint arguments'
complete -c perf-trace -l map-dump -d 'Dump BPF maps setup by events passed via -e, for instance the augmented_raw_s…'

