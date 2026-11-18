# Using a shared resource

lock_rules:
  ABOUT:
    - "~/.config/claude/bin/agent-lock shares a named resource between the agents on
       this machine - a device, a bench, a port, anything only one agent may use at a
       time. It holds a kernel flock on agent-locks/<name>.lock under
       ~/.local/state, so two agents cannot both hold a resource, and a holder that
       crashes cannot leave it locked. `agent-lock --help` lists the commands and
       limits"
    - "A lease ends on `release`, when the agent process that took it exits, or after
       15 min without a `run`. Waiting is not first-come-first-served"
    - "A command can outlive the lock - its `run` was killed, or its lease ended. The
       next holder kills such a command before it gets the resource"
    - "Which resources exist and what each one covers is machine-specific. It lives
       in ~/.config/claude/work.md, never in this file"

  MUST:
    - "Touch a resource only through the lock. For one command:
       `agent-lock run <name> -- <cmd>`. For a sequence whose state must not change
       between steps - flash, then test, then inspect: `agent-lock acquire <name>
       --purpose '<what>'`, then `agent-lock run <name> -- <cmd>` for each step, then
       `agent-lock release <name>`"
    - "Run every step under a lease through `run` too. `run` keeps the lease alive
       while it works - a bare command does not, so the lease can expire under it"
    - "Release as soon as the sequence is done, and before you stop to wait for my
       answer"
    - "When the resource is busy, start the acquire or run as a background command,
       so the harness wakes you when the lock is granted. Do not poll `status` in a
       loop. When the wait ends with exit 75, tell me who holds it and stop"
    - "Give a command that may run longer than 1 h an explicit `--timeout`. The
       default kills the command after 1 h, and exit 124 means that happened"
    - "For a long command you will not watch, take a lease first, so the resource stays
       yours for the cleanup. Start `agent-lock run <name> --timeout <limit> --
       <cmd>` and `agent-lock alarm <name> --before 10m` as two background commands.
       The alarm wakes you 10 min before the kill, or when the command ends. Then
       either `agent-lock extend <name> <duration>` and start the alarm again, or let
       the kill happen and clean up under the lease"
    - "Never `break` a lock that another session holds unless I ask for it in this
       session"
    - "Never delete or edit files in the agent-locks directory. A deleted .lock file
       lets two agents hold the same resource at once"
    - "A long-lived child started under a lease must not inherit the lock file
       descriptor; close it in the child and verify the lock is free after the run.
       A forked server that keeps the fd alive blocks every later holder while
       looking idle"

  SHOULD:
    - "After you acquire a resource, check or reset the state you depend on. The lock
       does not reset anything - you get the resource as the last holder left it"
