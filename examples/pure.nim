# pure by @sindresorhus (kinda)

import nicy, strformat

let
  prompt = color("❯ ", "magenta")
  tilde = color(tilde(getCwd()), "cyan")
  git = color(gitBranch() & gitStatus("*", ""), "black")
  nl = "\n"

echo fmt"{tilde}{git}{nl}{prompt}"

