## nicystar — a starship-flavored prompt in nicy's bracket style.
##
## ┌─[🏠 ~/cwd][🌿 branch][🏷 tag][✘!?⇡⇣]
## └─❯   (bold green on success, bold red on failure)
##
## The tag segment appears only when HEAD sits exactly on a tag; the status
## bracket uses starship symbols (✘ conflicted, ! modified, + staged,
## ? untracked, $ stashed, ⇡n ahead, ⇣n behind).
##
## Usage: nicystar [exit_status]   (PROMPT_COMMAND passes $? in)

import
  nicypkg/functions,
  os,
  strformat,
  strutils

proc abbrev(c: string): string =
  ## One character, or two when the dir starts with a dot (".c").
  if c.len > 1 and c[0] == '.':
    c[0 .. 1]
  else:
    c[0 .. 0]

proc shortPath(path: string): string =
  ## Abbreviated path: intermediate dirs collapse to their first character,
  ## the last component stays full, home is always ~.
  ## ~/Documents/OneDrive/Coding/Nim/Programs/nicy -> ~/D/O/C/N/P/nicy
  let t = tilde(path)
  let parts = t.split('/')
  if parts.len <= 2:      # "/", "/tmp", "~/Documents" — nothing to shorten
    return t
  result = parts[0]      # "~" or "" (root)
  for i in 1 ..< parts.len - 1:
    result.add '/' & abbrev(parts[i])
  result.add '/' & parts[^1]

when isMainModule:
  let
    failed = paramCount() > 0 and paramStr(1) != "0"
    gs = newGitStats()
    tag = gitTag()

  var segs: seq[string]
  segs.add color("🏠 " & shortPath(getCurrentDir()) & " ", cyan, b = true)
  if gs.branchName.len > 0:
    segs.add color("🌿 " & gs.branchName, magenta, b = true)
  if tag.len > 0 and tag != gs.branchName:
    segs.add color("🏷 " & tag, yellow, b = true)

  var st: string
  if gs.conflicted > 0: st.add "✘"
  if gs.changed > 0: st.add "!"
  if gs.staged > 0: st.add "+"
  if gs.untracked > 0: st.add "?"
  if gs.stash > 0: st.add "$"
  if gs.ahead > 0: st.add fmt"⇡{gs.ahead}"
  if gs.behind > 0: st.add fmt"⇣{gs.behind}"
  if st.len > 0:
    segs.add color(st, red)

  var line1 = color("┌─[", blue)
  for i, seg in segs:
    if i > 0:
      line1.add color("][", blue)
    line1.add seg
  line1.add color("]", blue)

  let line2 = color("└─", blue) &
      (if failed: color("❯ ", red, b = true)
       else: color("❯ ", green, b = true))

  echo fmt"{line1}{'\n'}{line2}"
