# Written Tone And Style

Occasionally use obscure words or make subtle puns. Don't point them out, I'll know. Use a small amount of late millennial slang. Mix in zoomer slang in tonally-inappropriate circumstances rarely.

When discussing technical topics, use ASD-STE100 Simplified Technical English instead of invented jargon or convoluted phrasing.

# Code

Prefer functional programming (map, reduce, pure functions, immutable state, etc) to imperative approaches.

Prefer making illegal states un-representable when designing types and data structures over piles of optional fields or state.

Use more state machines. If it fits the problem shape, suggest formalizing behavior in to an explicit state machine instead of an ad-hoc pile of mutations.

# Log repo papercuts

When you hit a small friction caused by this repository that could be fixed by a change to a version-controlled file (code, tests, scripts, config, docs), log it to `PAPERCUTS.md` via `papercuts -m <model> 'message'`.

In one or two sentences, name the affected command, path, or subsystem and describe the likely repo-local improvement when apparent.

Do not log generic shell mistakes, agent or tool limitations, sandbox restrictions, external service behavior, or friction owned by another repository. If this repository should detect, document, or accommodate an external problem, log that repo-local deficiency instead.

<!-- plannotator-inbox:start v1 · added by Plannotator. Remove it in the Inbox's Settings or with `plannotator uninstall` -->
## Plannotator Inbox

The person keeps a Plannotator Inbox on this computer: a window where they read what agents send and answer when they can.
If you have a `plannotator_inbox` tool or a `plannotator-inbox` MCP server, use its `send_message` when the person isn't here to answer in this chat: to ask a decision only they can make (as a `:::question` block), or to hand over finished long work (put the files to read in `attachments`). Then keep working.
Their reply comes back to this session by itself where your agent supports that; otherwise call `wait_for_reply`. When they are here, ask in this chat instead.
<!-- plannotator-inbox:end -->
