-- based on lazyvim clangd config
return {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders',
    '--fallback-style=llvm',
    '--pch-storage=memory',
  },
  capabilities = {
    offsetEncoding = { "utf-16" },
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
  root_dir = function(_bufnr, on_dir)
    on_dir(vim.fs.root(0, {
      "compile_commands.json",
      "compile_flags.txt",
      "configure.ac", -- AutoTools
      "Makefile",
      "configure.ac",
      "configure.in",
      "config.h.in",
      "meson.build",
      "meson_options.txt",
      "build.ninja",
      ".git",
      vim.api.nvim_buf_get_name(0)
    }))
  end,
}
