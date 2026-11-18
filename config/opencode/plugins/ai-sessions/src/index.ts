/*
 * Plan / guide / escalation hooks for OpenCode - the port of the Claude
 * SessionStart, PreToolUse, PostToolUse, PreCompact and SubagentStop hooks.
 *
 * -  SessionStart   session "context" hook, first call per process for a root
 *                   session: prunes stale bindings and topics, prints the plan
 *                   pointer, the new-session topic choice or the lost-binding
 *                   notice, arms the read gate, and keeps printing the pointer
 *                   while the gate stays armed.
 * -  PreToolUse     tool "execute.before": the plan read gate for every call,
 *                   the large-file read gate for `read`, and the escalation
 *                   edit gate for edit/write.
 * -  PostToolUse    tool "execute.after": clears escalations the main agent
 *                   has now read for itself, and enforces the reader ESCALATE
 *                   block on finished subagent calls.
 * -  PreCompact     session "compaction" hook: checkpoints a bounded tail of
 *                   the transcript before the summary runs, then flags the
 *                   next context call as post-compaction so the gate re-arms.
 *
 * Every hook fails open: an internal error lets the call proceed.
 */

import { Plugin } from "@opencode/plugin"
import fs from "node:fs"
import fsp from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import {
  AUX_AGENTS,
  BY_SESSION,
  CHECKPOINT_FILENAME,
  EDIT_MAX_DENIALS,
  ESCALATIONS,
  GATES,
  GATE_MAX_AGE_S,
  GATE_MAX_DENIALS,
  GUIDE_README_FILENAME,
  LARGE_READ_EXEMPT_ROOTS,
  LARGE_READ_MIN_LINES,
  LARGE_READ_MIN_LINES_ENV,
  LOCAL_INSTRUCTIONS,
  READER_TYPES,
  TOPIC_GUIDES_FILENAME,
  allGuides,
  armGate,
  attachedNames,
  checkpointTail,
  covers,
  describe,
  describeEntry,
  disarmGate,
  instructionsLine,
  listTopics,
  loadEscalations,
  loadGate,
  markSeen,
  planFor,
  pruneOldEscalations,
  readJson,
  recordStartup,
  saveEscalations,
  seenBefore,
  topicDirFor,
  writeAtomically,
} from "./state"
import type { EscalationEntry, Gate } from "./state"

/** Thrown to refuse a tool call; the message becomes the tool's error result */
class Block extends Error {}

type SessionState = { known: boolean; compact: boolean; fork: boolean; cwd: string }

const contextState = new Map<string, SessionState>()
const announcePending = new Map<string, EscalationEntry[]>()

/* ---------- small helpers ---------- */

function fileExists(file: string): boolean {
  try {
    return fs.statSync(file).isFile()
  } catch {
    return false
  }
}

function resolveSafe(raw: string, cwd: string): string {
  let candidate = raw.startsWith("~") ? path.join(os.homedir(), raw.slice(1)) : raw
  if (!path.isAbsolute(candidate)) candidate = path.resolve(cwd || ".", candidate)
  try {
    return fs.realpathSync.native(candidate)
  } catch {
    return candidate
  }
}

function toInt(value: unknown): number | undefined {
  return typeof value === "number" && Number.isInteger(value) && Number.isFinite(value) ? value : undefined
}

function isAux(agent: string | undefined): boolean {
  return agent !== undefined && AUX_AGENTS.includes(agent)
}

function gatewayDirectory(): string {
  return path.join(os.homedir(), ".local", "share", "ai-guides")
}

/* ---------- listing builders (port of session-start.py) ---------- */

const TOPIC_LISTING_MAX_ROWS = 8
const GUIDE_LISTING_MAX_ROWS = 10

function topicsListing(): string {
  const rows = listTopics()
  if (!rows.length) return "Existing topics: (none)"
  const ordered = [...rows].sort((a, b) => b.mtime - a.mtime)
  const shown = ordered.slice(0, TOPIC_LISTING_MAX_ROWS)
  const width = Math.max(...shown.map((row) => row.name.length))
  return [
    `Existing topics (newest first, ${shown.length} of ${ordered.length}):`,
    ...shown.map((row) => {
      const stamp = row.mtime ? new Date(row.mtime).toISOString().slice(0, 16).replace("T", " ") : "-"
      return `  ${row.name.padEnd(width)}  ${stamp}  ${row.summary}`
    }),
  ].join("\n")
}

