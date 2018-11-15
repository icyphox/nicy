import 
  nicypkg/functions,
  strformat

export
  functions

let
  magenta = "magenta"
  yellow = "yellow"
  cyan = "cyan"
  prompt = "› "
  nl = "\n"
  dirty = color("×", "red")
  clean = color("•", "green")

# the prompt
echo fmt"{nl}{virtualenv()}{color(tilde(getCwd()), cyan)}{color(gitBranch(), yellow)}{gitStatus(dirty, clean)}{nl}{color(prompt, magenta)}"
