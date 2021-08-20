import
  nre,
  os,
  osproc,
  posix,
  strformat,
  strutils,
  tables,
  terminal

type
  Color* = enum
    none = -1
    black = 0
    red = 1
    green = 2
    yellow = 3
    blue = 4
    magenta = 5
    cyan = 6
    white = 7

  GitStats* = object
    branchName*: string
    detached*: bool
    localRef*: string
    remoteRef*: string
    ahead*: int
    behind*: int
    untracked*: int
    conflicted*: int
    changed*: int
    staged*: int
    stash*: int

when defined(bash): # shell switch during compilation using "-d:bash"
  proc isBash(): bool =
    result = true
elif defined(zsh): # or "-d:zsh"
  proc isBash(): bool =
    result = false
else: # or detect shell automatic
  proc isBash(): bool =
    result = false
    let ppid = getppid()
    let (o, err) = execCmdEx(fmt"ps -p {ppid} -oargs=")
    if err == 0:
      let name = o.strip()
      if name.endswith("bash"):
        result = true

let
  shellName* = # make sure the shell detection runs once only
    if isBash():
      "bash"
    else:
      "zsh"    # default

proc zeroWidth*(s: string): string =
  return s
  #if shellName == "bash":
  #  return fmt"\[{s}\]"
  #else:
  #  # zsh, default
  #  return fmt"%{{{s}%}}"

proc foreground*(s: string, color: Color): string =
  let c = "\x1b[" & $(ord(color)+30) & "m"
  result = fmt"{zeroWidth($c)}{s}"

proc background*(s: string, color: Color): string =
  let c = "\x1b[" & $(ord(color)+40) & "m"
  result = fmt"{zeroWidth($c)}{s}"

proc bold*(s: string): string =
  const b = "\x1b[1m"
  result = fmt"{zeroWidth(b)}{s}"

proc underline*(s: string): string =
  const u = "\x1b[4m"
  result = fmt"{zeroWidth(u)}{s}"

proc italics*(s: string): string =
  const i = "\x1b[3m"
  result = fmt"{zeroWidth(i)}{s}"

proc reverse*(s: string): string =
  const rev = "\x1b[7m"
  result = fmt"{zeroWidth(rev)}{s}"

proc reset*(s: string): string =
  const res = "\x1b[0m"
  result = fmt"{s}{zeroWidth(res)}"

proc color*(s: string, fg, bg = Color.none, b, u, r = false): string =
  if s.len == 0:
    return
  result = s
  if fg != Color.none:
    result = foreground(result, fg)
  if bg != Color.none:
    result = background(result, bg)
  if b:
    result = bold(result)
  if u:
    result = underline(result)
  if r:
    result = reverse(result)
  result = reset(result)

proc horizontalRule*(c = '-'): string =
  for _ in 1 .. terminalWidth():
    result &= c
  result &= zeroWidth("\n")

proc tilde*(path: string): string =
  # donated by @misterbianco
  let home = getHomeDir()
  if path.startsWith(home):
    result = "~/" & path.split(home)[1]
  else:
    result = path

proc getCwd*(): string =
  result = try:
    getCurrentDir() & " "
  except OSError:
    "[not found]"

proc virtualenv*(): string =
  let env = getEnv("VIRTUAL_ENV")
  result = extractFilename(env) & " "
  if env.len == 0:
    result = ""

proc gitBranch*(): string =
  let (o, err) = execCmdEx("git status")
  if err == 0:
    let firstLine = o.split("\n")[0].split(" ")
    result = firstLine[^1] & " "
  else:
    result = ""

proc gitStatus*(dirty, clean: string): string =
  let (o, err) = execCmdEx("git status --porcelain")
  result = if err == 0:
    if o.len != 0:
      dirty
    else:
      clean
  else:
    ""

proc user*(): string =
  result = $getpwuid(getuid()).pw_name

proc host*(): string =
  const size = 64
  result = newString(size)
  discard gethostname(cstring(result), size)

proc uidsymbol*(root, user: string): string =
  result = if getuid() == 0: root else: user

proc returnCondition*(ok: string, ng: string, delimiter = "."): string =
  result = fmt"%(?{delimiter}{ok}{delimiter}{ng})"

proc returnCondition*(ok: proc(): string, ng: proc(): string,
    delimiter = "."): string =
  result = returnCondition(ok(), ng(), delimiter)

proc getGitDetachedBranch(): string =
  let (o, err) = execCmdEx("git describe --tags --always")
  if err == 0:
    result = o.strip()

proc getStashCount(): int =
  let (o, err) = execCmdEx("git stash list")
  if err == 0:
    result = o.count("\n")

proc newGitStats*(): GitStats =
  let (o, err) = execCmdEx("git status --porcelain -b")
  if err == 0:
    let pattern = re"^## (?P<local>\S+?)(\.{3}(?P<remote>\S+?)( \[(ahead (?P<ahead>\d+)(, )?)?(behind (?P<behind>\d+))?\])?)?$"
    let lines = o.split("\n")

    let firstLine = lines[0]
    let matched = firstLine.match(pattern)
    if matched.isSome:
      let status = matched.get.captures.toTable
      result.localRef = status["local"]
      result.remoteRef = status.getOrDefault("remote", "")
      result.ahead = parseInt(status.getOrDefault("ahead", "0"))
      result.behind = parseInt(status.getOrDefault("behind", "0"))
      result.branchName = status["local"]
    else:
      result.branchName = getGitDetachedBranch()
      if result.branchName.len > 0:
        result.detached = true
      else:
        result.branchName = "Big Bang"
        result.detached = false

    for line in lines[1..^1]:
      if line.len < 2:
        continue
      let code = line[0..<2]
      if code == "??":
        result.untracked.inc
      elif code in @["DD", "AU", "UD", "UA", "DU", "AA", "UU"]:
        result.conflicted.inc
      else:
        if code[1] != ' ':
          result.changed.inc
        if code[0] != ' ':
          result.staged.inc
    result.stash = getStashCount()

proc dirty*(gs: GitStats): bool =
  (gs.untracked + gs.changed + gs.staged + gs.conflicted) > 1

proc branch*(gs: GitStats, detachedPrefix = "", postfix = " "): string =
  if gs.branchName.len > 0:
    result = gs.branchName & postfix
  if gs.detached and detachedPrefix.len > 0:
    result = detachedPrefix & result

proc status*(gs: GitStats, ahead, behind, untracked, changed, staged,
    conflicted, stash: string, separator, postfix = " "): string =
  var parts = newSeq[string]()

  template add(gs: GitStats, field: untyped, value: string, ss: seq[string]) =
    if gs.`field` > 0:
      if gs.`field` > 1:
        ss.add($gs.`field` & value)
      else:
        ss.add(value)

  if gs.branchName.len > 0:
    add(gs, ahead, ahead, parts)
    add(gs, behind, behind, parts)
    add(gs, untracked, untracked, parts)
    add(gs, changed, changed, parts)
    add(gs, staged, staged, parts)
    add(gs, conflicted, conflicted, parts)
    add(gs, stash, stash, parts)
    result = parts.join(separator)
    if result.len > 0 and postfix.len > 0:
      result &= postfix
