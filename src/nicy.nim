import 
  nicy/functions,
  strformat

let
  magenta = "magenta"
  yellow = "yellow"
  cyan = "cyan"
  prompt = "> "
  nl = "\n"
echo fmt"{nl}{virtualenv()}{color(tilde(getCwd()), cyan)}{color(gitBranch(), yellow)}{nl}{color(prompt, magenta)}"
