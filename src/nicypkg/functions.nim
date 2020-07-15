import
  os,
  osproc,
  strformat,
  strutils,
  posix,
  terminal

type
  Color* = enum
    none = "",
    black = "\x1b[30m",
    red = "\x1b[31m",
    green = "\x1b[32m",
    yellow = "\x1b[33m",
    blue = "\x1b[34m",
    magenta = "\x1b[35m",
    cyan = "\x1b[36m",
    white = "\x1b[37m",

func zeroWidth*(s: string): string = 
  result = fmt"%{{{s}%}}"

func foreground*(s: string, color: Color): string =
  result = fmt"{zeroWidth($color)}{s}"

func background*(s: string, color: Color): string =
  result = fmt"{zeroWidth($color)}{s}"

func bold*(s: string): string = 
  const b = "\x1b[1m"
  result = fmt"{zeroWidth(b)}{s}"

func underline*(s: string): string = 
  const u = "\x1b[4m"
  result = fmt"{zeroWidth(u)}{s}"

func italics*(s: string): string = 
  const i = "\x1b[3m"
  result = fmt"{zeroWidth(i)}{s}"

func reverse*(s: string): string = 
  const rev = "\x1b[7m"
  result = fmt"{zeroWidth(rev)}{s}"

func reset*(s: string): string = 
  const res = "\x1b[0m"
  result = fmt"{s}{zeroWidth(res)}"

func color*(s: string, fg, bg = Color.none, b, u, r = false): string =
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

func returnCondition*(ok: string, ng: string, delimiter = "."): string = 
  result = fmt"%(?{delimiter}{ok}{delimiter}{ng})"

func returnCondition*(ok: proc(): string, ng: proc(): string, delimiter = "."): string =
  result = returnCondition(ok(), ng(), delimiter)