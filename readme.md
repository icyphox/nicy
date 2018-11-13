# nicy
> A nice and icy ZSH prompt in Nim

![scrot](https://x.ph0x.me/FRejk.png)

## Installation
`nimble install https://github.com/icyphox/nicy`

## Usage
Add this to your `~/.zshrc`

```zsh
_nicy_prompt() {
	PROMPT=$("/path/to/nicy")
}
precmd_functions+=_nicy_prompt
_nicy_prompt
```

Make sure you disable all your other themes. 

## Configuration
At the moment, you're going to have to modify `src/nicy.nim` to build your prompt.

## TODO
- git clean/dirty state
- text based config