type Guide = ReturnType<typeof allGuides>[number]

function guideRows(cwd: string, topicDir: string | null): { rows: string[]; needed: string[] } {
  const guides = new Map(allGuides().map((guide) => [guide.name, guide]))
  const attached = topicDir ? attachedNames(topicDir) : []
  const rows: string[] = []
  for (const name of attached) {
    const guide = guides.get(name)
    if (!guide) {
      rows.push(`  ${name}  MISSING - ${path.join(gatewayDirectory(), name, GUIDE_README_FILENAME)} does not exist`)
      continue
    }
    rows.push(`  ${guide.readme}  (attached to the plan)`)
  }
  const needed = [...attached]
  for (const guide of guides.values()) {
    if (!needed.includes(guide.name) && covers(guide, cwd)) {
      rows.push(`  ${guide.readme}  (covers the cwd)`)
      needed.push(guide.name)
    }
  }
  return { rows, needed }
}

function guidesListing(cwd: string, topicDir: string | null): string {
  const { rows, needed } = guideRows(cwd, topicDir)
  const lines: string[] = []
  if (rows.length) {
    lines.push(
      "READ THE README OF EACH GUIDE BELOW before working on the task - it says which of the guide's other files you need:",
    )
    lines.push(...rows)
  }
  const others = allGuides().filter((guide) => !needed.includes(guide.name))
  if (others.length) {
    const shown = others.slice(0, GUIDE_LISTING_MAX_ROWS)
    const width = Math.max(...shown.map((guide) => guide.name.length))
    lines.push(`Other guides in ${gatewayDirectory()} (${shown.length} of ${others.length}):`)
    lines.push(...shown.map((guide) => `  ${guide.name.padEnd(width)}  ${guide.description || "(no description)"}`))
  }
  if (topicDir) {
    lines.push(`Attach a guide to this plan: add its name to ${path.join(topicDir, TOPIC_GUIDES_FILENAME)}`)
  }
  return lines.join("\n")
}

function localInstructionsLine(): string {
  return (
    `LOCAL INSTRUCTIONS: ${LOCAL_INSTRUCTIONS} (${describe(LOCAL_INSTRUCTIONS)}) - part of the global ` +
    "instructions. OpenCode loads it automatically as a configured instruction"
  )
}

function planHeader(
  sessionID: string,
  plan: string,
  source: string,
  cwd: string,
  tail: string | null,
): string {
  const lines = [
    "READ YOUR PLAN FROM DISK BEFORE ANY OTHER TOOL CALL. It is not in context.",
    `  cat ${plan}`,
  ]
  if (tail) lines.push(`  cat ${tail}   # then merge live state into the plan and delete it`)
  lines.push(`ACTIVE PLAN FILE: ${plan}`)
  lines.push(`PLAN STATE: ${describe(plan)}`)
  lines.push(`SOURCE: ${source}   CWD: ${cwd}`)
  return lines.join("\n")
}

const PLAN_OPTIONS = [
  "  1. create a new topic (a new plan.md) for this work",
  "  2. bind this session to an existing topic from the list below",
  "  3. work without a plan - for a task too small to need one",
]

