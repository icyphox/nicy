import strformat, times, os, osproc, nicypkg/functions
export functions

when isMainModule:
  let
    prompt = returnCondition(ok = "👍", ng = "👎") & " "
    nl = "\n"
    gitBranch = color(gitBranch(), "yellow")
    cwd = color(tilde(getCwd()), "cyan")
    dirty = color("×", "red")
    clean = color("•", "green")
    git = gitBranch & gitStatus(dirty, clean)
    ni = execCmdEx("nim --version").output[21 .. 25]
    py = execCmdEx("python --version").output[7 .. ^4]
  echoc cstring(fmt"{user()}@x {virtualenv()}{cwd} {getClockStr()[0..^4]} Py{py} Nim{ni} {git}{nl}{prompt}")
