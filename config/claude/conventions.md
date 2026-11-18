# Repository conventions

These rules decide commit messages, MR descriptions and test changes in a
repository that brings no rules of its own. The session-start hook names this
file only when the session's repository tracks no AGENTS.md or CLAUDE.md, and
the instruction gate then refuses state-changing work until it is read. Where
the repository you change has its own AGENTS.md or CLAUDE.md that sets one of
these conventions, that file wins for it. The rest of the global instructions
still apply everywhere

commit_message_rules:
  MUST:
    - "In commit messages keep the subject imperative, 110 chars max, no trailing dot"
    - "Commit messages are a single subject line - no body, no bullet list, no blank-line-separated paragraphs"
    - breaking_change:
      - "A commit that introduce breaking changes must be indicated by an '!' before the ':' in the subject line
         E.g. 'feat(api)!: remove status endpoint'"
      - "Only if a commit introduces a breaking change AND the commit description isn't sufficiently informative:
         You MUST add a footer with references and information about Breaking Changes.
         Breaking Changes must start with the word BREAKING CHANGE:
         For a single line description just add a space after BREAKING CHANGE:
         For a multi line - add two new lines"
    - "Whatever would have gone in the commit body goes in the MR description instead"
    - commit_conventional_prefix:
      - "Use conventional commits style"
      - scope_policy: "Scope in the prefix only for the repos ~/.config/claude/work.md names
          as scoped. There, code changes take a scope matching what those repos already
          do, and changes touching no code take a bare prefix: 'docs: ...', 'chore: ...'"
        types:
        - "Changes relevant to the API or UI":
          - "`feat` Commits that add, adjust or remove a feature to/of/from the API or UI"
          - "`fix` Commits that fix an API or UI bug of a preceded feat commit"
        - "`refactor` Commits that rewrite or restructure code without altering API or UI behavior":
          - "`perf` Commits are special type of refactor commits that specifically improve performance"
        - "`style` Commits that address code style (e.g., white-space, formatting, missing semi-colons) and do not affect application behavior"
        - "`test` Commits that add missing tests or correct existing ones"
        - "`docs` Commits that exclusively affect documentation"
        - "`build` Commits that affect build-related components such as build tools, dependencies, project version, ..."
        - "`ops` Commits that affect operational aspects like infrastructure (IaC), deployment scripts, CI/CD pipelines, backups, monitoring, or recovery procedures, ..."
        - "`chore` Commits that represent tasks like initial commit, modifying .gitignore, ..."
      - "Everywhere else use no scope at all: 'fix: ...', 'chore: ...'"

mr_description_rules:
  ABOUT:
    - "What an MR description contains and how it is shaped. Comments and thread
       replies follow mr_message_rules in ~/.config/claude/reference/reviews.md"

  FORMAT:
    - "1600 chars is a soft upper bound - go past it only when the content genuinely needs the room"
    - "No Markdown headings; carry the structure in the prose and sometimes in lists"
    - "No dots at the ends of paragraphs"
    - "Use GENERAL from the shared entry point and REVIEW_COMMENTS from ~/.config/claude/reference/reviews.md"

  DESCRIPTION:
    MUST:
      - "Open with the defect or the situation as a fact about the code, not as a
         statement about the MR. 'The server bound its receive socket to the
         literal address 10.0.0.12' - never 'This MR changes the socket binding'"
      - "Give the mechanism, not the symptom. Name the wrong value, the right value and
         why the wrong one was produced. If you can write the bug as one equation or one
         command, do"
      - "Order it: what was wrong -> what the fix is -> what it was measured against ->
         what remains unverified. Everything else hangs off that spine"
      - "Do not list passing tests, lint, formatting, successful pipelines or generic
         verification. Those are presumed. Keep measurements only when they are a
         substantive behavioral result of the change, not proof that the change was
         tested. Mention a pipeline only when it failed or remained incomplete, and
         explain why that result is expected or does not reflect the changed behavior"
      - "State explicitly what was NOT verified and why. 'The two hardware-smoke paths
         are unexercised - they need the hardware rig'. A missing verification named is
         information; a missing verification omitted is a lie by shape"
      - "Any change the task did not ask for gets its own paragraph, marked so it can be
         rejected on its own: 'Not asked for, so reject separately if unwanted'"
      - "A constant that was picked rather than derived must say so and invite the real
         figure: '256 is chosen, not derived. If there is a figure from real link
         behavior it should be that instead'"
      - "A defect found but deliberately not fixed here gets a paragraph saying what it
         is, why it is out of scope and where it belongs"
      - "State inter-MR relationships plainly: what this is stacked on, what it blocks,
         what supersedes it, what to retarget after which merge"
      - "When a timeout, retry, grace period, protocol limitation or conservative
         policy matters, trace the concrete runtime sequence: what arrives or fails to
         arrive, what state remains, what the user-visible consequence is, why the
         chosen mechanism helps, and what it still cannot guarantee. Do not assume the
         reviewer already knows the pipeline that makes the limitation relevant"
      - "When an MR contains independent mechanisms, present them as parallel list
         items with one defect and its fix per item. Do not combine unrelated protocol,
         lifecycle, measurement and UI changes into one narrative paragraph"
      - "Before calling something unverified, check for newer valid evidence. Distinguish
         a procedure that did not converge from a completed trial inside it, and an
         attempt that failed before traffic from a later attempt that measured the path"
      - "Identifiers, paths, file:line, shas and config keys in backticks. Keep every
         number and address - simplify sentences, never facts"
      - "When the description has gone stale against the branch, rewrite it and say you
         did. When your own earlier text was wrong, correct it in place and label the
         correction: 'Correcting my own description: ...'"
      - "When updating an existing description, prefer replacing to appending. Every
         added paragraph must answer what the reviewer needs to decide. Report the old
         and new character count when showing the draft"
      - "Explain a mechanism once, in the MR that owns it. A dependent MR links it and
         says only what changes for its own code"

    SHOULD:
      - "For a measurement, keep the result and the conditions needed to trust it,
         not the path to it"
      - "Frame a deliberate change by what it achieves ('now matches production'),
         not only by what it breaks"
      - "Prose paragraphs separated by blank lines. Use a list only for genuinely
         parallel items - independent review points, a set of test cases, a matrix of
         hostile inputs"
      - "Prefer the reproduction to the argument. If the bug reproduced in one step,
         show that step and its two results"

    AVOID:
      - "Markdown headings, and the Problem/Approach/Verification skeleton"
      - "Dots at the ends of paragraphs"
      - "A bullet list of files changed. The diff already says that"
      - "Restating the commit messages"
      - "Adjectives doing the work of measurements - 'much faster', 'more robust',
         'significantly improved'"
      - "Justifying clauses and closing caveats that argue the point down - the
         mr_message_rules COMMENTS AVOID rules in ~/.config/claude/reference/reviews.md apply to
         descriptions too. 'It is not duplicated in this library MR' is one"

test_change_rules:
  MUST:
    - "Never weaken an assertion to stop a test failing or flaking. If a change
       alters what the test can still catch, stop and say so before writing it -
       name the regression that would now slip through"
    - "When fixing flakiness, only touch what the evidence implicates. Get the
       failure list first (CI history, repeated local runs). A test that has not
       actually failed is out of scope"
    - "Prove a flake fix by measurement: failure rate before and after, same
       harness, stated as N/M. 'Should be more robust' is not a result"

  SHOULD:
    - "When a fix has several parts, isolate each part's contribution so it is
       known which one actually mattered"
