# fish’s default prompt '~>'

import nicy, strformat

let
  prompt = color("> ", "green")
  tilde = tilde(getCwd())

echo fmt"{tilde}{prompt}"

