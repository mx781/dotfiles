# Markdown math preview

In Neovim, put the cursor inside math in a Markdown file and press `gx`,
or run `:NFHMath`. Supports `$…$`, `$$…$$`, `\(…\)`, and `\[…\]`;
display math can span lines. Skips fenced code and inline code.
Existing image/URL handling applies when the cursor is outside math.
This is cursor-based, not a mouse-hover popup.

In terminal scrollback, enter terminal-normal mode (`Ctrl-\\ Ctrl-N`) and press
`gx` on delimited math. If there is no delimited expression under the cursor,
the current line is treated as raw TeX. In either a Markdown or terminal buffer,
visual-select an exact expression and press `gx` to render only the selection;
surrounding `$…$`, `$$…$$`, `\(…\)`, or `\[…\]` delimiters are removed.
Standalone `[` and `]` lines, as commonly emitted around display math in
terminal/LLM output, are also recognized; indentation is allowed.

Requires Neovim 0.10+, Node.js, npm, and feh. Install local dependencies:

```sh
npm ci --prefix ~/hub/dotfiles/scripts/math-preview
```

TeX is piped to local MathJax, converted from SVG to a white-background PNG
with sharp, and opened asynchronously in feh. Close feh to delete the temporary
PNG. Rendering has a 30-second timeout. No remote rendering service is used.
The delimiter scanner is intentionally lightweight, not a full Markdown parser.

From the repository root, verify extraction and rendering without opening a GUI:

```sh
nvim --headless -u NONE -i NONE -l scripts/math-preview/test.lua
```

The renderer can also be used directly with raw, undelimited TeX:

```sh
printf '%s' '\frac{a}{b}' | node scripts/math-preview/render.mjs /tmp/math.png
feh /tmp/math.png
```
