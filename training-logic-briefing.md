# Smart Training Logic: From Content Repository to Dog Operating System

**Developer Briefing — Otis App**
**Date: March 2026**

---

## The Core Problem

Most puppy training apps treat skills as a linear checklist: finish Skill 1, unlock Skill 2. In reality, dog training is a concurrent, interleaved process where previously mastered skills require ongoing maintenance, new skills build on old ones, and failure on a "completed" skill must trigger re-prioritization. This document describes the rules and logic needed to make the app's training engine genuinely intelligent.

---

## 1. The Skill Lifecycle (Phases Within a Module)

Each training module (e.g. "Look at Me", "Sit", "Recall") should progress through distinct phases. The standard progression, well-established in professional dog training, is:

1. **Luring/Shaping** — The dog learns the physical behavior through a food lure or successive approximation. No verbal cue yet.
2. **Adding the Cue** — A verbal command (and/or hand signal) is paired with the now-familiar behavior.
3. **Proofing via the 3Ds** — The behavior is tested and reinforced across three independent dimensions:
   - **Duration** — How long the dog holds the behavior.
   - **Distance** — How far the handler is from the dog.
   - **Distraction** — Environmental complexity (other dogs, noise, new locations).
4. **Generalization** — The behavior is practiced in novel environments to ensure it transfers beyond the training context.
5. **Maintenance** — The behavior is considered "mastered" but enters a spaced repetition cycle.

### Critical rule: Only increase one D at a time

When making any single dimension harder, the other two should be reset to easy. If you add distance, drop duration back to seconds and minimize distractions. This is non-negotiable in the training science — the AKC, Susan Garrett, and guide dog programs all converge on this principle. The app should enforce or at least strongly guide this.

### The ping-pong pattern

Within each dimension, difficulty should not increase linearly. The recommended approach is to "ping-pong" — e.g. hold for 10 seconds, then 5, then 15, then 8, then 20. This prevents the dog from predicting the pattern and builds genuine understanding rather than rote compliance.

---

## 2. Mastery Criteria and Progression Thresholds

Research from the University of Copenhagen (Meyer & Ladewig, 2008) used the following criterion in their peer-reviewed studies on canine learning:

- **≥80% success rate** at a given step → advance to the next step.
- **<20% success rate** → regress to the previous step.
- Each session begins with 3 "warm-up" trials at the current step. If the dog fails all 3, stay at the previous step.

For the app, a practical implementation:

| Success Rate | Action |
|---|---|
| **90–100%** | Advance to next phase/stage. Skill enters lighter maintenance. |
| **80–89%** | Advance, but schedule a confirmation check within 48 hours. |
| **50–79%** | Stay at current stage. Repeat with variation. |
| **Below 50%** | Step back one stage. Flag to the user that this needs focus. |

The "10 out of 10 in any context" standard the app aims for maps to the generalization phase. A skill is only truly mastered when it hits 90%+ success across multiple environments and distraction levels. Until then, it is still in the proofing pipeline.

---

## 3. Interleaving: The Session Composition Engine

This is the biggest architectural shift. Instead of "do Module 1 until done, then Module 2," each training session should be a **mixed playlist** of skills at various stages. The research-backed ratio:

### The 70/30 Rule (adapted for multi-skill training)

A training session should roughly follow:

- **~60–70% primary focus** — The skill(s) currently being actively taught or proofed.
- **~20–30% maintenance review** — Quick reps of previously mastered skills.
- **~10% warm-up / engagement** — Easy wins to start the session (a skill the dog loves and nails every time).

### Why interleaving matters

Cognitive science research on "interleaved practice" (mixing different types of problems rather than blocking them) consistently shows better long-term retention — both in humans and animals. Massed practice (grinding one skill) feels more productive but produces worse retention than spaced, interleaved practice.

For dogs specifically, the University of Copenhagen studies found that dogs trained with spaced sessions (1–2x per week per skill) learned tasks in fewer total sessions than dogs trained daily on the same skill, and showed better long-term retention.

