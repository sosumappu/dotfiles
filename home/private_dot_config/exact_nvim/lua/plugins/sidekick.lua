return {
    "folke/sidekick.nvim",
    opts = {
        cli = {
            mux = {
                backend = "tmux",
                enabled = true,
            },
        },
        nes = { enabled = true },
    },
    keys = {
        -- disable overlapping keymaps with avante.lua
        {
            "<leader>aa",
            false
        },
        {
            "<leader>af",
            false
        },
        {
            "<tab>",
            function()
                if not require("sidekick").nes_jump_or_apply() then
                    return "<Tab>"
                end
            end,
            expr = true,
            desc = "Goto/Apply Next Edit Suggestion",
        },
        {
            "<leader>as",
            function()
                require("sidekick.cli").toggle()
            end,
            desc = "Sidekick Toggle CLI",
        },
        {
            "<leader>aF",
            function() require("sidekick.cli").send({ msg = "{file}" }) end,
            desc = "Send File",
        }
    },
}
