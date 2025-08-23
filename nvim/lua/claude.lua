-- 🤖 Claude API Integration for Neovim
-- Simple, focused Claude API client for code completion and assistance

local M = {}

-- Configuration
M.config = {
  api_key = nil,
  api_url = "https://api.anthropic.com/v1/messages",
  model = "claude-3-5-sonnet-20241022",
  max_tokens = 1000,
  temperature = 0.7,
}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  
  -- Get API key from environment if not provided
  if not M.config.api_key then
    M.config.api_key = os.getenv("ANTHROPIC_API_KEY")
  end
  
  if not M.config.api_key then
    vim.notify("Claude API key not found. Set ANTHROPIC_API_KEY environment variable.", vim.log.levels.WARN)
  end
end

-- Make API request to Claude
local function make_request(prompt, callback)
  if not M.config.api_key then
    vim.notify("Claude API key not configured. Set ANTHROPIC_API_KEY environment variable.", vim.log.levels.ERROR)
    return
  end

  -- Prepare the request payload
  local payload = {
    model = M.config.model,
    max_tokens = M.config.max_tokens,
    temperature = M.config.temperature,
    messages = {
      {
        role = "user",
        content = prompt
      }
    }
  }

  local curl_cmd = {
    "curl", "-s", "-w", "\\n%{http_code}",
    "-X", "POST",
    M.config.api_url,
    "-H", "Content-Type: application/json",
    "-H", "x-api-key: " .. M.config.api_key,
    "-H", "anthropic-version: 2023-06-01",
    "-d", vim.json.encode(payload)
  }

  local response_data = {}
  local stderr_data = {}

  vim.fn.jobstart(curl_cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(response_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        local error_msg = "Curl failed with exit code: " .. exit_code
        if #stderr_data > 0 then
          error_msg = error_msg .. "\nError: " .. table.concat(stderr_data, "\n")
        end
        vim.notify("Claude API Error: " .. error_msg, vim.log.levels.ERROR)
        return
      end

      if #response_data == 0 then
        vim.notify("No response from Claude API", vim.log.levels.ERROR)
        return
      end

      -- The last line should be the HTTP status code
      local http_code = tonumber(response_data[#response_data])
      local response_body = table.concat(response_data, "\n", 1, #response_data - 1)

      if http_code and http_code >= 400 then
        vim.notify("Claude API HTTP Error " .. http_code .. ": " .. response_body, vim.log.levels.ERROR)
        return
      end

      local ok, response = pcall(vim.json.decode, response_body)
      if not ok then
        vim.notify("Failed to parse Claude API response: " .. (response or "invalid JSON"), vim.log.levels.ERROR)
        return
      end

      if response.error then
        vim.notify("Claude API Error: " .. (response.error.message or "Unknown error"), vim.log.levels.ERROR)
        return
      end

      if response.content and response.content[1] and response.content[1].text then
        callback(response.content[1].text)
      else
        vim.notify("Unexpected Claude API response format", vim.log.levels.ERROR)
        print("Response:", vim.inspect(response))
      end
    end,
  })
end

-- Get current context for better completions
local function get_context()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1]
  local col_num = cursor_pos[2]
  
  -- Get surrounding lines for context
  local start_line = math.max(1, line_num - 10)
  local end_line = math.min(vim.api.nvim_buf_line_count(0), line_num + 5)
  local context_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:t")
  
  return {
    current_line = current_line,
    cursor_pos = col_num,
    context_lines = context_lines,
    filetype = filetype,
    filename = filename,
    line_num = line_num - start_line + 1 -- Relative line number in context
  }
end

-- Code completion function
function M.complete()
  local context = get_context()
  local prompt = string.format([[
You are a code completion assistant. Complete the following %s code intelligently.

File: %s
Context (current line is marked with >>> ):
%s

Complete the code naturally. Provide only the completion, no explanations.
]], 
    context.filetype or "code",
    context.filename or "untitled",
    table.concat(context.context_lines, "\n"):gsub(context.context_lines[context.line_num], ">>> " .. context.context_lines[context.line_num])
  )
  
  make_request(prompt, function(completion)
    -- Insert completion at cursor
    local lines = vim.split(completion, "\n")
    if #lines > 0 then
      -- Remove the current line's duplicate if present
      local first_line = lines[1]
      local current_line_part = context.current_line:sub(context.cursor_pos + 1)
      
      if first_line:find(current_line_part, 1, true) then
        first_line = first_line:gsub(vim.pesc(current_line_part), "", 1)
        lines[1] = first_line
      end
      
      vim.api.nvim_put(lines, "c", true, true)
    end
  end)
end

-- Explain code function
function M.explain(code)
  local prompt = string.format([[
Explain this %s code clearly and concisely:

```%s
%s
```

Provide a brief, helpful explanation focusing on what the code does.
]], vim.bo.filetype or "code", vim.bo.filetype or "", code)
  
  make_request(prompt, function(explanation)
    -- Show explanation in a floating window
    local lines = vim.split(explanation, "\n")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines + 2, vim.o.lines - 4)
    
    vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = width,
      height = height,
      row = (vim.o.lines - height) / 2,
      col = (vim.o.columns - width) / 2,
      style = "minimal",
      border = "rounded",
      title = " Claude Explanation ",
      title_pos = "center",
    })
    
    -- Close with escape or any key
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", {noremap = true, silent = true})
  end)
