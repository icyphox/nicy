# pure by @sindresorhus (kinda)

import nicy, strformat

let
  prompt = color("❯ ", magenta)
  tilde = color(tilde(getCwd()), cyan)
  git = color(gitBranch() & gitStatus("*", ""), red)
  nl = "\n"

echo fmt"{nl}{tilde}{git}{nl}{prompt}"
