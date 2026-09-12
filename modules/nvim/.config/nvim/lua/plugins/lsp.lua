-- Installs, configures, and enables language servers
local mason_server_names = {
    -- Lua / Neovim
    "lua_ls",

    -- Shell
    "bashls",

    -- Web
    "cssls",
    "eslint",
    "html",
    "jsonls",
    "tailwindcss",
    "ts_ls",

    -- Documentation and grammar
    -- "harper_ls",
    "marksman",

    -- Scripting and backend
    "phpactor",
    "pyright",
    "ruff",
    "sqlls",

    -- Systems and compiled languages
    "clangd",
    "gopls",
    "jdtls",
    "rust_analyzer",

    -- Build and project files
    "autotools_ls",
    "neocmake",

    -- Configuration formats
    "taplo",
    "yamlls",

    -- Infastructure / platform
    "docker_compose_language_service",
    "dockerls",
    "helm_ls",
    "terraformls",

    -- CI / Linux tooling
    "gh_actions_ls",
    "systemd_lsp",
}

-- Servers installed outside of Mason; ensure their executables are available in PATH
local external_server_names = {
    -- Dart / Flutter (provided by the Dart SDK)
    "dartls",
}

local server_names = vim.list_extend(
    vim.deepcopy(mason_server_names),
    external_server_names
)

local function get_server_configs()
    local schemastore = require("schemastore")

    return {
        lua_ls = {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
                    },
                },
            },
        },

        jsonls = {
            settings = {
                json = {
                    schemas = schemastore.json.schemas(),
                    validate = { enable = true },
                },
            },
        },

        yamlls = {
            settings = {
                yaml = {
                    schemaStore = {
                        enable = false,
                        url = "",
                    },
                    schemas = schemastore.yaml.schemas(),
                    validate = true,
                    completion = true,
                    hover = true,
                },
            },
        },

        pyright = {
            settings = {
                python = {
                    analysis = {
                        typeCheckingMode = "basic",
                    },
                },
            },
        },
    }
end

return {
    -- Install and manage external tools for NeoVim
    {
        "mason-org/mason.nvim",
        opts = {},
    },

    -- Auto-install LSP servers listed by nvim-lspconfig name
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
        },
        opts = {
            ensure_installed = mason_server_names,
            automatic_enable = false,
        },
    },

    -- Configure and enable Neovim language servers.
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "mason-org/mason-lspconfig.nvim",
            "b0o/schemastore.nvim",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local server_configs = get_server_configs()

            -- Register each server with optional config and shared completion capabilities
            for _, server in ipairs(server_names) do
                local server_config = server_configs[server] or {}

                local config = vim.tbl_deep_extend('force', {}, server_config, {
                    capabilities = capabilities,
                })

                vim.lsp.config(server, config)
            end

            -- Enable Mason-managed and externally installed servers
            vim.lsp.enable(server_names)
        end,
    }
}
