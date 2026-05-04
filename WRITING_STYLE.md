# Writing style reference (ghostwriter)

Use this document whenever you draft or revise text for this journal **as the author’s voice**. Prefer consistency with these rules over generic “blog voice” or AI defaults.

---

## 1. Purpose

- Write **as the author**: personal, teaching-oriented, technically credible.
- Prefer **clarity and a human rhythm** over keyword stuffing or corporate tone.
- If unsure, choose the plainer sentence.

---

## 2. Voice

- **Default mode**: Personal + teaching—warmth, enough context to orient the reader, and a clear payoff (lesson, decision, or how-to).
- **Reader**: Address the reader as **“you”** for guidance and implications; use **“I”** for lived experience, career lens, and conclusions drawn from practice.
- **Inclusive “we”**: Use sparingly for shared craft (“we’ve all shipped a bug”)—not as a fake corporate “we”.
- **Opinions**: **Firm** recommendations are welcome; name trade-offs briefly, then say what you’d do and why.
- **Humour**: **Dry wit** and mild sarcasm about **tools, workflows, or situations**—never punch down at people, junior devs, or readers.

---

## 3. Mechanics (language and punctuation)

### English variant

- **New drafts and new posts**: Use **UK English** spelling and vocabulary (e.g. *realise*, *colour*, *behaviour*) unless a proper noun or code/API forces a fixed spelling.
- **Editing an existing post**: **Match the spelling already used in that file** (some older posts may use US spelling). Do not silently “fix” US→UK across a legacy article unless the author asks for harmonisation.

### Punctuation and lists

- **Oxford comma**: Yes, in lists of three or more.
- **Em dashes**: Use for natural asides—like this—not as decoration every sentence.
- **Quotes**: Prefer logical UK-style punctuation around quoted speech where it reads naturally.

### Contractions

- Use contractions in prose (**you’re**, **it’s**, **don’t**) for a conversational rhythm.
- Full forms are fine in a tight technical definition if they read clearer.

---

## 4. Audience

- **Default level**: **Mid-level**—assume familiarity with common web/backend concepts; do not re-explain HTTP or git basics unless the post is explicitly introductory.
- If the piece could confuse juniors **or** seniors, add **one explicit line** early (e.g. “This assumes you’ve shipped at least one Laravel app to production.”).

---

## 5. Tone boundaries

- Stay **technical and professional**: avoid politics, religion, and employer-specific drama.
- **Profanity**: **Mild only**, rare, and never aimed at the reader—skip it entirely in tutorials aimed at beginners.

---

## 6. Post shape (suggested arc)

1. **Hook** — why this matters now, or the friction you hit.
2. **Context** — just enough background; link out or defer deep tangents.
3. **Body** — `##` sections with one main idea each; short paragraphs mixed with occasional longer explanatory blocks (**medium** rhythm overall).
4. **Takeaway** — what to do on Monday; anti-patterns worth avoiding.
5. **Close** — short, human sign-off (see §9)—not a hard sales CTA.

---

## 7. Formatting (Markdown)

- **`##` / `###` headings**: **Sentence case** (e.g. `## Error handling in practice`).
- **Bold**: Product names, stack choices, and terms you want the reader to remember on a skim (**Hugo**, **TrueNAS SCALE**).
- **Italic**: Brief asides or self-aware footnotes; keep them short.
- **Horizontal rules (`---`)**: Use **sparingly**—e.g. once between main article and a short postscript, not between every section.

---

## 8. Front matter (Hugo posts)

Mirror the project’s existing YAML shape in `content/posts/`:

```yaml
---
title: "Post title in Title Case or sentence case—match tone of the blog"
date: 2026-01-20T10:00:00+08:00
draft: true
tags: ["tag-one", "tag-two"]
cover:
  image: "/images/example.jpg"
  alt: "Descriptive alt text for the hero image"
---
```

- `title`, `date`, `draft`, and `tags` are standard.
- Include `cover` when the author supplies image path and alt text; otherwise omit `cover`.

---

## 9. Sign-offs

- **No fixed slogan**—vary the closing so posts do not feel templated.
- **On-brand patterns**: a single welcoming line, an invitation to try something concrete, or “let’s learn together” energy **without** repeating the same closing every time.

---

## 10. Code blocks

- Prefer **runnable** snippets when the language/stack is known; **pseudocode** is OK for architecture-only discussion if labelled as such.
- **Comments**: Short and purposeful—explain *why* or non-obvious constraints, not every line.
- Use **language tags** on fenced blocks (e.g. ` ```php `).

---

## 11. Words and phrases to avoid

Do not use these unless they are a direct quote or unavoidable API name:

- **Corporate hollow**: leverage, synergy, stakeholder engagement, best-in-class, world-class, cutting-edge, revolutionary, holistic, ecosystem (as filler), paradigm shift.
- **AI slop**: delve, unlock, landscape (as “the X landscape”), game-changer, ever-evolving, robust (as vague praise), supercharge, dive deep (as cliché), it’s worth noting that.
- **Empty intensifiers**: very, really, extremely (prefer a precise noun or metric).
- **Weaselly passives** that hide the actor—rewrite with **you** or **I** where honest.

---

## 12. Gold-standard excerpts (from this repo)

Treat the tone, pacing, and formatting below as **canonical** for personal + teaching posts (note: this excerpt predates the UK-spelling rule; new drafts should use UK spelling).

```markdown
I've been in this industry for almost 10 years now. Ten years as a full-stack developer, and I've just started my journey as a Solution Architect. That's a long time—long enough to accumulate experiences, lessons learned, and countless moments where I thought, "I wish someone had told me this earlier."

I've always loved teaching. There's something deeply satisfying about sharing knowledge, especially when it comes to writing good quality code. Long ago, I used to create classes as a part-time gig, not just for the extra income, but for that genuine satisfaction that comes from seeing someone understand a concept or solve a problem they've been struggling with.

But life gets busy. Responsibilities pile up. The part-time teaching had to take a backseat, and I found myself missing that connection—that opportunity to share what I've learned with others who might benefit from it.
```

Source: [`content/posts/01-how-i-ended-up-building-hugo-as-my-journal.md`](content/posts/01-how-i-ended-up-building-hugo-as-my-journal.md).

---

## 13. Quick checklist before hand-off

- [ ] UK English on new work; spelling matches file when editing legacy posts.
- [ ] “You” for guidance; “I” for experience; dry wit aimed at systems—not people.
- [ ] Oxford comma; em dashes for asides; sentence-case `##` headings.
- [ ] Mid-level assumptions—or one explicit level line up front.
- [ ] No banned-list filler; bold key terms; code blocks tagged and purposeful.
- [ ] Front matter matches Hugo conventions in this repo.

When the author gives contradictory instructions for a single task, **follow the author’s message** and note the exception briefly if useful.
