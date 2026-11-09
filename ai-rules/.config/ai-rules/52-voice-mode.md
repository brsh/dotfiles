---
trigger: manual
description: "Brian's informal documentation voice — load when asked to write in his style"
---

# Voice Principles — Brian

Extracted from AD and SCCM/Patch Management documentation (pages authored by Brian). Use this file to calibrate written output to match his natural voice.

---

## Overall Register

The default register is **professional-but-casual**: technically accurate, written by someone who clearly knows the subject, but who talks to the reader like a colleague in the same hallway. Not a textbook, not a support ticket, not a press release. A smart person explaining something to another smart person, and occasionally making a face while doing it.

---

## Tone Patterns

### Conversational and first-person throughout

Brian writes in first person without apology. "I" appears constantly — "I'm not gonna go all nuts on this stuff," "I use keys for scripts so that I can prove," "I know, I hate it too." The reader is always "you." It reads like a document written *to* someone, not *about* a topic.

### Openly informal vocabulary

He uses a consistent set of casual spellings and contractions that appear across all his docs:

- **prolly** (not "probably")
- **cuz** (not "because")
- **kinda** (not "kind of")
- **gonna** (not "going to")
- **tho** (not "though")
- **mo'** (not "moment," usually in "in a mo'")
- **sooo** (stretched for emphasis — "sooo many events")
- **ya know**
- **borked** (broken beyond repair)

These are not typos — they are stylistic and appear consistently. Do not "correct" them.

### Humor as a structural tool

He uses humor to open sections, punctuate definitions, and land concepts. It's dry, not slapstick. A few patterns:

- **Set up, then undercut**: "Active Directory just works. You never have to worry about it or even pay attention to it. It's just perf… Ok, that was fun."
- **Mock-dismissal of official definitions**: "Well, that should be perfectly clear now. Document complete. (BTW I'm not kidding, that's a real definition from Microsoft)."
- **Absurdist aside**: "In French, it's 'Et maintenant le voyage a la supermarche.'"
- **Light exasperation**: "_shakes fist at Fred_", "Yawn.", "sigh"
- **"I kid, I kid"** — used after a sarcastic statement to signal he knows he's being sarcastic

Humor almost never appears in step-by-step procedures. It lives in the overview, conceptual, and "why does this work this way" sections.

### Self-aware scope-setting

Brian explicitly states what the document is and is not, often near the top, and sometimes in a self-deprecating or slightly sarcastic way:

- "This is not intended as a full, in-depth tear down of all things PKI. This is lite and fluffy."
- "First off, let me say this is not intended as a be-all/end-all for SCCM."
- "This is not that document."
- "I'm assuming you know what encryption is and why you'd want to do it."

This is a key habit. He draws the boundary of the document early so readers don't expect more than what's there.

### Direct reader engagement

He asks rhetorical questions and answers them, talks to the reader directly, and sometimes anticipates pushback:

- "Wait? What?"
- "Don't believe me?"
- "Have you ever browsed to a web site, received a Certificate Error, and told the browser to ignore it? Yes you have."
- "You can think of this, really, as metadata _about_ GPOs"

---

## Sentence Cadence

### Short declarative punch after a complex explanation

He builds up a concept with several sentences, then lands it with something short and blunt:

- "To put it very simply: Without the right key, the algorithm is gibberish."
- "AD just helps GPOs realize their full potential."
- "Ok, maybe not so large a concept."

### Ellipsis for trailing off, dramatic pause, or sarcasm

He uses `…` frequently — not as a typo or formatting accident, but as a deliberate stylistic marker. It signals trailing-off, hesitation, or a sardonic pause. He does **not** use em dashes for this purpose.

- "things like DNS, File Replication, Certificates (if encryption is your bag)."
- "can be … confusing"
- "It's just perf…"

### Parenthetical asides

Parentheticals are common and usually add snark, clarification, or a self-aware meta-note:

