local bundles = {}
local bundles_specs = {
  { name = "http:java-test", path = "/extension/server/*.jar" },
  { name = "http:java-debug", path = "/extension/server/com.microsoft.java.debug.plugin-*.jar" },
  { name = "http:lombok", path = "*.jar" },
}

local function get_mise_pkg(pkg_name)
  local r = vim.system({ "mise", "where", pkg_name }):wait()
  if r.code == 0 then
    return vim.trim(r.stdout)
  end
  error("Package not found" .. pkg_name)
end

for _, spec in ipairs(bundles_specs) do
  vim.list_extend(bundles, vim.fn.glob(get_mise_pkg(spec.name) .. spec.path, true, true))
end

local function get_capabilities()
  local c = {}
  local jdtls = require("jdtls")
  vim.list_extend(c, jdtls.extendedClientCapabilities)
  return c
end

return {
  root_markers = { ".git", "gradlew", "mvnw" },
  cmd = { "jdtls" },
  filetypes = { "java" },
  init_options = {
    bundles = bundles,
    extendedClientCapabilities = get_capabilities(),
  },
  settings = {
    java = {
      -- Enable code formatting
      format = {
        enabled = true,
        settings = {
          profile = "GoogleStyle",
          url = os.getenv("HOME") .. "/.config/nvim/.java-google-formatter.xml",
        },
      },
      -- Enable downloading archives from eclipse automatically
      eclipse = {
        downloadSource = true,
      },
      -- Enable downloading archives from maven automatically
      maven = {
        downloadSources = true,
      },
      -- Enable method signature help
      signatureHelp = {
        enabled = true,
      },
      -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
      contentProvider = {
        preferred = "fernflower",
      },
      -- Setup automatical package import oranization on file save
      saveActions = {
        organizeImports = true,
      },
      -- Customize completion options
      completion = {
        -- When using an unimported static method, how should the LSP rank possible places to import the static method from
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
        },
        -- Try not to suggest imports from these packages in the code action window
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
        -- Set the order in which the language server should organize imports
        -- "" is all others, "#" is static imports
        importOrder = {
          "com",
          "lombok",
          "org",
          "jakarta",
          "javax",
          "java",
          "",
          "#",
        },
      },
      sources = {
        -- How many classes from a specific package should be imported before automatic imports combine them all into a single import
        organizeImports = {
          starThreshold = 9999,
          staticThreshold = 9999,
        },
      },
      -- How should different pieces of code be generated?
      codeGeneration = {
        -- When generating toString use a json format
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        -- When generating hashCode and equals methods use the java 7 objects method
        hashCodeEquals = {
          useJava7Objects = true,
        },
        -- When generating code use code blocks
        useBlocks = true,
      },
      -- If changes to the project will require the developer to update the projects configuration advise the developer before accepting the change
      configuration = {
        runtimes = {
          -- will most likely have a different path on other systems
          {
            name = "JavaSE-21",
            path = os.getenv("JAVA_HOME"),
          },
        },
        updateBuildConfiguration = "interactive",
      },
      -- enable code lens in the lsp
      referencesCodeLens = {
        enabled = true,
      },
      -- enable inlay hints for parameter names,
      inlayHints = {
        parameterNames = {
          enabled = "all",
        },
      },
    },
  },
}
