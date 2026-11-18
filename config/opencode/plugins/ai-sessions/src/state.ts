/*
 * Shared state for the ai-sessions plugin: bindings, gates, digests, guides and
 * escalations. A port of the Claude hook modules plan_state.py, guide_state.py
 * and escalation_state.py to live beside them under the same root, so Claude,
 * Codex and OpenCode read and act on the same plan topics and guides.
 *
 * The header never prints a plan body. The gate makes reading it the only
 * thing the session can do first.
 */

import { createHash } from "node:crypto"
import os from "node:os"
import path from "node:path"
import fs from "node:fs"
import fsp from "node:fs/promises"

export const HOME = os.homedir()

export const ROOT = path.join(HOME, ".local", "share", "ai-sessions")
export const BY_SESSION = path.join(ROOT, ".by-session")
export const GATES = path.join(ROOT, ".gates")
export const STATE = path.join(ROOT, ".state")
export const ESCALATIONS = path.join(ROOT, ".escalations")
export const CHECKPOINT_FILENAME = "pre-compact-tail.jsonl"
export const PLAN_FILENAME = "plan.md"

export const GUIDES_ROOT = path.join(HOME, ".local", "share", "ai-guides")
export const GUIDE_README_FILENAME = "README.md"
export const TOPIC_GUIDES_FILENAME = "guides"
const FRONT_MATTER_FENCE = "---"

export const DIGEST_CHARS = 12
export const GATE_MAX_DENIALS = 4
export const GATE_MAX_AGE_S = 3600
export const EDIT_MAX_DENIALS = 2
export const STATE_MAX_AGE_S = 30 * 86400
export const BINDING_MAX_AGE_DAYS = 30
export const TOPIC_MAX_AGE_DAYS = 30
const SECONDS_PER_DAY = 86400

export const LARGE_READ_MIN_LINES = 350
export const LARGE_READ_MIN_LINES_ENV = "LARGE_READ_MIN_LINES"
const BINARY_SNIFF_BYTES = 8192
export const LARGE_READ_EXEMPT_ROOTS = [
  ROOT,
  GUIDES_ROOT,
  path.join(HOME, ".config", "claude"),
  path.join(HOME, ".config", "codex"),
  path.join(HOME, ".config", "opencode"),
]

/** The Python hooks print and store these paths; keep the wording in step. */
export const INSTRUCTION_FILES = [
  path.join(HOME, ".config", "claude", "CLAUDE.md"),
  path.join(HOME, ".config", "codex", "AGENTS.md"),
  path.join(HOME, ".config", "opencode", "AGENTS.md"),
]
export const LOCAL_INSTRUCTIONS = path.join(HOME, ".config", "claude", "work.md")

export const READER_TYPES = ["bulk-reader", "careful-reader", "deep-reader"]
export const AUX_AGENTS = [...READER_TYPES, "general", "explore", "compaction", "title", "summary"]

export type Gate = {
  plan: string
  plan_digest?: string
  tail?: string | null
  source?: string
  armed_at: number
  denials: number
}

export type EscalationEntry = {
  path: string
  start: number
  end: number
  reason: string
  agent_type: string
  is_announced: boolean
  denials: number
}

/* ---------- files ---------- */

export async function writeAtomically(destination: string, data: Buffer): Promise<void> {
  await fsp.mkdir(path.dirname(destination), { recursive: true })
  const temp = path.join(path.dirname(destination), `.tmp-${process.pid}-${Date.now()}`)
  const handle = await fsp.open(temp, "w")
  try {
    await handle.writeFile(data)
    await handle.datasync()
  } finally {
    await handle.close()
  }
  await fsp.rename(temp, destination)
}

export async function readJson<T>(file: string): Promise<T | null> {
  try {
    return JSON.parse(await fsp.readFile(file, "utf8")) as T
  } catch {
    return null
  }
}

export function digest(file: string): string {
  try {
    const data = fs.readFileSync(file)
    return createHash("blake2b512").update(data).digest("hex").slice(0, DIGEST_CHARS)
  } catch {
    return "unreadable"
  }
}

export function describe(file: string): string {
  try {
    const data = fs.readFileSync(file)
    const stamp = new Date(fs.statSync(file).mtimeMs).toISOString().slice(0, 16).replace("T", " ")
    const lines = data.includes(0) ? data.length : countLines(data)
    return `${data.length} bytes, ${lines} lines, blake2b ${digest(file)}, modified ${stamp}`
  } catch {
    return "(unreadable)"
  }
}

function countLines(data: Buffer): number {
  let lines = 0
  for (const byte of data) if (byte === 10) lines++
  if (data.length && data[data.length - 1] !== 10) lines++
  return lines
}

/* ---------- bindings and topics ---------- */