function noPlanHeader(
  sessionID: string,
  cwd: string,
  pruned: { bindings: number; topics: string[] },
  state: { source: string; lost: boolean },
): string {
  const lines = state.lost
    ? [
        `PLAN BINDING LOST for cwd=${cwd} session=${sessionID} (source=${state.source}). This session ran before, or was forked or resumed, but its plan is not bound now.`,
        "Say plainly that the binding was lost, then ask me to rebind an existing topic, create a new one, or continue without a plan.",
        "Do not pretend you have a plan and do not infer one from repository state.",
      ]
    : [
        `NEW SESSION - no plan is bound for cwd=${cwd} session=${sessionID} (source=${state.source}). This is expected for a new session, not a failure.`,
        "Ask me to choose one, then act on the answer:",
        ...PLAN_OPTIONS,
        "Do not report this as an error or say a topic could not be seen.",
      ]
  lines.push(topicsListing())
  lines.push(`Bind by session: write a topic name to ${path.join(BY_SESSION, sessionID)}`)
  lines.push("Ask before binding - do not infer the plan from repository state")
  lines.push(localInstructionsLine())
  const guideText = guidesListing(cwd, null)
  if (guideText) lines.push(guideText)
  if (pruned.bindings) lines.push(`(pruned ${pruned.bindings} stale session binding(s))`)
  if (pruned.topics.length) lines.push(`(pruned abandoned topic(s): ${pruned.topics.join(", ")})`)
  return lines.join("\n")
}

/* ---------- session "context" hook (SessionStart) ---------- */

async function getSessionInfo(ctx: any, sessionID: string): Promise<any | null> {
  try {
    const info: any = await ctx.session.get({ sessionID })
    return info?.data ?? info ?? null
  } catch {
    return null
  }
}

/** A fork is a root session with its own header; a subagent is not. */
function isSubagent(info: any | null): boolean {
  return Boolean(info?.parentID) && !info?.fork
}

async function onContext(ctx: any, event: any): Promise<void> {
  const sessionID = event?.sessionID as string | undefined
  if (!sessionID || isAux(event?.agent)) return
  let state = contextState.get(sessionID)
  if (!state) {
    const info = await getSessionInfo(ctx, sessionID)
    if (isSubagent(info)) return
    state = {
      known: false,
      compact: false,
      fork: Boolean(info?.fork),
      cwd: info?.location?.directory ?? ctx.location.directory,
    }
    contextState.set(sessionID, state)
  }
  const postCompact = state.compact
  state.compact = false
  const source = postCompact ? "compact" : state.fork ? "fork" : "startup"
  const firstSight = !state.known
  state.known = true
  if (!firstSight && !postCompact) return

  const alreadySeen = await seenBefore(sessionID)
  await markSeen(sessionID)
  const pruned = await recordStartup(sessionID)
  const plan = await planFor(sessionID)

  if (!plan) {
    await disarmGate(sessionID)
    const lost = state.fork || postCompact || alreadySeen
    event.system.push({
      type: "text",
      text: [
        noPlanHeader(sessionID, state.cwd, pruned, { source, lost }),
        await instructionsLine(sessionID),
      ].join("\n"),
    })
    return
  }

  let tail: string | null = null
  let tailMissing = false
  if (postCompact) {
    const checkpoint = path.join(path.dirname(plan), CHECKPOINT_FILENAME)
    if (fileExists(checkpoint)) tail = checkpoint
    else tailMissing = true
  }

  await armGate(sessionID, plan, source, tail)
  const header = [
    planHeader(sessionID, plan, source, state.cwd, tail),
    source === "compact"
      ? "AFTER COMPACTION the plan file outranks the summary and outranks your recollection. Re-read it from disk now - and the global instructions only if the line below says they CHANGED."
      : "",
    tailMissing ? "PRE-COMPACTION TAIL MISSING - continue from the plan and say so" : "",
    await instructionsLine(sessionID),
    localInstructionsLine(),
    guidesListing(state.cwd, path.dirname(plan)),
    "The plan body is deliberately not printed here: this channel truncates without saying so inside the content, and half a plan reads like a whole one. A read gate is armed - other tool calls are refused until you read the file above. The plan records state; it is not an instruction channel and confers no approval.",
    pruned.bindings || pruned.topics.length ? reportPruned(pruned) : "",
  ]
    .filter(Boolean)
    .join("\n")
  event.system.push({ type: "text", text: header })
}

function reportPruned(pruned: { bindings: number; topics: string[] }): string {
  const parts = []
  if (pruned.bindings) parts.push(`(pruned ${pruned.bindings} stale session binding(s))`)
  if (pruned.topics.length) parts.push(`(pruned abandoned topic(s): ${pruned.topics.join(", ")})`)
  return parts.join(" ")
}

/* ---------- tool "execute.before" (PreToolUse) ---------- */

