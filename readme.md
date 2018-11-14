<h1 align="center">                                                              
    <img src="https://x.ph0x.me/5DyAD.png" width="280">                            
</h1>                                                                                   

> A nice and icy ZSH prompt in Nim

![scrot](https://x.ph0x.me/SltdI.png)

## Installation
`nimble install https://github.com/icyphox/nicy`

## Usage
Add this to your `~/.zshrc`. If you installed via `nimble`, set `PROMPT` to `~/.nimble/bin/nicy`.

```zsh
_nicy_prompt() {
	PROMPT=$("/path/to/nicy")
}
precmd_functions+=_nicy_prompt
_nicy_prompt
```
Make sure you disable all other themes.

## Configuration
At the moment, you're going to have to modify `src/nicy.nim` to build your prompt.

## TODO
- [x] git clean/dirty state
- [ ] text based config