export async function topicDirFor(sessionID: string): Promise<string | null> {
  if (!sessionID) return null
  const binding = path.join(BY_SESSION, sessionID)
  let topic: string
  try {
    topic = (await fsp.readFile(binding, "utf8")).trim()
  } catch {
    return null
  }
  if (!topic) return null
  const root = fs.realpathSync.native(ROOT)
  const topicDir = fs.realpathSync.native(path.resolve(ROOT, topic))
  if (!topicDir.startsWith(root + path.sep) || topicDir === root) {
    throw new Error(`unsafe topic binding for session ${sessionID}`)
  }
  return topicDir
}

export async function planFor(sessionID: string): Promise<string | null> {
  const topicDir = await topicDirFor(sessionID).catch(() => null)
  if (!topicDir) return null
  const plan = path.join(topicDir, PLAN_FILENAME)
  return fileExists(plan) ? plan : null
}

function fileExists(file: string): boolean {
  try {
    fs.statSync(file)
    return true
  } catch {
    return false
  }
}

function isTopicDir(entry: string): boolean {
  try {
    return fs.statSync(entry).isDirectory() && !path.basename(entry).startsWith(".") && path.basename(entry) !== "bin"
  } catch {
    return false
  }
}

function newestMtime(topic: string): number {
  let newest = 0
  try {
    newest = fs.statSync(topic).mtimeMs
    for (const child of walk(topic)) newest = Math.max(newest, fs.statSync(child).mtimeMs)
  } catch {}
  return newest
}

function* walk(dir: string): Generator<string> {
  let entries: fs.Dirent[]
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true })
  } catch {
    return
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) yield* walk(full)
    else yield full
  }
}

/** bindings touch + stale pruning at startup, mirroring the Claude hook */
export async function recordStartup(sessionID: string): Promise<{ bindings: number; topics: string[] }> {
  const binding = path.join(BY_SESSION, sessionID)
  if (fileExists(binding)) {
    try {
      const stamp = new Date()
      await fsp.utimes(binding, stamp, stamp)
    } catch {}
  }
  let removed = 0
  const cutoff = Date.now() - BINDING_MAX_AGE_DAYS * SECONDS_PER_DAY * 1000
  if (directoryExists(BY_SESSION)) {
    for (const name of fs.readdirSync(BY_SESSION)) {
      if (name.startsWith(".")) continue
      const file = path.join(BY_SESSION, name)
      try {
        const topic = (await fsp.readFile(file, "utf8")).trim()
        const dangling = !topic || !fileExists(path.join(ROOT, topic, PLAN_FILENAME))
        if (dangling || fs.statSync(file).mtimeMs < cutoff) {
          await fsp.unlink(file)
          removed++
        }
      } catch {
        continue
      }
    }
  }
  const prunedTopics = await pruneTopics()
  return { bindings: removed, topics: prunedTopics }
}

export async function pruneTopics(): Promise<string[]> {
  const removed: string[] = []
  if (!directoryExists(ROOT)) return removed
  const bound = new Set<string>()
  if (directoryExists(BY_SESSION)) {
    for (const name of fs.readdirSync(BY_SESSION)) {
      if (name.startsWith(".")) continue
      try {
        bound.add((await fsp.readFile(path.join(BY_SESSION, name), "utf8")).trim())
      } catch {
        continue
      }
    }
  }
  const topicCutoff = Date.now() - TOPIC_MAX_AGE_DAYS * SECONDS_PER_DAY * 1000
  for (const name of fs.readdirSync(ROOT)) {
    const entry = path.join(ROOT, name)
    if (!isTopicDir(entry) || bound.has(name)) continue
    if (newestMtime(entry) >= topicCutoff) continue
    try {
      fs.rmSync(entry, { recursive: true, force: true })
      removed.push(name)
    } catch {}
  }
  return removed
}

function directoryExists(dir: string): boolean {
  try {
    return fs.statSync(dir).isDirectory()
  } catch {
    return false
  }
}

export function listTopics(): { name: string; mtime: number; summary: string }[] {
  if (!directoryExists(ROOT)) return []
  const rows: { name: string; mtime: number; summary: string }[] = []
  for (const name of fs.readdirSync(ROOT)) {
    const entry = path.join(ROOT, name)
    if (!isTopicDir(entry)) continue
    const plan = path.join(entry, PLAN_FILENAME)
    let mtime = 0
    let summary = "(no plan.md)"
    try {
      mtime = fs.statSync(plan).mtimeMs
      summary = summarize(plan)
    } catch {}
    rows.push({ name, mtime, summary })
  }
  return rows
}

const TOPIC_SUMMARY_MAX_CHARS = 60

