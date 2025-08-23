-- Custom keymaps for LazyVim - Python & DevOps focused
local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better line movement
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Quick save
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })

-- Python specific
map("n", "<leader>pr", "<cmd>!python3 %<cr>", { desc = "Run Python file" })
map("n", "<leader>pd", "<cmd>lua require('dap-python').test_method()<cr>", { desc = "Debug Python method" })
map("n", "<leader>pf", "<cmd>lua require('dap-python').test_class()<cr>", { desc = "Debug Python class" })
map("n", "<leader>ps", "<cmd>lua require('dap-python').debug_selection()<cr>", { desc = "Debug Python selection" })

-- Docker/K8s
map("n", "<leader>dk", "<cmd>!kubectl apply -f %<cr>", { desc = "Apply K8s manifest" })
map("n", "<leader>dd", "<cmd>!docker build .<cr>", { desc = "Docker build" })

-- Terraform
map("n", "<leader>ti", "<cmd>!terraform init<cr>", { desc = "Terraform init" })
map("n", "<leader>tp", "<cmd>!terraform plan<cr>", { desc = "Terraform plan" })
map("n", "<leader>tf", "<cmd>!terraform fmt %<cr>", { desc = "Terraform format" })
map("n", "<leader>tv", "<cmd>!terraform validate<cr>", { desc = "Terraform validate" })

-- Git (enhanced)
map("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Git status" })
map("n", "<leader>gp", "<cmd>!git push<cr>", { desc = "Git push" })
map("n", "<leader>gpu", "<cmd>!git pull<cr>", { desc = "Git pull" })
map("n", "<leader>gc", "<cmd>!git commit<cr>", { desc = "Git commit" })
map("n", "<leader>ga", "<cmd>!git add .<cr>", { desc = "Git add all" })
map("n", "<leader>gb", "<cmd>Gblame<cr>", { desc = "Git blame" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Git diff view" })
map("n", "<leader>gl", "<cmd>!git log --oneline -10<cr>", { desc = "Git log" })
map("n", "<leader>gco", "<cmd>!git checkout ", { desc = "Git checkout" })