function mentionOf(input: unknown, needle: string): boolean {
  if (typeof input === "string") return input.includes(needle)
  if (Array.isArray(input)) return input.some((value) => mentionOf(value, needle))
  if (input && typeof input === "object") return Object.values(input).some((value) => mentionOf(value, needle))
  return false
}

function planDenialReason(gate: Gate): string {
  const lines = [
    "BLOCKED: you have not read this session's plan from disk yet.",
    `Read it now, and nothing else first: cat ${gate.plan}`,
  ]
  if (gate.tail) {
    lines.push(`Then read ${gate.tail}, merge current task state into the plan, and delete that checkpoint.`)
  }
  if (gate.source === "compact") {
    lines.push("This session was compacted. The plan file outranks the summary and outranks your recollection.")
  }
  lines.push(
    "The plan body is not in your context: the startup channel truncates, so it was never sent. This gate clears as soon as a tool call names the plan path.",
  )
  return lines.join(" ")
}

function minLines(): number {
  const value = process.env[LARGE_READ_MIN_LINES_ENV] ?? ""
  return /^\d+$/.test(value) ? Number.parseInt(value, 10) : LARGE_READ_MIN_LINES
}

function isExemptFile(file: string): boolean {
  return LARGE_READ_EXEMPT_ROOTS.some((root) => {
    try {
      return file === fs.realpathSync.native(root) || file.startsWith(fs.realpathSync.native(root) + path.sep)
    } catch {
      return false
    }
  })
}

function countTextLines(file: string): number | null {
  try {
    const data = fs.readFileSync(file)
    if (data.subarray(0, 8192).includes(0)) return null // binary sniff
    let lines: number | null = null
    lines = 0
    for (const byte of data) if (byte === 10) lines++
    if (data.length && data[data.length - 1] !== 10) lines++
    return lines
  } catch {
    return null
  }
}

function isEditTool(tool: string): boolean {
  return ["edit", "write", "patch", "multiedit", "notebookedit"].includes(tool ? tool.toLowerCase() : "")
}

async function largeReadGate(event: any, input: any): Promise<void> {
  if (input?.offset !== undefined || input?.limit !== undefined) return
  const raw = input?.filePath ?? input?.file_path
  if (!raw) return
  const file = resolveSafe(String(raw), process.cwd())
  if (!fileExists(file) || isExemptFile(file)) return
  const lines = countTextLines(file)
  const threshold = minLines()
  if (lines !== null && lines > threshold) {
    throw new Block(
      `BLOCKED: whole-file Read of a ${lines}-line file (threshold ${threshold}). ` +
        "Delegate it: subagent with agent careful-reader (needs understanding; the default) or bulk-reader " +
        "(mechanical: exports, definitions, shapes). Give it the paths and one precise question. If you need " +
        "exact lines to edit, Read again with offset/limit for just that section",
    )
  }
}

async function escalationEditGate(sessionID: string, target: string): Promise<void> {
  const entries = await loadEscalations(sessionID)
  const blocking = entries.filter((entry) => entry.path === target)
  if (!blocking.length) return
  for (const entry of blocking) entry.denials++
  const remaining = entries.filter((entry) => entry.denials <= EDIT_MAX_DENIALS)
  await saveEscalations(sessionID, remaining)
  const stillBlocking = remaining.filter((entry) => blocking.includes(entry))
  if (!stillBlocking.length) return
  throw new Block(
    [
      "BLOCKED: a reader escalated ranges in this file and you have not read them yourself. Read each with offset/limit, then retry the edit:",
      ...stillBlocking.map((entry) => `[${describeEntry(entry)}]`),
    ].join(" "),
  )
}

/* ---------- tool "execute.after" (PostToolUse + reader-stop) ---------- */