export function summarize(plan: string): string {
  try {
    for (const line of fs.readFileSync(plan, "utf8").split("\n")) {
      const text = line.replace(/^#+\s*/, "").replace(/#+\s*/, "").trim()
      if (!text) continue
      return text.length <= TOPIC_SUMMARY_MAX_CHARS ? text : text.slice(0, TOPIC_SUMMARY_MAX_CHARS - 1) + "…"
    }
  } catch {
    return "(unreadable)"
  }
  return "(empty)"
}

/* ---------- read gate ---------- */

function gatePath(sessionID: string): string {
  return path.join(GATES, `${sessionID}.json`)
}

export async function armGate(sessionID: string, plan: string, source: string, tail: string | null): Promise<void> {
  const payload: Gate = {
    plan,
    plan_digest: digest(plan),
    tail,
    source,
    armed_at: Date.now(),
    denials: 0,
  }
  await writeAtomically(gatePath(sessionID), Buffer.from(JSON.stringify(payload)))
}

export async function disarmGate(sessionID: string): Promise<void> {
  try {
    await fsp.unlink(gatePath(sessionID))
  } catch {}
}

export function loadGate(sessionID: string): Gate | null {
  try {
    return JSON.parse(fs.readFileSync(gatePath(sessionID), "utf8")) as Gate
  } catch {
    return null
  }
}

/* ---------- remembered instruction digests ---------- */

function statePath(sessionID: string): string {
  return path.join(STATE, `${sessionID}.json`)
}

type SessionState = {
  instructions_digest?: string
  seen?: boolean
  seen_at?: number
}

export async function readSessionState(sessionID: string): Promise<SessionState> {
  return (await readJson<SessionState>(statePath(sessionID))) ?? {}
}

export async function seenBefore(sessionID: string): Promise<boolean> {
  return Boolean((await readSessionState(sessionID)).seen)
}

export async function markSeen(sessionID: string): Promise<void> {
  const state = await readSessionState(sessionID)
  state.seen = true
  state.seen_at = Date.now()
  await writeAtomically(statePath(sessionID), Buffer.from(JSON.stringify(state)))
}

export async function rememberInstructions(sessionID: string, current: string): Promise<string | null> {
  const state = await readSessionState(sessionID)
  const previous = state.instructions_digest ?? null
  state.instructions_digest = current
  await writeAtomically(statePath(sessionID), Buffer.from(JSON.stringify(state)))
  return previous
}

/* ---------- guides ---------- */

export type Guide = {
  name: string
  readme: string
  description: string
  paths: string[]
}

function parseFrontMatter(text: string): Record<string, string | string[]> {
  const lines = text.split(/\r?\n/)
  if (!lines.length || lines[0].trim() !== FRONT_MATTER_FENCE) return {}
  const fields: Record<string, string | string[]> = {}
  let key: string | null = null
  for (const line of lines.slice(1)) {
    const stripped = line.split(" #", 1)[0].trim()
    if (stripped === FRONT_MATTER_FENCE) return fields
    if (stripped.startsWith("- ") && key) {
      const items = (fields[key] = Array.isArray(fields[key]) ? (fields[key] as string[]) : [])
      items.push(stripped.slice(2).trim())
    } else if (stripped.includes(":")) {
      const [rawKey, ...rest] = stripped.split(":")
      const value = rest.join(":").trim()
      key = rawKey.trim()
      if (value) fields[key] = value
    }
  }
  return {}
}

function loadGuide(directory: string): Guide | null {
  const readme = path.join(directory, GUIDE_README_FILENAME)
  let text: string
  try {
    text = fs.readFileSync(readme, "utf8")
  } catch {
    return null
  }
  const fields = parseFrontMatter(text)
  const description = fields["description"]
  const paths = fields["paths"]
  return {
    name: path.basename(directory),
    readme,
    description: typeof description === "string" ? description : "",
    paths: Array.isArray(paths) ? paths.map((p) => (p.startsWith("~") ? path.join(HOME, p.slice(1)) : p)) : [],
  }
}

export function allGuides(): Guide[] {
  if (!directoryExists(GUIDES_ROOT)) return []
  const guides: Guide[] = []
  for (const name of fs.readdirSync(GUIDES_ROOT).sort()) {
    if (name.startsWith(".")) continue
    const guide = loadGuide(path.join(GUIDES_ROOT, name))
    if (guide) guides.push(guide)
  }
  return guides
}

export function attachedNames(topicDir: string): string[] {
  try {
    const lines = fs.readFileSync(path.join(topicDir, TOPIC_GUIDES_FILENAME), "utf8").split("\n")
    return lines.map((l) => l.trim()).filter((l) => l && !l.startsWith("#"))
  } catch {
    return []
  }
}

export function covers(guide: Guide, cwd: string): boolean {
  try {
    const resolved = fs.realpathSync.native(cwd)
    return guide.paths.some((p) => resolved.startsWith(fs.realpathSync.native(p) + path.sep))
  } catch {
    return false
  }
}

/* ---------- escalations ---------- */

const HEADER = /^\W*ESCALATE\W*:?\s*(.*)$/i
const ENTRY = /^\s*[-*\d.)]*\s*`?([^\s`:]+):(\d+)(?:-(\d+))?`?\s*[-:]*\s*(.*)$/
const NONE = /^\W*none\b/i

/** Escalations from a reader's final message; null when no ESCALATE block exists */
export function parseBlock(message: string): { path: string; start: number; end: number; reason: string }[] | null {
  const lines = message.split(/\r?\n/)
  for (let index = lines.length - 1; index >= 0; index--) {
    const header = HEADER.exec(lines[index])
    if (header) return entries(header[1] ?? "", lines.slice(index + 1))
  }
  return null
}

function entries(rest: string, following: string[]): { path: string; start: number; end: number; reason: string }[] {
  if (NONE.test(rest)) return []
  const found: { path: string; start: number; end: number; reason: string }[] = []
  for (const line of [rest, ...following]) {
    const match = ENTRY.exec(line)
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

export function resolvePath(raw: string, cwd: string): string {
  let candidate = raw.startsWith("~") ? path.join(HOME, raw.slice(1)) : raw
  if (!path.isAbsolute(candidate)) candidate = path.resolve(cwd || ".", candidate)
  try {
    return fs.realpathSync.native(candidate)
  } catch {
    return path.resolve(candidate)
  }
}

function escalationsPath(sessionID: string): string {
  return path.join(ESCALATIONS, `${sessionID}.json`)
}

export async function loadEscalations(sessionID: string): Promise<EscalationEntry[]> {
  return (await readJson<EscalationEntry[]>(escalationsPath(sessionID))) ?? []
}

export async function saveEscalations(sessionID: string, list: EscalationEntry[]): Promise<void> {
  if (!list.length) {
    try {
      await fsp.unlink(escalationsPath(sessionID))
    } catch {}
    return
  }
  await writeAtomically(escalationsPath(sessionID), Buffer.from(JSON.stringify(list)))
}

export async function pruneOldEscalations(): Promise<void> {
  if (!directoryExists(ESCALATIONS)) return
  const cutoff = Date.now() - STATE_MAX_AGE_S * 1000
  for (const name of fs.readdirSync(ESCALATIONS)) {
    if (!name.endsWith(".json")) continue
    const file = path.join(ESCALATIONS, name)
    try {
      if (fs.statSync(file).mtimeMs < cutoff) await fsp.unlink(file)
    } catch {}
  }
}

export function overlaps(entry: { start: number; end: number }, offset?: number, limit?: number): boolean {
  if (offset === undefined && limit === undefined) return true
  const first = offset ?? 1
  if (limit === undefined) return first <= entry.end
  return first <= entry.end && entry.start < first + limit
}

export function describeEntry(entry: EscalationEntry): string {
  return `${entry.path}:${entry.start}-${entry.end} (${entry.agent_type}): ${entry.reason}`
}

/* ---------- checkpoint tail ---------- */

const TAIL_MAX_BYTES = 32 * 1024

/** Serialize transcript messages to a bounded tail of complete JSONL records */
export function checkpointTail(messages: unknown[]): Buffer {
  const serialized = messages.map((message) => Buffer.from(JSON.stringify(message) + "\n"))
  const chunks: Buffer[] = []
  let total = 0
  for (let i = serialized.length - 1; i >= 0; i--) {
    const chunk = serialized[i]
    if (total + chunk.length > TAIL_MAX_BYTES) break
    chunks.unshift(chunk)
    total += chunk.length
  }
  return Buffer.concat(chunks)
}

/**
 * The digest line naming the global instruction files. The digest comparison is
 * what lets a session skip re-reading its own injected instructions.
 */
export async function instructionsLine(sessionID: string): Promise<string> {
  const digests = INSTRUCTION_FILES.map((file) => `${file.split(path.sep).slice(-2).join("/")}: ${digest(file)}`)
  const digestsSeen = new Set(INSTRUCTION_FILES.map((file) => digest(file)))
  const drift = digestsSeen.size > 1 ? "  DRIFT: the copies differ" : ""
  const current = digest(INSTRUCTION_FILES[0])
  const previous = await rememberInstructions(sessionID, current)
  const same = INSTRUCTION_FILES.every((file) => digest(file) === current)
  const verdict =
    previous !== null && previous !== current
      ? "CHANGED since this session started - re-read it"
      : "unchanged - already in your context, do not re-read"
  return (
    `GLOBAL INSTRUCTIONS: ${INSTRUCTION_FILES.join(" or ")} - whichever you are (blake2b ${digests.join("/")}), ` +
    `${same ? "copies agree" : "check drift"}${drift}, ${verdict}`
  )
}

export function joinList(items: string[], indent = "  "): string {
  return items.map((item) => `${indent}${item}`).join("\n")
}
