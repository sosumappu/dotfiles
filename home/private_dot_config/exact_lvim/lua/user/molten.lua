local M = {}

local keys = function(str)
    return function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(str, true, false, true), "m", true)
    end
end


local imb = function(e) -- init molten buffer
    vim.schedule(function()
        -- Change to the notebook's directory
        vim.cmd("cd %:p:h")

        local kernels = vim.fn.MoltenAvailableKernels()
        local try_kernel_name = function()
            local metadata = vim.json.decode(io.open(e.file, "r"):read("a"))["metadata"]
            return metadata.kernelspec.name
        end
        local ok, kernel_name = pcall(try_kernel_name)
        if not ok or not vim.tbl_contains(kernels, kernel_name) then
            kernel_name = nil
            local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
            if venv ~= nil then
                kernel_name = string.match(venv, "/.+/(.+)")
            end
        end
        if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
            vim.cmd(("MoltenInit %s"):format(kernel_name))
        end
        vim.cmd("MoltenImportOutput")
    end)
end

M.config = function()
    -- a keybind for `:noautocmd MoltenEnterOutput` to open the output again
    vim.g.molten_auto_open_output = false
    -- this guide will be using image.nvim
    -- Don't forget to setup and install the plugin if you want to view image outputs
    vim.g.molten_image_provider = "image.nvim"
    -- optional, I like wrapping. works for virt text and the output window
    vim.g.molten_wrap_output = true
    -- Output as virtual text. Allows outputs to always be shown, works with images, but can
    -- be buggy with longer images
    vim.g.molten_virt_text_output = true
    -- this will make it so the output shows up below the \`\`\` cell delimiter
    vim.g.molten_virt_lines_off_by_1 = true

    --- AUTOCMD
    -- automatically import output chunks from a jupyter notebook
    vim.api.nvim_create_autocmd("BufAdd", {
        pattern = { "*.ipynb" },
        callback = imb,
    })
    -- we have to do this as well so that we catch files opened like nvim ./hi.ipynb
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "*.ipynb" },
        callback = function(e)
            if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
                imb(e)
            end
        end,
    })
    -- -- automatically export output chunks to a jupyter notebook on write
    -- vim.api.nvim_create_autocmd("BufWritePost", {
    --     pattern = { "*.ipynb" },
    --     callback = function()
    --         if require("molten.status").initialized() == "Molten" then
    --             vim.cmd("MoltenExportOutput!")
    --         end
    --     end,
    -- })

    local wk_status, wk = pcall(require, "which-key")
    if not wk_status then
        vim.notify("which-key not found", vim.log.levels.WARN)
        return
    end

    -- Setup keybindings only for markdown and python files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "python" },
        callback = function()
            wk.register({
                j = {
                    name = " [J]upyter",
                    e = {
                        ":MoltenEvaluateOperator<CR>",
                        "󰘦 Evaluate operator",
                    },
                    o = {
                        ":noautocmd MoltenEnterOutput<CR>",
                        "󰏋 Open output window",
                    },
                    r = { ":MoltenReevaluateCell<CR>", "󰑐 Re-evaluate cell" },
                    h = { ":MoltenHideOutput<CR>", "󰘖 Hide output window" },
                    d = { ":MoltenDelete<CR>", "󰆴 Delete Molten cell" },
                    x = {
                        ":MoltenOpenInBrowser<CR>",
                        "󰖟 Open output in browser",
                    },
                },
            }, { prefix = "<leader>", mode = "n", noremap = true, silent = true, nowait = true, buffer = 0 })

            -- Visual mode mapping for execute selection
            wk.register({
                j = {
                    name = " [J]upyter",
                    r = {
                        ":<C-u>MoltenEvaluateVisual<CR>gv",
                        "▶ Execute visual selection",
                    },
                },
            }, { prefix = "<leader>", mode = "v", noremap = true, silent = true, nowait = true, buffer = 0 })
        end,
    })
end

return M
