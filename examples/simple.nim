# ‘user@host $’ prompt

import nicy, strformat

let
  user = color(user(), green)
  host = color(host(), red)
  prompt = color("$ ", cyan)
  at = color("@", yellow)

echo fmt"{user}{at}{host} {prompt}"