### Practical session template

For a 5–10 minute session:

1. **Warm-up** (1 min) — One easy, mastered behavior. Gets the dog into training mode and earns quick rewards.
2. **New skill work** (3–5 min) — The current primary module at its active phase.
3. **Maintenance reps** (2–3 min) — 2–3 quick reps each of 1–3 previously mastered skills, selected by the spaced repetition algorithm.
4. **Easy finish** (30 sec) — End on a success. Always.

---

## 4. The Spaced Repetition Algorithm for Maintenance

Once a skill reaches "mastered" status, it enters a maintenance queue governed by expanding intervals. This is directly analogous to how Anki/SRS systems work for language learning:

### Interval schedule

| Review # | Interval | Notes |
|---|---|---|
| 1st review after mastery | 1 day | Confirm it stuck |
| 2nd review | 3 days | |
| 3rd review | 1 week | |
| 4th review | 2 weeks | |
| 5th review | 1 month | |
| 6th+ review | 2–3 months | Ongoing lifetime maintenance |

### On success (80%+ in maintenance check)
→ Interval doubles (or expands per schedule). Confidence score increases.

### On failure (<80% in maintenance check)
→ This is the critical logic. The skill **must** be escalated:

1. Interval resets to the shortest tier (1 day).
2. The skill's status changes from "Mastered" back to "Needs Work."
3. In the next session, this skill gets promoted into the **primary focus** slot, displacing whatever new skill was being worked on.
4. The new skill being learned gets temporarily demoted to secondary focus until the regressed skill is re-stabilized at 80%+.

This is the "regression trumps progression" rule: solidifying a slipping foundation is always more important than building new floors.

---

## 5. Priority Queue Logic

The app needs a priority system to decide what goes into each session. Here's a proposed hierarchy:

### Priority 1: Regression Recovery
Any previously mastered skill that has failed a maintenance check. These get primary session time until re-stabilized.

