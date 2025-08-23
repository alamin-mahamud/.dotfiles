-- 🧪 Simple Claude API Test
-- Run this with: :luafile ~/.config/nvim/test-claude-api.lua

local api_key = os.getenv("ANTHROPIC_API_KEY")

if not api_key then
  print("❌ ANTHROPIC_API_KEY not set")
  print("Set it with: export ANTHROPIC_API_KEY='your-key-here'")
  return
end

print("🧪 Testing Claude API...")
print("API Key: " .. api_key:sub(1, 10) .. "...")

-- Simple curl test
local curl_cmd = {
  "curl", "-s", "-w", "\\n%{http_code}",
  "-X", "POST",
  "https://api.anthropic.com/v1/messages",
  "-H", "Content-Type: application/json", 
  "-H", "x-api-key: " .. api_key,
  "-H", "anthropic-version: 2023-06-01",
  "-d", vim.json.encode({
    model = "claude-3-5-sonnet-20241022",
    max_tokens = 50,
    messages = {
      {
        role = "user", 
        content = "Say 'Hello from Neovim!' and nothing else."
      }
    }
  })
}

local response_lines = {}
local error_lines = {}

vim.fn.jobstart(curl_cmd, {
  on_stdout = function(_, data)
    for _, line in ipairs(data) do
      if line ~= "" then
        table.insert(response_lines, line)
      end
    end
  end,
  on_stderr = function(_, data)
    for _, line in ipairs(data) do
      if line ~= "" then
        table.insert(error_lines, line)
      end
    end
  end,
  on_exit = function(_, exit_code)
    print("\n📊 Test Results:")
    print("Exit code: " .. exit_code)
    
    if exit_code ~= 0 then
      print("❌ Curl failed!")
      if #error_lines > 0 then
        print("Errors: " .. table.concat(error_lines, "\n"))
      end
      return
    end
    
    if #response_lines == 0 then
      print("❌ No response received")
      return
    end
    
    -- Last line is HTTP status
    local http_code = tonumber(response_lines[#response_lines])
    local response_body = table.concat(response_lines, "\n", 1, #response_lines - 1)
    
    print("HTTP Status: " .. (http_code or "unknown"))
    
    if http_code and http_code >= 400 then
      print("❌ HTTP Error " .. http_code)
      print("Response: " .. response_body)
      return
    end
    
    print("Raw response:")
    print(response_body)
    print("\n" .. string.rep("-", 50))
    
    local ok, response = pcall(vim.json.decode, response_body)
    if not ok then
      print("❌ Failed to parse JSON: " .. response)
      return
    end
    
    if response.error then
      print("❌ API Error: " .. response.error.message)
      return
    end
    
    if response.content and response.content[1] then
      print("✅ Success! Claude says: " .. response.content[1].text)
    else
      print("❌ Unexpected response format")
      print("Response structure: " .. vim.inspect(response))
    end
  end,
})