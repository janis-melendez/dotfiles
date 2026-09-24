-- Adds Tree-sitter parsers for better syntax highlighting, indentation, and plugin integrations

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    enabled = true,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local treesitter = require("nvim-treesitter")

        treesitter.setup({
            install_dir = vim.fn.stdpath("data") .. "/site",
        })

        local function register_custom_parsers()
            local parsers = require("nvim-treesitter.parsers")

            parsers.ghostty = {
                install_info = {
                    url = "https://github.com/bezhermoso/tree-sitter-ghostty",
                    revision = "7f41507014534e5f72d16e4639c0346d0adb8054",
                    queries = "queries/ghostty",
                },
                tier = 2,
            }

            parsers.tmux = {
                install_info = {
                    url = "https://github.com/Freed-Wu/tree-sitter-tmux",
                    branch = "main",
                    queries = "queries",
                },
                tier = 2,
            }
        end

        -- Re-register the custom parser after nvim-treesitter updates its registry
        vim.api.nvim_create_autocmd("User", {
            group = vim.api.nvim_create_augroup(
                "treesitter-custom-parsers",
                { clear = true }
            ),
            pattern = "TSUpdate",
            callback = register_custom_parsers,
        })

        -- Makes the parsers available immediately
        register_custom_parsers()

        local ensure_installed = {
            -- Neovim / Lua
            "lua",
            "query",
            "vim",
            "vimdoc",

            -- Shell / dotfiles
            "bash",
            "tmux",
            "zsh",

            -- Git
            "diff",
            "git_config",
            "git_rebase",
            "gitattributes",
            "gitcommit",
            "gitignore",

            -- Web
            "css",
            "html",
            "javascript",
            "jsdoc",
            "scss",
            "tsx",
            "typescript",

            -- Dart / Flutter
            "dart",

            -- Documentation
            "markdown",
            "markdown_inline",
            "mermaid",

            -- Backend / scripting
            "php",
            "phpdoc",
            "python",
            "sql",

            -- Sytems and compiled languages
            "c",
            "cpp",
            "go",
            "gomod",
            "gosum",
            "gowork",
            "java",
            "rust",

            -- Systems and compiled languages
            "dockerfile",
            "hcl",
            "helm" ,

            -- Build and project files
            "cmake",
            "editorconfig",
            "make",

            -- Config formats
            "json",
            "json5",
            "kdl",
            "ini",
            "toml",
            "yaml",

            -- Application configuration
            "ghostty",
            "rasi",
        }

        -- Must happen after creating the TSUpdate autocmd
        treesitter.install(ensure_installed)

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                pcall(vim.treesitter.start, args.buf)
            end,
        })
    end,
}