### Priority 2: Active Learning
The current skill module being taught (at whatever phase it's in). This is the "new stuff."

### Priority 3: Scheduled Maintenance
Skills that are due for their next spaced repetition review. The app should surface these proactively ("Ollie hasn't practiced Recall in 12 days — let's do a quick check").

### Priority 4: Generalization Opportunities
If the user is training in a new location (detectable via GPS or user input), the app should suggest running maintenance checks there, since location changes are a form of distraction proofing.

### Priority 5: Enrichment / Fun
Optional tricks or games that aren't core obedience but keep training enjoyable.

---

## 6. Additional Considerations the Developer Should Know

### Session length and frequency matter more than you think

Research shows that short sessions (5–10 minutes for puppies, up to 15 for adults) significantly outperform longer sessions. Multiple short sessions per day beat one long one. The app should actively discourage sessions over 10 minutes for puppies and nudge toward 3–5 sessions spread through the day.

### The "always end on a success" rule

If a session is going poorly, the app should suggest dropping back to an easy behavior and ending there rather than grinding through failures. This is not just motivational — it prevents the dog from associating training with frustration and avoids the handler inadvertently reinforcing incorrect behavior through repetition.

### Variable reinforcement schedules

Dr. Ian Dunbar's work emphasizes that continuous reinforcement (reward every correct response) actually undermines reliability long-term. Once a behavior is learned, the app should guide users toward variable ratio reinforcement — rewarding randomly rather than every time. This makes the behavior far more resistant to extinction. The app could implement this as coaching tips during the maintenance phase: "Try rewarding only 3 out of 5 correct responses this time."

### Don't chain behaviors predictably

The AKC advises against always practicing skills in the same sequence (sit → down → stay). Dogs learn the chain rather than the individual cues. The session playlist should randomize the order of maintenance skills.

### Context specificity is real

Dogs do not generalize well. A dog that sits perfectly in the kitchen genuinely may not understand "sit" means the same thing at the park. The app should track *where* skills have been practiced and proofed (home, garden, park, street, indoor public space) and surface prompts to practice in new contexts.

### Regression is normal, not failure

The app's UX should normalize regression. When a mastered skill slips, the messaging should be encouraging ("Time for a refresher!") rather than implying the dog or owner failed. Regression is an expected part of the learning curve, especially during adolescence (6–18 months) when dogs commonly "forget" things they knew as puppies.

### Puppy age considerations

Young puppies (8–12 weeks) have very short attention spans. Sessions should be 3–5 minutes max, 3–5 times daily. The app should adjust session templates and expectations based on the puppy's age, which affects everything from bladder control (relevant for training breaks) to the socialization window (3–14 weeks is critical).

---

## 7. What This Means for the UI/UX

The current "finish one, then the next" flow needs to be replaced with:

1. **A dynamic "Today's Training" view** — An algorithmically generated session plan mixing new learning, maintenance, and warm-ups. Think of it as a smart playlist, not a linear curriculum.

2. **Skill cards with status indicators** — Each skill should show its current phase, last practiced date, next review date, and a confidence/reliability score based on logged success rates.

3. **Quick-log after each rep** — The user needs a fast way to record success/failure per attempt. This feeds the algorithm. Could be as simple as a thumbs up/down or a swipe gesture. Friction here kills data quality.

4. **Regression alerts** — When a maintenance check fails, a clear but non-alarming notification that reprioritizes the training plan. "Recall needs some love — we've moved it to your focus list."

5. **Location-aware prompting** — If the app detects a new location (or the user tags one), suggest running a generalization check on mastered skills.

6. **Progress visualization** — Not just "complete/incomplete" but a nuanced view: learning → proofing → mastered → maintaining, with the 3D dimensions visible (Duration ✓, Distance ✓, Distraction: in progress).

7. **Session timer with gentle limits** — A visible timer that encourages short sessions and warns when the session is getting long, especially for puppies.

---

## 8. Summary of Golden Rules

1. **80% is the threshold.** Below 80% success = don't advance. Above 80% = ready to progress.
2. **Regression trumps progression.** A slipping old skill always gets priority over a shiny new one.
3. **One D at a time.** Never increase duration, distance, and distraction simultaneously.
4. **Interleave, don't block.** Mix skills in every session. ~60–70% new work, ~20–30% maintenance.
5. **Space it out.** Expanding intervals for maintenance reviews. More spacing = better retention.
6. **End on a win.** Every session finishes with a successful behavior.
7. **Short and frequent beats long and rare.** Multiple 5-minute sessions > one 30-minute session.
8. **Randomize order.** Don't let skills become a predictable chain.
9. **Track context.** A skill isn't mastered until it works in multiple locations and distraction levels.
10. **Normalize regression.** Especially during adolescence. It's biology, not failure.

---

## References & Further Reading

- Meyer, I. & Ladewig, J. (2008). The relationship between number of training sessions per week and learning in dogs. *Applied Animal Behaviour Science.*
- Demant, H. et al. (2011). The effect of frequency and duration of training sessions on acquisition and long-term memory in dogs. *Applied Animal Behaviour Science.*
- Dunbar, I. (2010). Reinforcement Schedules. *Dog Star Daily.*
- Garrett, S. (2020). The 3D Model for Dog Training: Duration, Distance, Distraction.
- AKC (2024). The Three Ds of Dog Training. *American Kennel Club Expert Advice.*
- AKC (2018). Important Rule of Dog Training: One Thing at a Time.
- Brown, P.C., Roediger, H.L. & McDaniel, M.A. (2014). *Make It Stick: The Science of Successful Learning.* Harvard University Press.
- Smolen, P., Zhang, Y. & Bhyne, J.H. (2016). The right time to learn: mechanisms and optimization of spaced learning. *Nature Reviews Neuroscience.*
