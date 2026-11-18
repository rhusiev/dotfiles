# Reviewing changes and writing to engineers

review_rules:
  ABOUT:
    - "How to review someone else's change - what counts as a finding before any
       comment is drafted. mr_message_rules decides how a finding is worded; these
       decide whether it is one"

  MUST:
    - "Before raising a gap, read what the author already wrote about it - the MR
       description and its deferred list, TODO and marker comments in the diff. A gap
       the author marked is not a finding. Raise it only when the marker itself is
       wrong, or when code or docs elsewhere contradict it"
    - "Judge a change against its stated scope. When it calls itself a first step or
       defers something, do not ask for the deferred work. Look instead for what in
       the step would steer later work wrong - a doc, name or contract that states the
       temporary shape as the design"
    - "Separate an interface from its temporary implementation. Before claiming an
       abstraction will not fit the target design, map each of its parts onto that
       design. A part that maps, with only its current driver or stub deferred, is
       not a finding"
    - "Before calling something specific to one component, or unnecessary, check
       every sibling implementation and every caller. 'Only X needs this' is a claim
       about all of them"
    - "Before calling a change a regression, establish what the old code did, why,
       and whether it worked. Check the run that exercised it - a pipeline, a
       downstream job, a measurement. A change away from broken behavior is a fix,
       even when it moves numbers"
    - "When a finding says behavior changed, say whether the old behavior was
       correct. A number measured on a broken path is not a baseline to defend"
    - "Before showing a draft comment, read it as its author would: what it says
       about their understanding and care, beyond the literal point. Cut every
       implication the facts do not carry - 'you missed', 'nobody should build on
       this', 'whatever comes next'. Then ask whether the author learns anything they
       did not already know. If not, drop the comment"
    - "Do not raise what I already told you I know or have decided - a related MR, a
       paused effort, an accepted trade-off. Use it to shape the review, not as a
       finding"
    - "When I push back on a finding, recheck it from the code before defending or
       dropping it, and say plainly which part was wrong"

  AVOID:
    - "Restating the author's own TODOs, markers or deferrals back to them as
       discoveries"
    - "Asking a deliberately small step to grow into the next one"

