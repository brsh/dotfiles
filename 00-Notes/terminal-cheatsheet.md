# Terminal Cheat Sheet — Kitty & tmux

> **Local workflow:** Use **Kitty** for all tabs, windows/panes, and scrollback.  
> **Remote workflow:** Use **tmux** for session persistence, panes, and layouts over SSH.

---

## Kitty

> `kitty_mod` = **`ctrl+shift`**  
> Selecting text **auto-copies** to clipboard (`copy_on_select yes`).

### Tabs *(primary local navigation)*

| Key | Action |
|-----|--------|
| `ctrl+shift+t` | New tab |
| `ctrl+shift+q` | Close tab |
| `ctrl+shift+→` or `ctrl+tab` | Next tab |
| `ctrl+shift+←` or `ctrl+shift+tab` | Previous tab |
| `ctrl+alt+1`–`9` | Jump to tab 1–9 |
| `ctrl+shift+.` | Move tab forward |
| `ctrl+shift+,` | Move tab backward |
| `ctrl+shift+alt+t` | Rename tab |

### Windows / Panes *(local splits)*

| Key | Action |
|-----|--------|
| `ctrl+shift+enter` | New window (split — uses current layout) |
| `ctrl+shift+w` | Close window |
| `ctrl+shift+]` | Focus next window |
| `ctrl+shift+[` | Focus previous window |
| `ctrl+shift+f7` | Visual window picker (overlay labels) |
| `ctrl+shift+f8` | Visual window swap |
| `ctrl+shift+r` | Start interactive window resize |
| `ctrl+shift+1`–`9` | Focus window by number |

### Layouts

| Key | Action |
|-----|--------|
| `ctrl+shift+l` | Cycle to next layout |
| `ctrl+alt+s` | Toggle **stack** layout (zoom current window, un-zoom to return) |

### OS Windows

| Key | Action |
|-----|--------|
| `ctrl+shift+n` | New OS window |

### Scrollback

| Key | Action |
|-----|--------|
| `ctrl+shift+↑` | Scroll line up |
| `ctrl+shift+↓` | Scroll line down |
| `shift+page_up` | Scroll page up |
| `shift+page_down` | Scroll page down |
| `ctrl+page_up` | Jump to top of scrollback |
| `ctrl+page_down` | Jump to bottom (latest output) |
| `ctrl+shift+h` | Open full scrollback in pager (`less`) |

### Clipboard

| Key | Action |
|-----|--------|
| `ctrl+c` | Copy selection **or** send interrupt (if no selection) |
| `ctrl+v` | Paste from clipboard |
| `ctrl+shift+c` | Copy to clipboard (default, also active) |
| `ctrl+shift+v` | Paste from clipboard (default, also active) |

> **Note:** Selecting text automatically copies it to the clipboard.

### Text / Line Navigation

| Key | Action |
|-----|--------|
| `home` or `cmd+left` | Jump to beginning of line |
| `end` or `cmd+right` | Jump to end of line |
| `ctrl+left` | Jump to previous word (Alt-b) |
| `ctrl+right` | Jump to next word (Alt-f) |
| `opt+backspace` | Delete previous word |

### Font Size

| Key | Action |
|-----|--------|
| `ctrl+shift+=` | Increase font size (current window) |
| `ctrl+shift+-` | Decrease font size (current window) |

### Miscellaneous

| Key | Action |
|-----|--------|
| `ctrl+shift+cmd+p` | Command palette |
| `ctrl+shift+f3` | Command palette (default) |
| `ctrl+shift+f1` | Kitty docs overview |
| `ctrl+shift+f2` | Edit `kitty.conf` |
| `ctrl+shift+f5` | Reload `kitty.conf` |
| `ctrl+shift+delete` | Reset terminal |
| `ctrl+shift+escape` | Open kitty shell (remote control) |
| `ctrl+shift+u` | Unicode character input |
| `ctrl+shift+f11` | Toggle fullscreen |
| `ctrl+shift+e` | Open visible URL with hints kitten |

---

### Kittens *(run as commands, no keybinding required)*