end

-- Ask Claude about code
function M.ask(question)
  local context = get_context()
  local prompt = string.format([[
I'm working on %s code in file %s. Here's my question:

%s

Context:
```%s
%s
```

Please provide a helpful answer.
]], context.filetype or "code", context.filename or "untitled", question, context.filetype or "", table.concat(context.context_lines, "\n"))
  
  make_request(prompt, function(answer)
    -- Show answer in a floating window
    local lines = vim.split(answer, "\n")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown" -- Enable markdown highlighting
    
    local width = math.min(100, vim.o.columns - 4)
    local height = math.min(#lines + 2, vim.o.lines - 4)
    
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = (vim.o.lines - height) / 2,
      col = (vim.o.columns - width) / 2,
      style = "minimal",
      border = "rounded",
      title = " Claude Answer ",
      title_pos = "center",
    })
    
    -- Close with escape or q
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", {noremap = true, silent = true})
  end)
end

-- Refactor code function
function M.refactor(code)
  local prompt = string.format([[
Refactor this %s code to make it cleaner, more readable, and follow best practices:

```%s
%s
```

Provide only the refactored code, no explanations.
]], vim.bo.filetype or "code", vim.bo.filetype or "", code)
  
  make_request(prompt, function(refactored)
    -- Replace selected text with refactored version
    local lines = vim.split(refactored, "\n")
    -- Remove code block markers if present
    if lines[1]:match("^```") then
      table.remove(lines, 1)
      if lines[#lines]:match("^```") then
        table.remove(lines, #lines)
      end
    end
    
    -- Replace current selection
    vim.api.nvim_put(lines, "l", false, true)
  end)
end

-- Generate tests function
function M.generate_tests(code)
  local prompt = string.format([[
Generate comprehensive unit tests for this %s code:

```%s
%s
```

Create tests that cover normal cases, edge cases, and error conditions. Use the appropriate testing framework for %s.
]], vim.bo.filetype or "code", vim.bo.filetype or "", code, vim.bo.filetype or "the language")
  
  make_request(prompt, function(tests)
    -- Show tests in a new buffer
    local buf = vim.api.nvim_create_buf(true, false)
    local lines = vim.split(tests, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = vim.bo.filetype -- Same filetype as original
    
    vim.api.nvim_set_current_buf(buf)
    vim.notify("Generated tests in new buffer", vim.log.levels.INFO)
  end)
end

return M