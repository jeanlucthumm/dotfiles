import type { EngineInterface as Api, Register } from 'claude-code'

const TOOL = 'mcp__self-compact__compact_after_turn'

// Context note: once per threshold crossing, a neutral note in the session's own
// conversation. The session decides whether and when to compact.
const LIMITS = { planner: 45, executor: 45 }
const PLANNER_NAME = /\b(planning|planner|design)\b/i
const REARM_GAP = 5 // re-arm once the fill drops this far under the threshold (it compacted)
const MARK = '[context note]'
const SUMMARY_START = 'This session is being continued' // first words of a compaction summary

// Set by the tool call, consumed at the end of the main loop's turn. A reload
// drops it, which only loses a pending request.
let pending = false
// Per load: the session's role, and whether this crossing's note is out
// (undefined until checked against the conversation, which survives reloads).
let role: keyof typeof LIMITS | undefined
let noted: boolean | undefined

// The session's display name lives in ~/.claude/sessions/<pid>.json; the mod sits
// somewhere under ~/.claude.
async function sessionName($: Api): Promise<string> {
  const id = await $.session.id()
  const dir = $.plugin.root.replace(/\/\.claude\/.*$/, '/.claude/sessions')
  for (const entry of await $.fs.list(dir)) {
    if (!entry.name.endsWith('.json')) continue
    try {
      const d = JSON.parse(String(await $.fs.read(`${dir}/${entry.name}`)))
      if (d.sessionId === id) return String(d.name ?? '')
    } catch {
      // another session's file mid-write; skip it
    }
  }
  return ''
}

// True when this crossing's note is already in the conversation since the last
// compaction (a reload or restart forgets `noted`, the conversation doesn't).
async function noteSinceCompaction($: Api): Promise<boolean> {
  const messages = await $.session.messages()
  for (const m of [...messages].reverse()) {
    if (m.role !== 'user') continue
    if (m.text.startsWith(SUMMARY_START)) return false
    if (m.text.startsWith(MARK)) return true
  }
  return false
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'compact_after_turn',
      description:
        'Compact this conversation, as /compact does, once the current turn ends. ' +
        'Whether and when to compact is your call. If you do, run /pre-compact first so your ' +
        'notes are saved, then call this and end the turn.',
      inputSchema: { type: 'object', properties: {} },
      isDeferred: true,
    })
    return next(e)
  })

  on('tool.call', { tool: TOOL }, async () => {
    pending = true
    return { result: 'Compaction queued for when this turn ends. End the turn now.' }
  }).catch(() => ({ deny: 'self-compact: could not queue the compaction' }))

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (pending && e.agentId === undefined && !e.isAborted) {
      pending = false
      // Input already waiting (a peer message, a due wakeup, a task notification)
      // can start the next turn before this call lands, and compact rejects while
      // a turn runs. Keep the request so the next main-loop turn end retries.
      $.session.compact({}).catch(err => {
        pending = true
        $.ui.toast(`self-compact: ${String(err)}`)
      })
    }
    return done
  })

  on('session.measure', async ($, e, next) => {
    const done = await next(e)
    const pct = e.context.percent
    if (pct === undefined || pct < Math.min(...Object.values(LIMITS)) - REARM_GAP) {
      noted = pct === undefined ? noted : false
      return done
    }
    role ??= PLANNER_NAME.test(await sessionName($)) ? 'planner' : 'executor'
    const limit = LIMITS[role]
    if (pct < limit - REARM_GAP) noted = false
    if (pct < limit || noted) return done
    noted = await noteSinceCompaction($)
    if (noted) return done
    noted = true
    const text =
      `${MARK} Your context is at ${pct}% of its window; the threshold for your role ` +
      `(${role}) is ${limit}%. Whether and when to compact is your call. The mechanism, if ` +
      `you use it: /pre-compact, then the ${TOOL} tool, which compacts once your turn ends.`
    await $.session.append({ message: { type: 'user', content: [{ type: 'text', text }] } })
    return done
  }).catch(($, e, next) => next(e))
}