| Command | What it does |
|---------|-------------|
| `kitten icat <image>` | Display an image inline in the terminal |
| `kitten diff <file1> <file2>` | Side-by-side visual diff with syntax highlighting |
| `kitten ssh <host>` | SSH with full kitty feature support (images, clipboard, etc.) |
| `kitten themes` | Interactive theme picker |
| `kitten choose-fonts` | Interactive font picker with live preview |
| `kitten hints` | Interactive text/URL/path selector from current screen |
| `kitten broadcast` | Type simultaneously into multiple windows |
| `kitten transfer <file>` | Transfer files over SSH using the terminal |
| `kitten clipboard` | Read/write clipboard from scripts |
| `kitten unicode_input` | Insert a Unicode character by name or codepoint |
| `kitten show-key` | Show key escape codes (useful for debugging bindings) |

---

---

## tmux *(remote sessions)*

> **Prefix:** `ctrl+a`  
> All `prefix X` bindings mean: press `ctrl+a`, release, then press `X`.  
> **Mouse is off by default.** Toggle with `prefix m`.

### Sessions

| Key | Action |
|-----|--------|
| `prefix d` | Detach from session |
| `prefix s` | Choose/switch session (tree view) |
| `prefix $` | Rename current session |
| `prefix (` | Switch to previous session |
| `prefix )` | Switch to next session |
| `tmux new -s <name>` | Create named session (from shell) |
| `tmux attach -t <name>` | Attach to named session (from shell) |
| `tmux ls` | List sessions (from shell) |
| `prefix m` | Toggle mouse on/off |

### Windows

| Key | Action |
|-----|--------|
| `prefix c` | New window |
| `prefix n` | Next window |
| `prefix p` | Previous window |
| `prefix l` | Last active window |
| `prefix 1`–`9` | Go to window by number |
| `prefix ,` | Rename window |
| `prefix &` | Kill window (with confirmation) |
| `prefix w` | Window/session tree picker |
| `prefix f` | Find window by name |
| `prefix .` | Move window (renumber/reassign) |

### Panes

| Key | Action |
|-----|--------|
| `prefix \|` | Split pane horizontally (new pane to the right) |
| `prefix -` | Split pane vertically (new pane below) |
| `alt+←/→/↑/↓` | Move focus between panes (**no prefix**) |
| `prefix o` | Cycle to next pane |
| `prefix ;` | Toggle to last active pane |
| `prefix q` | Flash pane numbers (press number to jump) |
| `prefix z` | Zoom/unzoom current pane (toggle fullscreen) |
| `prefix x` | Kill current pane |
| `prefix {` | Swap pane with the one above/left |
| `prefix }` | Swap pane with the one below/right |
| `prefix !` | Break pane out into its own window |

### Pane Resizing

| Key | Action |
|-----|--------|
| `prefix H` | Resize pane left 5 cells (repeatable) |
| `prefix J` | Resize pane down 5 cells (repeatable) |
| `prefix K` | Resize pane up 5 cells (repeatable) |
| `prefix L` | Resize pane right 5 cells (repeatable) |
| `alt+shift+←/→/↑/↓` | Resize pane 5 cells (**no prefix**) |

### Layouts

| Key | Action |
|-----|--------|
| `prefix space` | Cycle through preset layouts |

Preset layouts: `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`, `tiled`

### Copy Mode *(scrollback + selection)*

| Key | Action |
|-----|--------|
| `prefix [` | Enter copy mode |
| `q` or `Esc` | Exit copy mode |
| `↑/↓` or `k/j` | Scroll line by line |
| `page_up / page_down` | Scroll by page |
| `g` | Go to top |
| `G` | Go to bottom |
| `Space` | Start selection |
| `Enter` | Copy selection and exit |
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next / previous match |
| `prefix ]` | Paste most recent buffer |

### Miscellaneous

| Key | Action |
|-----|--------|
| `prefix r` | Reload `tmux.conf` |
| `prefix :` | Open tmux command prompt |
| `prefix ?` | List all key bindings |
| `prefix t` | Show clock |
| `prefix ~` | Show message log |
| `prefix ctrl+a` | Send prefix key to a nested session |
