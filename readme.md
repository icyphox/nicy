<h1 align="center">                                                              
    <img src="https://x.ph0x.me/5DyAD.png" width="280">                            
</h1>

> A nice and icy ZSH prompt in Nim

![scrot](https://x.ph0x.me/SltdI.png)

## Installation
```console
nimble install https://github.com/icyphox/nicy
```

## Usage
Add this to your `~/.zshrc`. If you installed via `nimble`, set `PROMPT` to `$(~/.nimble/bin/nicy)`.

```zsh
_nicy_prompt() {
	PROMPT=$("/path/to/nicy")
}
precmd_functions+=_nicy_prompt
_nicy_prompt
```
Make sure you disable all other themes.

## Configuration
At the moment, you’re going to have to modify `src/nicy.nim` to build your prompt using the available procs listed below.

#### `zeroWidth(s: string): string`
Returns the given string wrapped in zsh zero-width codes. Useful for prompt alignment and cursor positioning.  
All procs below return strings wrapped by this.

#### `foreground(s, color: string): string`
Returns the given string, colorized.  
Possible colors are `"black"`, `"red"`, `"green"` `"blue"`, `"cyan"`, `"yellow"`, `"magenta"`, `"white"`.

#### `background(s, color: string): string`
Returns the given string with its background colorized.  
Same possible colors as above.

#### `bold(s: string): string`
Makes the given string bold.

#### `underline(s: string): string`
Adds an underline to the given string.

#### reverse(s: string): string
Swaps the foreground/background colors for the given string.

#### `reset(s: string): string`
Resets all attributes. Useful to disable all styling.

#### `color(s: string, fg: string = "", bg: string = "",  b: bool = false, u: bool = false, r = false): string`
Convenience proc that sets all attributes to a given string.  
`fg`: foreground, `bg`: background, `b`: bold, `u`: underline, `r`: reverse

#### `horizontalRule(c: char): string`
Returns a string of characters `c`, having the length of the current terminal width. Useful for positioning right-side prompts.

#### `tilde(path: string): string`
If `path` starts with `/home/user`, it is replaced by a `~/`.

#### `getCwd(): string`
Returns the full path of the current working directory, or returns the string `[not found]` if current path doesn't exist. (eg: `rm -rf ../curpath`)

#### `virtualenv(): string`
Returns the current virtualenv name if in one.

#### `gitBranch(): string`
Returns the current git branch, if in a git directory.

#### `gitStatus(dirty, clean: string): string`
Returns either `dirty` or `clean` if in a git repository. For example, return `•` if clean and `×` if dirty.

#### `user(): string`
Returns the current username.

#### `host(): string`
Returns the current hostname.

## License
MIT © Anirudh Oppiliappan
