import strutils

# thanks to @jabbalaci for these
proc lchop*(s, sub: string): string =
  ## Remove ``sub`` from the beginning of ``s``.
  if s.startsWith(sub):
    s[sub.len .. s.high]
  else:
    s

proc rchop*(s, sub: string): string =
  ## Remove ``sub`` from the end of ``s``.
  if s.endsWith(sub):
    s[0 ..< ^sub.len]
  else:
    s
