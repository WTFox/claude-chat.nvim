# claude-chat.nvim

A Neovim plugin for seamless integration with Claude Code CLI.

This plugin provides a smooth wrapper around Claude Code, helping you formulate prompts and automatically sharing file context. At its core, it launches Claude with your current file, selection context, and custom prompts—all without modifying Claude's configuration. Any changes Claude makes to visible buffers are immediately reflected in Neovim.

Built for Claude Code enthusiasts, mostly built _with_ Claude itself! 🤖

**Contributing**: Pull requests and issues are very welcome! If you want a feature that's missing, please help build it out (see "The Dream" section below).

https://github.com/user-attachments/assets/a91b3a0d-03bc-4810-b83a-c629bcf8cd46

## ✨ Features

- **🎯 Smart Context Sharing**: Automatically passes current file path, filetype, and text selections to Claude
- **💬 Interactive Terminal**: Chat with Claude Code in a customizable split or floating window with keybinds. (<C-f> injects current buffer filename)
- **📝 Visual Selection Support**: Works seamlessly with text selections and visual ranges
- **⚙️ Flexible Configuration**: Configurable split positioning, sizing, and terminal behavior
- **👀 Live File Watching**: Real-time context updates as you work

## 📋 Requirements

- **Neovim**: Version 0.7 or higher
- **Claude Code CLI**: [Install from Claude](https://claude.com/product/claude-code) and ensure it's available in your PATH as `claude`

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Recommended (simple setup):**
```lua
{
  "wtfox/claude-chat.nvim",
  config = true,
}
```

**With custom options:**
```lua
{
  "wtfox/claude-chat.nvim",
  config = true,
  keys = {
    { "<leader>cc", ":ClaudeChat<CR>", mode = { "n", "v" }, desc = "Toggle Claude Chat" },
  },
  opts = {
    -- Optional configuration
    split = "vsplit",      -- "vsplit", "split", or "float"
    position = "right",    -- "right", "left", "top", "bottom" (ignored for float)
    width = 0.6,          -- percentage of screen width (for vsplit or float)
    height = 0.8,         -- percentage of screen height (for split or float)
    claude_cmd = "claude", -- command to invoke Claude Code
    float_opts = {        -- options for floating window
      relative = "editor",
      border = "rounded",
      title = " Claude Chat ",
      title_pos = "center",
    },
  },
}
```

### Other Plugin Managers

<details>
<summary>Click to expand</summary>

**vim-plug**:
```vim
Plug 'wtfox/claude-chat.nvim'
```

**packer.nvim**:
```lua
use 'wtfox/claude-chat.nvim'
```
</details>

## 🚀 Usage

### Quick Start

The plugin intelligently adapts based on your input, text selection, and current session state:

| Scenario | Behavior |
|----------|----------|
| 🔹 **No prompt + No selection + No session** | Opens plain Claude terminal |
| 🔸 **No prompt + Text selected + No session** | Sends selection with file context |
| 🔹 **With prompt + No selection** | Sends prompt with current file context |
| 🔸 **With prompt + Text selected** | Sends both prompt and selection context |
| ✨ **No prompt + Active session** | **Toggles chat window visibility** |

### Command Reference

| Command | Description |
|---------|-------------|
| `:ClaudeChat` | Interactive prompt or toggle if session active |
| `:ClaudeChat <prompt>` | Direct command without dialog |

### 🎹 Chat Terminal Keybindings

#### Normal Mode (after pressing `<Esc><Esc>`)
| Key | Action |
|-----|--------|
| `q` | Close the chat |
| `i` | Enter insert mode to type messages |
| `a` | Enter insert mode at end of line |

#### Terminal Mode (works anytime)
| Key | Action |
|-----|--------|
| `<C-q>` | Close or toggle window visibility |
| `<C-f>` | Insert current filename into input |
| `<C-c>` | Exit Claude Chat |
| `<Esc><Esc>` | Exit to normal mode |
| `<C-\><C-N>` | Alternative: Exit to normal mode |

### 💡 Usage Examples

<details>
<summary><strong>🗨️ General Chat</strong></summary>

```
<leader>cc → (leave input empty) → Opens plain Claude terminal
```
Perfect for general questions or when you want to start fresh.
</details>

<details>
<summary><strong>📄 Ask About Current File</strong></summary>

```
<leader>cc → "What does this file do?" → Sends question + file context
```
Claude gets your file path and can analyze the entire file.
</details>

<details>
<summary><strong>🎯 Ask About Selection Only</strong></summary>

```
1. Select some code
2. <leader>cc → (leave input empty) → Sends just the selection
```
Focus Claude's attention on specific code.
</details>

<details>
<summary><strong>🔍 Ask About Selection + Question</strong></summary>

```
1. Select some code
2. <leader>cc → "Optimize this" → Sends question + selection
```
Combine specific code with targeted questions.
</details>

<details>
<summary><strong>⚡ Direct Commands</strong></summary>

```
:ClaudeChat explain this bug
```
Skip the dialog and send commands directly.
</details>

<details>
<summary><strong>🔄 Toggle Window Visibility</strong></summary>

```
1. Start a Claude session: <leader>cc → "help me debug this"
2. Hide the window: <leader>cc → (no prompt, just press Enter)
3. Restore the window: <leader>cc → (no prompt, just press Enter)
```
Perfect for quickly hiding/showing Claude while preserving your conversation.
</details>

## ⚙️ Configuration

### 🌟 Recommended Configuration

```lua
{
  "wtfox/claude-chat.nvim",
  config = true,
  keys = {
    { "<leader>cc", ":ClaudeChat<CR>", mode = { "n", "v" }, desc = "Toggle Claude Chat" },
  },
}
```

No global keymap is set by default — use lazy's `keys` spec to define one. Use `:ClaudeChat` directly if you prefer no keymap.

### Full Configuration Options

Customize the plugin behavior with these options:

```lua
require('claude-chat').setup({
  split = "vsplit",      -- "vsplit" for vertical, "split" for horizontal, "float" for floating
  position = "right",    -- "right", "left", "top", "bottom" (ignored for float)
  width = 0.6,          -- percentage of screen width (for vsplit or float)
  height = 0.8,         -- percentage of screen height (for split or float)
  claude_cmd = "claude", -- command to invoke Claude Code CLI
  float_opts = {        -- options for floating window (only used when split = "float")
    relative = "editor",
    border = "rounded",  -- "none", "single", "double", "rounded", "solid", "shadow"
    title = " Claude Chat ",
    title_pos = "center", -- "left", "center", "right"
  },
  keymaps = {
    terminal = {      -- Terminal mode keybindings
      close = "<C-q>",           -- Close chat from terminal mode
      toggle = "<C-q>",          -- Toggle chat window visibility
      normal_mode = "<Esc><Esc>", -- Exit terminal mode to normal mode
      insert_file = "<C-f>",     -- Insert current file path
      interrupt = "<C-c>",       -- Interrupt/close chat
    },
  },
})
```

### Configuration Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `split` | `string` | `"vsplit"` | Split type: `"vsplit"`, `"split"`, or `"float"` |
| `position` | `string` | `"right"` | Position: `"right"`, `"left"`, `"top"`, `"bottom"` (ignored for float) |
| `width` | `number` | `0.6` | Width percentage (for vertical splits and float) |
| `height` | `number` | `0.8` | Height percentage (for horizontal splits and float) |
| `claude_cmd` | `string` | `"claude"` | Claude Code CLI command |
| `float_opts` | `table` | See example | Floating window options (border, title, etc.) |
| `keymaps` | `table` | See example | All keymap configurations (global and terminal) |

## 🔧 How It Works

1. **Context Gathering**: Collects your current file path, filetype, and any selected text
2. **Terminal Launch**: Opens a configured split and starts Claude Code CLI with context
3. **Smart Integration**: Claude receives rich context to provide better, more relevant responses
4. **Live Updates**: File changes are automatically detected and reflected in real-time

## 🌟 The Dream

Future features that would be amazing to have:

- **🔄 Session Management**: Background terminal sessions with easy recall
- **🎨 Prompt Customization**: Configurable base prompts and context formatting
- **📚 Better Base Prompts**: More intelligent default prompting
- **🔗 Multi-file Context**: Support for workspace-wide context sharing
- **💾 Chat History**: Persistent conversation history
- **🎯 Smart Context**: AI-powered relevant file detection

*Want to help make these dreams reality? Pull requests are more than welcome!*

## 🙏 Acknowledgments

This plugin was inspired by excellent work in the Claude-Neovim ecosystem:

- [greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim)
- [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)

## 📜 License

MIT License - feel free to use, modify, and distribute!
