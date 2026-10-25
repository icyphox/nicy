import
  os,
  osproc,
  posix,
  strformat,
  strutils,
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

proc parentComm(): string =
  ## Name of the parent process' executable, e.g. "bash" or "zsh".
  ## Uses /proc when available (no subprocess), ps otherwise.
  when defined(linux):
    try:
      return readFile("/proc/" & $getppid() & "/comm").strip()
    except OSError, IOError:
      discard
  let (o, err) = execCmdEx("ps -p " & $getppid() & " -o comm=")
  if err == 0:
    return o.strip()
  ""

when defined(bash): # shell switch during compilation using "-d:bash"
  proc detectShell(): string =
    "bash"
elif defined(zsh): # or "-d:zsh"
  proc detectShell(): string =
    "zsh"
else: # or detect shell automatically
  proc detectShell(): string =
    # Match the executable name only, not its arguments: shells are often
    # launched as "bash -i" (tmux, terminal emulators, pty wrappers), which
    # the old args-based check missed, defaulting to zsh escapes.
    let name = parentComm()
    if name == "bash" or name.endsWith("/bash"):
      "bash"
    elif name == "zsh" or name.endsWith("/zsh"):
      "zsh"
    else:
      ""    # unknown: emit no zero-width wrappers at all

let
  shellName* = # make sure the shell detection runs once only
    detectShell()

proc zeroWidth*(s: string): string =
  ## Wrap `s` in the shell's zero-width escape so invisible sequences
  ## don't confuse the shell's prompt cursor math.
  case shellName
  of "bash":
    fmt"\[{s}\]"
  of "zsh":
    fmt"%{{{s}%}}"
  else:
    s

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
  let home = getHomeDir()          # trailing slash: "/home/luis/"
  if path == home[0 .. ^2]:
    result = "~"
  elif path.startsWith(home):
    result = "~/" & path[home.len .. ^1]
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

# ---------------------------------------------------------------------------
# Git — shells out to the `git` binary instead of linking libgit2. A single
# cached `git status --porcelain=v2 --branch` call per prompt provides the
# branch, upstream, ahead/behind and the status counts; `git describe` is
# only spawned for detached HEADs and exact tags, and the stash count is
# read straight from the stash reflog file.
# ---------------------------------------------------------------------------

var
  statusOut: string          # cached porcelain output, "" outside a repo
  statusFetched = false
  statsCache: GitStats
  statsParsed = false

proc gitStatusOut(): string =
  ## `git status --porcelain=v2 --branch` for the current directory,
  ## fetched once per prompt; empty outside a repository or without git.
  if not statusFetched:
    statusFetched = true
    try:
      # --no-optional-locks: a prompt must not fight the user's own git
      # commands over the index lock
      let (o, code) = execCmdEx(
          "git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null")
      if code == 0:
        statusOut = o
    except OSError:
      discard    # git not installed: same as being outside a repository
  statusOut

proc gitDescribe(args: string): string =
  ## Output of `git describe <args>`, stripped; "" when git refuses (e.g.
  ## HEAD is not on a tag with --exact-match).
  try:
    let (o, code) = execCmdEx("git describe " & args & " 2>/dev/null")
    if code == 0:
      result = o.strip()
  except OSError:
    discard

proc gitDirPath(): string =
  ## The .git directory of the repository containing the current
  ## directory, honoring GIT_DIR and ".git" pointer files (worktrees,
  ## submodules); "" when there is no repository.
  result = getEnv("GIT_DIR")
  if result.len > 0:
    return
  var dir = ""
  try:
    dir = getCurrentDir()
  except OSError:
    return
  while true:
    let candidate = dir / ".git"
    if dirExists(candidate):
      return candidate
    if fileExists(candidate):
      try:
        for line in readFile(candidate).splitLines():
          if line.startsWith("gitdir: "):
            let path = line[8..^1].strip()
            return if path.isAbsolute: path else: dir / path
      except OSError, IOError:
        discard
      return ""
    let parent = dir.parentDir()
    if parent.len == 0 or parent == dir:
      return ""
    dir = parent

proc stashCount(): int =
  ## Number of stashes: one reflog entry per stash on refs/stash, which is
  ## exactly what `git stash list` reads.
  let gitdir = gitDirPath()
  if gitdir.len == 0:
    return
  try:
    for line in readFile(gitdir / "logs" / "refs" / "stash").splitLines():
      if line.strip().len > 0:
        inc result
  except OSError, IOError:
    discard

proc parseStatus(outp: string): GitStats =
  ## Fill a GitStats from `git status --porcelain=v2 --branch` output.
  var head = ""
  var detached = false
  var unborn = false
  for line in outp.splitLines():
    if line.startsWith("# branch.oid "):
      if line.endsWith("(initial)"):
        unborn = true
    elif line.startsWith("# branch.head "):
      head = line[14..^1]
      if head == "(detached)":
        detached = true
        head = ""
    elif line.startsWith("# branch.upstream "):
      result.remoteRef = line[17..^1]
    elif line.startsWith("# branch.ab "):
      let f = line.splitWhitespace()
      if f.len == 4:
        try:
          result.ahead = parseInt(f[2][1..^1])
          result.behind = parseInt(f[3][1..^1])
        except ValueError:
          discard
    elif line.startsWith("1 ") or line.startsWith("2 "):
      let xy = line.splitWhitespace()[1]
      if xy.len == 2:
        if xy[0] notin {'.', ' '}: inc result.staged
        if xy[1] notin {'.', ' '}: inc result.changed
    elif line.startsWith("u "):
      inc result.conflicted
    elif line.startsWith("? "):
      inc result.untracked
  if detached:
    let described = gitDescribe("--tags --always")
    if described.len > 0:
      result.branchName = described
      result.detached = true
    else:
      result.branchName = "Big Bang"
  elif unborn:
    result.branchName = "Big Bang"   # unborn HEAD
  else:
    result.branchName = head
    result.localRef = head

proc gitStats(): GitStats =
  ## Parsed git status of the current directory, computed once per prompt.
  if not statsParsed:
    statsParsed = true
    let outp = gitStatusOut()
    if outp.len > 0:
      statsCache = parseStatus(outp)
      statsCache.stash = stashCount()
  statsCache

proc gitBranch*(): string =
  ## Name of the current branch (or the describe of a detached HEAD),
  ## with a trailing space; empty outside a repository.
  let gs = gitStats()
  if gs.branchName.len == 0 or (not gs.detached and gs.localRef.len == 0):
    return
  result = gs.branchName & " "

proc gitStatus*(dirty, clean: string): string =
  ## `dirty` if the worktree has any changes (including untracked files),
  ## else `clean`; empty outside a repository.
  if gitStatusOut().len == 0:
    return
  let gs = gitStats()
  result = if (gs.untracked + gs.changed + gs.staged +
      gs.conflicted) > 0: dirty else: clean

proc gitTag*(): string =
  ## The tag pointing exactly at HEAD; empty when HEAD is not on a tag
  ## or outside a repository.
  if gitStatusOut().len == 0:
    return
  result = gitDescribe("--tags --exact-match")

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

proc newGitStats*(): GitStats =
  ## All git stats for the prompt in a single pass.
  gitStats()

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