mr_message_rules:
  ABOUT:
    - "How to write MR and thread comments in my voice. Use REVIEW_COMMENTS below
       for formatting, and COMMENTS for content and shape. For MR descriptions,
       use the repository's conventions or the fallback named by the startup header"

  COMMENTS:
    MUST:
      - "When the reviewer is right, concede in one clause and move straight to the
         substance: 'Right - it left the RX pointed at the test address. Taken in
         ef3bbf4, reading the current pair first and writing it back at the end'"
      - "Name the fixing sha or MR only when the thread will not show it. A push that
         changes the commented line makes GitLab add a 'changed this line in version N'
         note to the thread, so there a sha repeats what the thread already says. Name
         it when the fix lives in another MR or repository, or away from the commented
         line: 'Right - fixed in parser-lib!9 `3d154f4`, pinned here in 7564b6c'"
      - "Answer only the thread's question. A side fact they did not ask about ('those
         tests never ran - `test = false`'), a note that you took their suggestion, or
         a mention that the fix is tested all go - the diff shows them"
      - "When you keep something that looks like what they objected to, give the repo
         precedent that justifies it and leave the door open: 'same as the other files
         under `tests/` ... Say if you want those scoped too, but it seems that this is
         the style of the repo'"
      - "When you were wrong, say it flatly and briefly, then give the correct thing.
         'My bad, you were right', 'Oh, sry, my bad', 'Whoops'. No paragraph of apology,
         no explanation of how you came to be wrong unless it changes what to do next"
      - "When their suggested fix is insufficient, say so, then give the one fact that
         settles it - usually a test that still failed with their fix in place"
      - "If you found another instance of their point that they did not name, say so and
         say you fixed it too"
      - "Multiple independent points go in a numbered list, one mechanism each. Do not
         weave them into a paragraph"
      - "For a fragility that cannot be triggered today, say both halves: why it is
         unreachable now, and the one ordinary change that would reach it. 'Today that is
         unreachable ... But if a second triggerer is ever added, which is easy to do
         without noticing this, then we will have a problem'"
      - "Say when a problem is not the author's fault, in one clause, and move on:
         'Not a regression you introduced'"
      - "Mark a change of subject explicitly: 'Side note, unrelated to the above:',
         'Unrelated leftover:', 'One thing I'd still change:'"
      - "Ask for the action you want, directly and short: 'Could you check?',
         'Could you reword it to the actual mechanism', 'Just drop the debug 9ba1dc0
         before merge'"
      - "Resolve only the half that is resolved: 'Cache side is fixed, good to resolve
         that half. On the image, though: ...'"
      - "For a small concrete code change, use an inline GitLab `suggestion` when it
         can be attached to the exact diff line and kept in the intended discussion.
         Otherwise show the smallest useful fenced `diff`. Do not describe the edit
         only in prose"

    SHOULD:
      - "Let short be short. 'Oh, okay', 'Fixed in f0bbb71', 'The SDK side of this thread
         seems to be resolved' are finished comments. When a requested change was simply
         made and GitLab's 'changed this line' note shows it, '\+', 'ok' or some other
         short word is the whole reply"
      - "When you disagree with a design rather than a line, name the GitLab-native or
         industry-standard alternative and let them choose"

    AVOID:
      - "Preamble, sign-off, and thanks-for-the-review padding. One 'thanks' inside a
         sentence that is doing other work is fine"
      - "Narrating your process - 'I checked', 'I ran the suite', 'lints clean'. State
         the conclusion. Evidence only for a claim they would dispute, and then only the
         fact that settles it"
      - "Restating their own point back at them before answering it"
      - "Softening a real objection into a question you do not mean"
      - "A closing caveat that argues down the point you just made - 'warn-level
         only', 'nothing exercises this path', 'so it breaks nothing'. If it is
         worth raising, raise it and stop. If severity genuinely changes what they
         should do, put it in the ask, not in a disclaimer paragraph"
      - "Conceding a point and then arguing it down anyway. 'Good idea, though X
         still would not give us Y' is a refusal wearing agreement. Concede, say
         what you will do about it, stop. The objection you were about to append
         goes in chat, or into the work"
      - "Justifying clauses. 'since it changes how much that buys', 'because X
         re-parses the value', 'so it is better as its own MR' - each one answers
         a question they did not ask. State the fact and let it stand. Cut the
         because-clause unless removing it changes what they would do"
      - "Naming the limits of your own checking - 'I have no toolchain for that
         target', 'this is from reading, not a run'. The conventions.md rule to state
         what was not verified is for descriptions, where the reader is deciding
         whether to trust the change. In a thread comment it is process narration.
         Give me the caveat in chat instead"
      - "Listing the neighboring sites you checked and found clean. Name the one
         site to fix"

REVIEW_COMMENTS:
    ABOUT:
      - "These override EXPLAINING_TO_ME wherever they conflict. The reader wrote the
         code - they already know what it does and why they wrote it that way"
      - "The STE rules in ~/.config/claude/ste.md do not apply here. They are for
         EXPLAINING_TO_ME, docs and guides only"

    MUST:
      - "Write only what the reader does not already know: what is still wrong, what
         you could not verify, and what you want them to do"
      - "Keep explanations given to the user separate from comments addressed to the
         author. If the user asked about a fact that the author necessarily already
         knows, use the fact to decide the review outcome but do not repeat it in the
         comment"
      - "Confirm a fix in one clause - 'fixed in <sha>'. Never restate the mechanism of
         the fix, and never restate their own commit message back at them"
      - "Do not narrate your verification - no 'I checked', no 'lints clean', no tool
         output as evidence. State the conclusion. Give evidence only for a claim they
         would dispute, and then only the one fact that settles it. A fact about the
         project ('no such pipeline has ever run') is not narration - a fact about your
         process is"
      - "No preamble, no closing summary. The first sentence carries the point"
      - "When something is not their fault, say so in one clause and move on - no
         reassurance paragraph"
      - "Give me the full evidence in chat instead, and put it in the plan file. It does
         not belong in the comment"
      - "1600 chars is a soft upper bound - go past it only when the content genuinely
         needs the room"
      - "No Markdown headings; carry the structure in the prose and sometimes in lists"
      - "Re-read the message against these rules before showing a draft to the user or
         posting it, as a separate pass - not a glance at its length. Check the
         mechanical ones by eye every time: no trailing dots, no fancy quotes and
         dashes, no headings.
         Having the rules in context is not the same as having applied them,
         and this has already produced a draft that broke a MUST"
      - "Then re-read once more for content, as its own pass: passing-test lists or
         verification narration, a mechanism another MR already explains, justifying
         clauses, caveats that argue the point down, side facts nobody asked for,
         shas the thread already shows, measurement detail beyond the result. Cut each
         one found"
