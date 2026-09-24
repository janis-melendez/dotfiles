-- Installs Tree-sitter parsers and enables Tree-sitter syntax highlighting

return {
    "romus204/tree-sitter-manager.nvim",
    -- NOTE: Currently disabled. Kept as a backup of nvim-treesitter.
    enabled = false,
    lazy = false,
    opts = {
        -- Parsers not included in tree-sitter-manager's repository registry
        languages = {
            make = {
                install_info = {
                    url = "https://github.com/tree-sitter-grammars/tree-sitter-make",
                },
            },
            mermaid = {
                install_info = {
                    url = "https://github.com/monaqa/tree-sitter-mermaid",
                },
            },
            rasi = {
                install_info = {
                    url = "https://github.com/Fymyte/tree-sitter-rasi",
                },
            },
            tmux = {
                install_info = {
                    url = "https://github.com/Freed-Wu/tree-sitter-tmux",
                    revision = "0.1.1",
                    queries = "queries",
                }
            },
        },

        ensure_installed = {
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
        },
        auto_install = true,
    },
}
