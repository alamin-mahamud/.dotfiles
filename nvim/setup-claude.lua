-- 🔧 Claude API Setup Helper
-- Run this with :luafile ~/.config/nvim/setup-claude.lua

local function setup_claude_api()
  print("🤖 Claude API Setup for Neovim")
  print("================================")

  -- Check if API key is already set
  local api_key = os.getenv("ANTHROPIC_API_KEY")
  if api_key then
    print("✅ ANTHROPIC_API_KEY is already set!")
    print("   Key preview: " .. api_key:sub(1, 10) .. "...")
  else
    print("❌ ANTHROPIC_API_KEY not found in environment")
    print("\n📋 To set up Claude API:")
    print("1. Get your API key from: https://console.anthropic.com/")
    print("2. Add to your shell config:")

    local shell = os.getenv("SHELL")
    if shell:match("zsh") then
      print("   echo 'export ANTHROPIC_API_KEY=\"your-api-key-here\"' >> ~/.zshrc")
      print("   source ~/.zshrc")
    elseif shell:match("bash") then
      print("   echo 'export ANTHROPIC_API_KEY=\"your-api-key-here\"' >> ~/.bashrc")
      print("   source ~/.bashrc")
    else
      print('   export ANTHROPIC_API_KEY="your-api-key-here"')
    end

    print("\n3. Restart Neovim or reload your shell")
  end

  print("\n🎯 Available Claude Commands:")
  print("   <C-c>       - Smart code completion (insert mode)")
  print("   <leader>cc  - Open Claude Code terminal")
  print("   <leader>cb  - Send current buffer to Claude Code")
  print("   <leader>ce  - Explain current line")
  print("   <leader>ca  - Ask Claude about selection")
  print("   <leader>cr  - Refactor selection")
  print("   <leader>ct  - Generate tests")

  print("\n🧪 Test Claude Integration:")
  print("1. Set your API key (instructions above)")
  print("2. Open a code file: nvim test.py")
  print("3. Type some code and press <C-c> for completion")
  print("4. Select some code and press <leader>ce to explain it")

  -- Quick test of the API key
  if api_key then
    print("\n🧪 Testing API connection...")
    local claude = require("claude")
    claude.setup({
      api_key = api_key,
      model = "claude-sonnet-4-20250514",
      max_tokens = 100,
    })

    -- Simple test request
    local test_prompt = "Say 'Hello from Claude API!' and nothing else."
    local curl_cmd = {
      "curl",
      "-s",
      "-X",
      "POST",
      "https://api.anthropic.com/v1/messages",
      "-H",
      "Content-Type: application/json",
      "-H",
      "x-api-key: " .. api_key,
      "-H",
      "anthropic-version: 2023-06-01",
      "-d",
      vim.json.encode({
        model = "claude-3-5-sonnet-20241022",
        max_tokens = 100,
        messages = { { role = "user", content = test_prompt } },
      }),
    }

    vim.fn.jobstart(curl_cmd, {
      on_stdout = function(_, data)
        if data and #data > 0 then
          local response_text = table.concat(data, "\n")
          local ok, response = pcall(vim.json.decode, response_text)

          if ok and response.content and response.content[1] then
            print("✅ API Test Success: " .. response.content[1].text)
          else
            print("❌ API Test Failed: Invalid response format")
          end
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          print("❌ API Test Error: " .. table.concat(data, "\n"))
        end
      end,
    })
  end
end

-- Run the setup
setup_claude_api()

