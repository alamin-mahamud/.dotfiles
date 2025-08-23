-- 🎯 Simple Claude Integration (Testing Version)
-- Minimal setup to get Claude working first

return {
  -- Basic dependencies
  {
    "nvim-lua/plenary.nvim", -- For HTTP and utilities
  },
  
  -- Simple Claude commands
  {
    "akinsho/toggleterm.nvim",
    keys = {
      -- Simple Claude Code terminal 
      { "<leader>cc", function() 
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude",
          hidden = true,
          direction = "float",
          float_opts = {
            border = "curved",
            width = function() return math.floor(vim.o.columns * 0.85) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            vim.defer_fn(function()
              term:send("/vim")  -- Enable vim mode
            end, 100)
          end,
        })
        claude_term:toggle()
      end, desc = "Claude Code Terminal" },
      
      -- Send file to Claude Code
      { "<leader>cb", function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content = table.concat(lines, "\n")
        local filename = vim.fn.expand("%:t") 
        local filetype = vim.bo.filetype
        
        -- Copy to clipboard first
        vim.fn.setreg("+", content)
        
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude",
          hidden = true, 
          direction = "float",
          float_opts = {
            border = "curved",
            width = function() return math.floor(vim.o.columns * 0.85) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            vim.defer_fn(function()
              term:send("/vim")
              local msg = string.format("Help with this %s file (%s):\n\n```%s\n%s\n```", 
                filetype or "code", filename, filetype or "", content)
              term:send(msg)
            end, 200)
          end,
        })
        claude_term:toggle()
        vim.notify("Sent " .. filename .. " to Claude Code", vim.log.levels.INFO)
      end, desc = "Send file to Claude Code" },
    }
  },
  
  -- Manual Claude API completion
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Simple manual completion function
      vim.api.nvim_create_user_command("ClaudeComplete", function()
        local claude = require("claude")
        if claude.complete then
          claude.complete()
        else
          vim.notify("Claude module not loaded properly", vim.log.levels.ERROR)
        end
      end, { desc = "Trigger Claude completion" })
      
      -- Simple explanation function
      vim.api.nvim_create_user_command("ClaudeExplain", function(opts)
        local claude = require("claude")
        local text = ""
        
        if opts.range == 2 then
          -- Visual selection
          local lines = vim.fn.getline(opts.line1, opts.line2)
          text = table.concat(lines, "\n")
        else
          -- Current line
          text = vim.api.nvim_get_current_line()
        end
        
        if claude.explain then
          claude.explain(text)
        else
          vim.notify("Claude module not loaded properly", vim.log.levels.ERROR)
        end
      end, { range = true, desc = "Explain code with Claude" })
      
      -- Test API function
      vim.api.nvim_create_user_command("ClaudeTest", function()
        print("🧪 Testing Claude API...")
        local api_key = os.getenv("ANTHROPIC_API_KEY")
        
        if not api_key then
          vim.notify("ANTHROPIC_API_KEY not set", vim.log.levels.ERROR)
          return
        end
        
        print("✅ API key found: " .. api_key:sub(1, 10) .. "...")
        
        -- Try to load claude module
        local ok, claude = pcall(require, "claude")
        if not ok then
          vim.notify("Failed to load claude module: " .. claude, vim.log.levels.ERROR)
          return
        end
        
        print("✅ Claude module loaded")
        
        -- Setup claude
        claude.setup({ api_key = api_key })
        print("✅ Claude configured")
        
        -- Test simple request
        claude.ask("Respond with just 'Hello from Claude API test!' and nothing else.")
      end, { desc = "Test Claude API connection" })
    end,
    keys = {
      { "<C-c>", ":ClaudeComplete<cr>", desc = "Claude completion", mode = "i" },
      { "<leader>ce", ":ClaudeExplain<cr>", desc = "Explain with Claude" },
      { "<leader>ct", ":ClaudeTest<cr>", desc = "Test Claude API" },
    }
  }
}

--[[
🧪 TESTING STEPS:

1. Make sure you have your API key set:
   export ANTHROPIC_API_KEY="your-key-here" 

2. Restart Neovim

3. Test the Claude module:
   :ClaudeTest

4. If that works, try explaining code:
   - Select some text in visual mode
   - Press <leader>ce

5. Test Claude Code integration:
   - Press <leader>cc for Claude terminal
   - Press <leader>cb to send current file

6. Test manual completion:
   - In insert mode, type some code
   - Press <C-c> for completion

🔧 If something fails:
- Check :messages for errors
- Run :ClaudeTest to debug step by step  
- Make sure 'claude' CLI is installed for terminal features
--]]