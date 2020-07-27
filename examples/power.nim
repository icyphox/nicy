# power by @xyb
import
  nicypkg/functions,
  strformat

let
  prompt = uidsymbol(root = color("#", fg = red, bg = white),
                     user = color("$", green))
  nl = "\n"
  cwd = color(tilde(getCwd()), cyan)

  ahead = color("⬆ ", yellow)
  behind = color("⬇ ", yellow)
  untracked = color("?", yellow)
  changed = color("✎", yellow)
  staged = color("✔ ", yellow)
  conflicted = color("✼", yellow)
  stash = color("⎘", yellow)

  gs = newGitStats()
  gitStatus = gs.status(ahead, behind, untracked, changed, staged,
    conflicted, stash)
  gitBranch = color(gs.branch(), yellow)
  git = gitBranch & gitStatus

# the prompt
echo fmt"{nl}{virtualenv()}{cwd}{git}{nl}{prompt} "