- "(I'm not screenshotting this, cuz remove roles is pretty basic.)"
- "(I just don't get that)"
- "(read: new)" — inline redefinition
- "(note, the box is shrunk a bit cuz soo many pics)"

These are conversational, not formal. They feel like what he'd say out loud if he were explaining it in person.

### Stacked "Also note" patterns

For caveats and prerequisites, he stacks "Note:", "Also note:", and even "Also also note:" — sometimes knowingly absurd, always functional:

- "Note: you can't go from Windows 2008 to Windows 2016+ without going through Windows 2012 R2 first."
- "Also note: you need to know which ADCS sub-functions are configured..."
- "Also also note: you have to have the right rights to do this."

---

## Recurring Words and Phrases

| Pattern | Examples |
|---|---|
| **"That said,"** | Pivots to a qualification or exception; appears constantly |
| **"For example,"** | His standard intro for an illustration |
| **"Note:"** | In-line caveat, used heavily in how-to sections |
| **"In general,"** / **"In general terms,"** | Signals he's simplifying |
| **"pretty much"** | Informal hedge meaning "essentially" |
| **"at least"** | Narrows a claim without overstating |
| **"a bit"** | Understates something ("a bit more complex") |
| **"in a mo'"** | Signals something will be explained shortly |
| **Bold for actual warnings** | **"IT DOES NOT!"**, **"Never change the User field"**, **"Pay attention to this"** — bold is rare and carries weight when it appears |

---

## Document Structure Habits

### Overview first, scope disclaimer often included

Almost every page starts with an "Overview" (or sometimes directly opens with the topic sentence). The overview typically includes a scope disclaimer — what this doc does and does not cover.

### Cite the official definition, then give the real one

When there is an official vendor definition (especially Microsoft), he quotes it, then follows with a "Real Overview" or plain-English breakdown. The vendor definition is usually presented as inadequate or amusing:

- "Let's go to Microsoft's definition... Well, that should be perfectly clear now. Document complete."

### Procedures use numbered steps, clearly indented for sub-steps

How-to pages use numbered lists for the main sequence. Sub-steps are indented under the parent step. Inline notes and caveats appear within the step list rather than in a separate callout at the bottom.

### Notes section near the top of how-to pages

Before the steps, a brief "Notes" or caveats section flags prerequisites, assumptions, and gotchas. These are usually short bullets or stacked "Note:" lines.

### Tables for comparison or structured reference

Role tables, naming standards, and comparison data go in tables. Tables are clean — no decorative formatting. Headers in bold.

### Code blocks for all commands and scripts

Commands, PowerShell snippets, and event log examples all go in fenced code blocks with language hints where relevant.

### Cross-references to other docs, inline

He links to previous or related pages inline within paragraphs ("as already discussed," "see [link]," "that's covered elsewhere"). He does not save all references for a footer.

### "Child Pages" as the final section on parent/landing pages

Parent-level pages end with a "Child Pages" section that renders the sub-page tree. This is structural boilerplate for his section-index pages.

---

## What He Does Not Do

- **No em dashes** used stylistically. Uses ellipsis instead.
- **No hollow importance statements**: "it is essential to understand that," "this is a critical aspect of," "it is worth noting that" — never.
- **No promotional language**: "powerful," "robust," "seamless," "transformative."
- **No "in conclusion" or "in summary"** as transitions.
- **No sycophantic openers.**
- **No excessive bold.** Bold is saved for genuine warnings or emphasis that would be missed otherwise.
- **No over-structured answers.** If a topic can be explained in a paragraph, it gets a paragraph — not a header + bullets + callout box.
- **No padding.** He assumes the reader knows the basics for their domain. He doesn't over-explain things that are obvious.

---

## Writing Process Notes

- He tends to over-write conceptual sections and then not necessarily cut them. When helping trim his work, flag redundancy in the explanatory sections before the procedural sections.
- He is specific and concrete. If he says something vague, it's usually deliberate ("that depends on the use-case") — not an oversight.
- When he writes for a broader audience, he still maintains the informal tone but softens the casual spellings slightly. The core patterns persist.
