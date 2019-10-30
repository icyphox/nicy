import
  os,
  osproc,
  strformat,
  tables,
  strutils,
  posix,
  terminal

func zeroWidth*(s: string): string {.inline.} =
  return fmt"%{{{s}%}}"

proc foreground*(s, color: string): string =
  const colors = {
    "black":"\x1b[30m",
    "red": "\x1b[31m",
    "green": "\x1b[32m",
    "yellow": "\x1b[33m",
    "blue": "\x1b[34m",
    "magenta": "\x1b[35m",
    "cyan": "\x1b[36m",
    "white": "\x1b[37m",
  }.toTable
  return fmt"{zeroWidth(colors[color])}{s}"

proc background*(s, color: string): string =
  const colors = {
    "black":"\x1b[40m",
    "red": "\x1b[41m",
    "green": "\x1b[42m",
    "yellow": "\x1b[43m",
    "blue": "\x1b[44m",
    "magenta": "\x1b[45m",
    "cyan": "\x1b[46m",
    "white": "\x1b[47m",
  }.toTable
  return fmt"{zeroWidth(colors[color])}{s}"

func bold*(s: string): string {.inline.} =
  const b = "\x1b[1m"
  return fmt"{zeroWidth(b)}{s}"

func underline*(s: string): string {.inline.} =
  const u = "\x1b[4m"
  return fmt"{zeroWidth(u)}{s}"

func italics*(s: string): string {.inline.} =
  const i = "\x1b[3m"
  return fmt"{zeroWidth(i)}{s}"

func reverse*(s: string): string {.inline.} =
  const rev = "\x1b[7m"
  return fmt"{zeroWidth(rev)}{s}"

func reset*(s: string): string {.inline.} =
  const res = "\x1b[0m"
  return fmt"{s}{zeroWidth(res)}"

proc color*(s: string, fg: string = "", bg: string = "",
  b: bool = false, u: bool = false, r = false): string =
  result = s
  if s.len == 0:
    return s
  if fg.len != 0:
    result = foreground(result, fg)
  if bg.len != 0:
    result = background(result, bg)
  if b:
    result = bold(result)
  if u:
    result = underline(result)
  if r:
    result = reverse(result)
  result = reset(result)

proc horizontalRule*(c: char = '-'): string =
  for _ in 1 || terminalWidth(): # Parallel for loop, unordered iter but faster.
    result &= c
  result &= zeroWidth("\n")

proc tilde*(path: string): string =
  # donated by @misterbianco
  let home = getHomeDir()
  if path.startsWith(home):
    result = "~/" & path.split(home)[1]
  else:
    result = path

template getCwd*(): string =
  try: getCurrentDir() & " " except OSError: "[not found]"

proc virtualenv*(): string =
  let env = getEnv("VIRTUAL_ENV")
  result = extractFilename(env) & " "
  if env.len == 0:
    result = ""

proc gitBranch*(): string =
  let (o, err) = execCmdEx("git status")
  if err == 0:
    let firstLine = o.split("\n")[0].split(" ")
    result = firstLine[firstLine.len - 1] & " "
  else:
    result = ""

proc gitStatus*(dirty, clean: string): string =
  let (o, err) = execCmdEx("git status --porcelain")
  if err == 0:
    if o.len != 0:
      result = dirty
    else:
      result = clean
  else:
    result = ""

template user*(): string =
  $getpwuid(getuid()).pw_name

proc host*(): string {.inline.} =
  const size = 64
  var s = cstring(newString(size))
  result = $s.gethostname(size)

template uidsymbol*(root, user: string): string =
  if unlikely(getuid() == 0): root else: user

func returnCondition*(ok: string, ng: string, delimiter = "."): string {.inline.} =
  result = fmt"%(?{delimiter}{ok}{delimiter}{ng})"

template returnCondition*(ok: proc(): string, ng: proc(): string, delimiter = "."): string =
  returnCondition(ok = ok(), ng = ng(), delimiter = delimiter)

func echoc*(s: cstring) {.importc: "printf", header: "<stdio.h>".} ## Fast pure C echo,uses cstring.
