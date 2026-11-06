# Simplified Technical English (ASD-STE100) writing rules

Apply the Rules and the Scan Checklist to three kinds of text:

1. Everything you say to me in chat - the EXPLAINING_TO_ME mode of writing_style_rules
2. Docs - the documentation files tracked in a repository, as guides_rules defines them
3. Guides - the files under ~/.local/share/ai-guides, as guides_rules defines them

Use the Process and the Boundaries when I ask you to rewrite a text. Where these rules conflict with GENERAL, or with EXPLAINING_TO_ME in chat, those win

Do not apply these rules to code comments. Code comments follow code_style_rules

Do not apply these rules to MR descriptions, MR and thread comments, commit messages or issue replies. Those follow REVIEW_COMMENTS, mr_message_rules and git_rules only

## Rules

### Structural rules - apply these

| Rule | Do | Don't |
|---|---|---|
| Active voice | "The agent deletes the file." | "The file is deleted (by the agent)." - unless the actor is genuinely unknown or irrelevant |
| No phrasal verbs (Rule 9.3) | "Remove the panel." / "Start the job." | "Take off the panel." / "Spin up the job." - a two-word verb has meanings the parts do not predict |
| One instruction per sentence | "Open the file. Read line 3." | "Open the file and read line 3, then check if it matches." |
| Sentence length | ≤20 words for instructions/procedures, ≤25 words for descriptions | Long compound/subordinate-clause sentences |
| No semicolons (Rule 8.1) | Split into separate sentences | Any semicolon at all - STE bans the mark outright, not only as a clause join. (Rule 8.1 permits every other standard punctuation mark. STE does not ban the em dash, but use `-` instead of it everywhere. A dash between two clauses often signals a sentence that should be split) |
| Noun clusters | ≤3 words stacked as a noun phrase ("fuel pump valve") | 4+ word noun stacks ("high pressure fuel pump inlet valve assembly") |
| No ellipsis | Keep the subject, verb, and article explicit even if it reads longer | Drop words to save space ("Files not backed up will be lost" → ambiguous which files) |
| Keep modality | "The request **may have** failed." stays "may have" | Promote a hedge to a fact ("The request failed.") or invent a certainty the source did not state |
| Paragraph limits | One topic per paragraph, ≤6 sentences | Multi-topic paragraphs |
| Lists for sequences | Use a numbered or bulleted list for 3+ steps or conditions | Bury a sequence inside one prose sentence |

### Lexical rules - direction of travel only

| Rule | Do | Don't | Why it is weaker here |
|---|---|---|---|
| One word, one meaning | Pick one verb for one action and reuse it every time (e.g. always "check", never mix "check"/"verify"/"confirm" for the same action) | Rotate synonyms for the same idea across a document | Consistency within a document is checkable. Which word is the *approved* one is not, without the dictionary |
| One part of speech per word | "Apply oil to the valve" (oil = noun) | "Oil the valve" (oil = verb) | Whether "oil" is approved as a noun only is a dictionary fact. Prefer the noun form when both read equally well. Do not claim compliance |
| Verb, not noun (Rule 3.7) | "Analyze the log." | "Perform an analysis of the log." - a noun form of an action makes the sentence longer and hides who acts | Rule 3.7 says "use an **approved** verb to describe an action." Preferring the verb form is safe to apply anywhere. Knowing which verb is the approved one needs the dictionary |
| Domain terms | Keep necessary technical nouns/verbs. If a term is not common English, say what it means in ordinary words in the same sentence where it first appears (STE allows a project-specific glossary beyond its base dictionary) | Use jargon without ever defining it | The glossary allowance is real STE, but the base dictionary it extends is absent |

### Simple tenses - apply with one exception

STE permits infinitive, imperative, simple present, simple past, simple future, and past participle as adjective. It excludes present perfect and other compound forms: "we received the report", not "we have received the report"

Aircraft manuals never need present perfect, so the exclusion costs the standard nothing. Other text is not always so lucky. "The job has completed" (and its output is available now) and "the job completed" (at some past point) are different statements, and status text frequently needs the first. **Where the compound form carries information the simple form cannot - current relevance, or a hedge as in "may have failed" - keep it and flag the departure.** Elsewhere, follow the rule

## Scan Checklist

These six habits cover most of what makes machine-written English hard to parse. Each one is mechanical: you can point at the exact word or punctuation mark that breaks the rule, with no judgment call. Scan for all six before you rewrite anything

1. **Synonym rotation** - the same thing gets several names in one document ("the user", "the customer", "the client"). The reader cannot tell whether they are one thing or three. Fix: pick one name, use it every time
2. **Hedge stacking** - helper verbs and qualifiers pile up until the sentence asserts nothing ("it is important to note that this may potentially help to improve"). Fix: state the claim, or delete it
3. **Nominalization** - an action frozen into a noun ("perform an analysis of", "provides assistance to"). Fix: use the verb ("analyze", "helps")
4. **Marketing adjectives** - words that claim quality instead of showing it: seamless, robust, powerful, cutting-edge, effortless, blazing-fast. Fix: delete, or replace with the measurement that earns the claim
5. **Run-on sentences** - several ideas joined by semicolons or dashes. Fix: one idea per sentence
6. **Soft phrasal verbs** - spin up, reach out, dive into, kick off. Fix: use the single plain verb (start, contact, read, begin)

## Process

1. Read the input text once for meaning - do not start rewriting before you understand what it must still say afterward
2. Walk it sentence by sentence. Flag every rule violation from the Rules tables and every habit from the Scan Checklist. Flag the lexical rules but do not enforce them
3. Rewrite each flagged sentence to fix the violation while preserving the original meaning exactly. If a rewrite would drop necessary precision (a safety condition, a scope qualifier, a number), keep the longer phrasing and flag it instead of silently simplifying
   - **Check modality before you commit to a rewrite.** Hedges ("may", "could", "sometimes", "is likely to") carry the author's confidence, and confidence is content. A shorter sentence that upgrades a hedge to a fact is not a simplification - it is a different claim. This is the most common way a well-intentioned STE rewrite goes wrong, because hedges are exactly what a length cap tempts you to cut
   - Never add a fact the source did not state. A rewrite that reads better because it supplies a cause, a frequency, or a mechanism has stopped being a rewrite
4. Output the rewritten text alone. Keep the rule analysis internal unless the user asked to see it

## Boundaries

**Will:**
- Rewrite ambiguous or dense English into short, single-meaning, active-voice sentences
- Return the rewritten text alone by default, and name the rules it applied when the user asks
- Preserve every fact, condition, and scope qualifier in the original
- Preserve the strength of every hedge, and add no claim the source did not make

**Will not:**
- Reproduce ASD's official ~900-word dictionary as if it were memorized verbatim
- Simplify creative, marketing, or persuasive copy where voice and nuance are the point
- Silently drop a safety condition, exception, or scope qualifier to shorten a sentence - flag the trade-off instead
- Convert "may have failed" into "failed", or "could be caused by X" into "X is the cause" - losing a hedge changes the claim
- Shorten past the point of clarity. Cutting words is not the goal. Removing ambiguity is the goal. Past a certain point compression starts costing the reader time rather than saving it, so stop when the sentence is unambiguous, not when it is shortest
