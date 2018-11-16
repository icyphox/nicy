import 
  os,
  osproc,
  strformat,
  tables,
  strutils,
  terminal

proc zeroWidth*(s: string): string =
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

proc bold*(s: string): string =
  const b = "\x1b[1m"
  return fmt"{zeroWidth(b)}{s}"

proc underline*(s: string): string =
  const u = "\x1b[4m"
  return fmt"{zeroWidth(u)}{s}"

proc italics*(s: string): string =
  const i = "\x1b[3m"
  return fmt"{zeroWidth(i)}{s}"

proc reverse*(s: string): string =
  const rev = "\x1b[7m"
  return fmt"{zeroWidth(rev)}{s}"

proc reset*(s: string): string =
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
  let width = terminalWidth()
  for i in countup(1, width):
    result &= c
  result &= zeroWidth("\n")

proc tilde*(path: string): string =
  let home = getHomeDir()
  if path.startsWith(home):
    result = path.replace(home, "~/")
  else:
    result = path

proc getCwd*(): string =
  try:
    result = getCurrentDir() & " "
  except OSError:
    result = "[not found]"

proc virtualenv*(): string =
  let env = getEnv("VIRTUAL_ENV")
  result = extractFilename(env)
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

proc user*(): string =
  result = getEnv("USER")

proc host*(): string =
  # result = getEnv("HOST")
  # FIXME: this doesn't work oddly, will have to revert to the `hostname` command
 let (o, err) = execCmdEx("hostname")
 discard err
 result = o