const ESCALATE_HEADER = /^\W*ESCALATE\W*:?\s*(.*)$/i
const ESCALATE_ENTRY = /^\s*[-*\d.)]*\s*`?([^\s`:]+):(\d+)(?:-(\d+))?`?\s*[-:]*\s*(.*)$/
const ESCALATE_NONE = /^\W*none\b/i
const MISSING_BLOCK_REASON =
  "Your answer has no ESCALATE block. End it with 'ESCALATE: none', or with 'ESCALATE:' followed by one line per range: '- path:start-end - reason'. Do not repeat the rest of your answer"

type ParsedEntry = { path: string; start: number; end: number; reason: string }

function parseEscalate(text: string): ParsedEntry[] | null {
  const lines = text.split(/\r?\n/)
  for (let index = lines.length - 1; index >= 0; index--) {
    const header = ESCALATE_HEADER.exec(lines[index])
    if (!header) continue
    if (ESCALATE_NONE.test(header[1] ?? "")) return []
    const found: ParsedEntry[] = []
    for (const line of [header[1] ?? "", ...lines.slice(index + 1)]) {
      const match = ESCALATE_ENTRY.exec(line)
      if (!match) continue
      const start = Number.parseInt(match[2], 10)
      found.push({
        path: match[1],
        start,
        end: match[3] ? Number.parseInt(match[3], 10) : start,
        reason: (match[4] ?? "").trim(),
      })
    }
    return found
  }
  return null
}

function resultText(result: any): string | null {
  const content = result?.content
  if (typeof content === "string") return content || null
  if (Array.isArray(content)) {
    const text = content
      .filter((part: any) => part?.type === "text")
      .map((part: any) => part?.text ?? "")
      .join("\n")
    return text || null
  }
  return null
}

function setResultText(result: any, text: string): void {
  if (Array.isArray(result?.content)) result.content = [{ type: "text", text }]
  else result.content = text
}

function childSessionID(result: any): string | null {
  const metadata: any = result?.metadata ?? result?.output ?? {}
  const candidate = metadata?.childSessionID ?? metadata?.sessionID ?? metadata?.child_session_id
  return typeof candidate === "string" && candidate ? candidate : null
}

async function storeEscalations(sessionID: string, agentType: string, parsed: ParsedEntry[], cwd: string): Promise<void> {
  if (!parsed.length) return
  const stored = await loadEscalations(sessionID)
  for (const entry of parsed) {
    stored.push({
      path: resolveSafe(entry.path, cwd),
      start: entry.start,
      end: entry.end,
      reason: entry.reason,
      agent_type: agentType,
      is_announced: false,
      denials: 0,
    })
  }
  await saveEscalations(sessionID, stored)
  announcePending.set(
    sessionID,
    stored.map((entry) => ({ ...entry })),
  )
}

async function enforceReaderBlock(ctx: any, event: any): Promise<void> {
  const input = event?.input ?? {}
  const agent = input?.agent ?? input?.agentID ?? input?.agent_type ?? input?.subagent_type
  if (typeof agent !== "string" || !READER_TYPES.includes(agent)) return
  if (input?.background) return // a background child is still running; fail open here
  const text = resultText(event?.result)
  if (!text) return
  const parsed = parseEscalate(text)

  if (parsed === null) {
    const childID = childSessionID(event?.result)
    if (!childID) {
      setResultText(
        event.result,
        text +
          "\n(The reader did not end with an ESCALATE block - treat any part of its answer you cannot verify yourself as unjudged.)",
      )
      return
    }
    let amended: string | null = null
    try {
      await ctx.session.prompt({ sessionID: childID, text: MISSING_BLOCK_REASON })
      await ctx.session.wait({ sessionID: childID })
      const messages: any[] = await ctx.session.context({ sessionID: childID })
      for (let index = messages.length - 1; index >= 0; index--) {
        const message: any = messages[index]
        const info: any = message?.info ?? message
        if (!String(info?.role ?? "").startsWith("assistant")) continue
        const parts: any[] = message?.parts ?? []
        const joined = parts
          .filter((part: any) => part?.type === "text")
          .map((part: any) => part?.text ?? "")
          .join("\n")
        if (joined.trim()) {
          amended = joined
          break
        }
      }
    } catch {
      amended = null
    }
    if (amended) {
      setResultText(event.result, amended)
      await storeEscalations(event.sessionID, agent, parseEscalate(amended) ?? [], ctx.location.directory)
      await pruneOldEscalations().catch(() => {})
    } else {
      setResultText(
        event.result,
        text +
          "\n(The reader did not end with an ESCALATE block and did not answer when asked to add one - treat any part of its answer you cannot verify yourself as unjudged.)",
      )
    }
    return
  }

  await storeEscalations(event.sessionID, agent, parsed, ctx.location.directory)
  await pruneOldEscalations().catch(() => {})
}

async function onToolAfter(ctx: any, event: any): Promise<void> {
  const sessionID = event?.sessionID as string
  if (!sessionID || isAux(event?.agent)) return
  const input = event?.input ?? {}

  if (event.tool === "read" && input?.filePath) {
    const target = resolveSafe(String(input.filePath), process.cwd())
    const entries = await loadEscalations(sessionID)
    const offset = toInt(input.offset)
    const limit = toInt(input.limit)
    const remaining = entries.filter(
      (entry) => entry.path !== target || !overlapsEntry(entry, offset, limit),
    )
    if (remaining.length !== entries.length) await saveEscalations(sessionID, remaining)
    if (announcePending.has(sessionID)) return
  }

  if (event.tool === "subagent" && event.status === "completed") {
    await enforceReaderBlock(ctx, event)
  }
}

function overlapsEntry(entry: { start: number; end: number }, offset?: number, limit?: number): boolean {
  if (offset === undefined && limit === undefined) return true
  const first = offset ?? 1
  if (limit === undefined) return first <= entry.end
  return first <= entry.end && entry.start < first + limit
}

/* ---------- plugin ---------- */

export default Plugin.define({
  id: "ai-sessions",
  async setup(ctx) {
    await ctx.session.hook("context", (event: any) =>
      Promise.resolve()
        .then(() => onContext(ctx, event))
        .catch(() => {}),
    )

    await ctx.session.hook("compaction", (event: any) =>
      Promise.resolve()
        .then(() => preCompact(ctx, event))
        .catch(() => {}),
    )

    await ctx.tool.hook("execute.before", async (event: any) => {
      try {
        const sessionID = event?.sessionID as string
        const input = event?.input ?? {}

        // The plan read gate. It fails open: after four refusals and after an
        // hour it disarms, and any internal error allows the call.
        const gate = loadGate(sessionID)
        if (gate && "plan" in gate) {
          if (Date.now() - gate.armed_at > GATE_MAX_AGE_S * 1000) {
            await disarmGate(sessionID)
          } else if (mentionOf(input, gate.plan)) {
            await disarmGate(sessionID)
          } else if (isAux(event?.agent)) {
            /* readers may act without the plan */
          } else {
            gate.denials++
            if (gate.denials > GATE_MAX_DENIALS) {
              await disarmGate(sessionID)
            } else {
              await writeAtomically(path.join(GATES, `${sessionID}.json`), Buffer.from(JSON.stringify(gate)))
              throw new Block(planDenialReason(gate))
            }
          }
        }

        if (isAux(event?.agent)) return
        if (event.tool === "read") await largeReadGate(event, input)
        if (isEditTool(event.tool)) {
          const raw = input?.filePath ?? input?.file_path ?? input?.notebook_path
          if (raw) await escalationEditGate(sessionID, resolveSafe(String(raw), ctx.location.directory))
        }
      } catch (error) {
        if (error instanceof Block) throw error
      }
    })

    await ctx.tool.hook("execute.after", async (event: any) => {
      try {
        await onToolAfter(ctx, event)
      } catch {}
    })

    return () => {
      contextState.clear()
      announcePending.clear()
    }
  },
})

async function preCompact(ctx: any, event: any): Promise<void> {
  const sessionID = event?.sessionID as string
  if (!sessionID) return
  const topicDir = await topicDirFor(sessionID).catch(() => null)
  if (!topicDir) return
  const messages = Array.isArray(event?.messages) ? event.messages : []
  if (!messages.length) return
  await writeAtomically(
    path.join(topicDir, CHECKPOINT_FILENAME),
    checkpointTail(messages),
  )
  const state = contextState.get(sessionID)
  if (state) state.compact = true
}

/* re-exports used by tests of the module surface */
export { contextState, announcePending }

/* keep the readJson helper referenced for future session-state reads */
void readJson
void pruneOldEscalations
