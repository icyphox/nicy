<h1 align="center">                                                              
    <img src="https://x.ph0x.me/5DyAD.png" width="280">                            
</h1>

> A nice and icy ZSH prompt in Nim

![scrot](https://x.ph0x.me/SltdI.png)

## Installation
```console
$ nimble install nicy
```

## Quick start
Add this to your `~/.zshrc`. If you installed via `nimble`, set `PROMPT` to `$(~/.nimble/bin/nicy)`.

```zsh
_nicy_prompt() {
	PROMPT=$("/path/to/nicy")
}
precmd_functions+=_nicy_prompt
_nicy_prompt
```
Make sure you disable all other themes.

### Configuration
If you want to configure `nicy` just as it is, you’ll have to edit `src/nicy.nim` file. 

### Build your own prompt
Alternatively, you can just as easily write your own prompt in Nim using `nicy`’s built in API. Refer to the [Examples](#Examples) section for some insight.

Once you’re done, compile it and add a similar function to your `.zshrc` as above, replacing `PROMPT` with the path to your own binary.

### Examples

```nim
# ‘user@host $’ prompt

import nicy, strformat

let
  user = color(user(), "green")
  host = color(host(), "red")
  prompt = color("$ ", "cyan")
  at = color("@", "yellow")

echo fmt"{user}{at}{host} {prompt}"
```

```nim
# fish’s default prompt '~>'

import nicy, strformat

let
  prompt = color("> ", "green")
  tilde = tilde(getCwd())

echo fmt"{tilde}{prompt}"
```

```nim
# pure by @sindresorhus (kinda)

import nicy, strformat

let
  prompt = color("❯ ", "magenta")
  tilde = color(tilde(getCwd()), "cyan")
  git = color(gitBranch() & gitStatus("*", ""), "black")
  nl = "\n"

echo fmt"{tilde}{git}{nl}{prompt}"
```

### API

**`zeroWidth(s: string): string`**  
Returns the given string wrapped in zsh zero-width codes. Useful for prompt alignment and cursor positioning.  
All procs below return strings wrapped by this.

**`foreground(s, color: string): string`**  
Returns the given string, colorized.  
Possible colors are `"black"`, `"red"`, `"green"` `"blue"`, `"cyan"`, `"yellow"`, `"magenta"`, `"white"`.

**`background(s, color: string): string`**  
Returns the given string with its background colorized.  
Same possible colors as above.

**`bold(s: string): string`**  
Makes the given string bold.

**`underline(s: string): string`**  
Adds an underline to the given string.

**`reverse(s: string): string`**  
Swaps the foreground/background colors for the given string.

**`reset(s: string): string`**  
Resets all attributes. Useful to disable all styling.

**`color(s: string, fg: string = "", bg: string = "",  b: bool = false, u: bool = false, r = false): string`**  
Convenience proc that sets all attributes to a given string.  
`fg`: foreground, `bg`: background, `b`: bold, `u`: underline, `r`: reverse

**`horizontalRule(c: char): string`**  
Returns a string of characters `c`, having the length of the current terminal width. Useful for positioning right-side prompts.

**`tilde(path: string): string`**  
If `path` starts with `/home/user`, it is replaced by a `~/`.

**`getCwd(): string`**  
Returns the full path of the current working directory, or returns the string `[not found]` if current path doesn’t exist. (eg: `rm -rf ../curpath`)

**`virtualenv(): string`**  
Returns the current virtualenv name if in one.

**`gitBranch(): string`**  
Returns the current git branch, if in a git directory.

**`gitStatus(dirty, clean: string): string`**  
Returns either `dirty` or `clean` if in a git repository. For example, return `•` if clean and `×` if dirty.

**`user(): string`**  
Returns the current username.

**`host(): string`**  
Returns the current hostname.

## Contributing
Bad code? New feature in mind? Open an issue. Better still, learn [Nim](https://nim-lang.org/documentation.html) and shoot a PR :sparkles:

## License
MIT © Anirudh Oppiliappan
