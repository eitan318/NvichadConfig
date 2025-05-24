
local M = {}

-- Helper function to load project-specific configuration
local function load_project_config()
  local local_config_path = vim.fn.getcwd() .. "/local.lua"
  local status, config = pcall(dofile, local_config_path)
  if not status then
    print("Error loading local.lua: " .. config)
    return nil
  end
  return config
end

-- Helper function to detect project type
local function detect_project_type()
  -- Check for C++ project files
  if vim.fn.glob("CMakeLists.txt") ~= "" or vim.fn.glob("*.cpp") ~= "" then
    return "cpp"
  end

  -- Check for C# project files
  if vim.fn.glob("*.sln") ~= "" or vim.fn.glob("*.csproj") ~= "" then
    return "cs"
  end



  return nil -- Unknown project type
end



local function build_cs_project(on_success)
  local cmd = "dotnet build"

  -- Run dotnet build command
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.fn.setqflist({}, "r", { title = "dotnet build Output", lines = data })
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.fn.setqflist({}, "a", { title = "dotnet build Errors", lines = data })
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        print("dotnet build completed successfully!")
        if on_success then
          on_success() -- Execute the callback if provided
        end
      else
        print("dotnet build failed with code:", code)
        vim.cmd("copen") -- Open the quickfix list
      end
    end,
  })
end

-- Helper function to build the project
local function build_cpp_project(on_success)
  local local_config = load_project_config()
  if not local_config or not local_config.project_sln then
    print("Error: project_sln not defined in local.lua")
    return
  end

  -- MSBuild command
  local cmd = string.format("msbuild \"%s\" /nologo /clp:ErrorsOnly /p:Configuration=Debug", local_config.project_sln)

  -- Run command and populate quickfix list
  vim.fn.jobstart(cmd, {
    stdout_buffered = true, -- Buffer the stdout data
    stderr_buffered = true, -- Buffer the stderr data
    on_stdout = function(_, data)
      if data then
        vim.fn.setqflist({}, "r", { title = "MSBuild Errors", lines = data }) -- Reset and set the quickfix list
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.fn.setqflist({}, "a", { title = "MSBuild Errors", lines = data }) -- Append stderr to the quickfix list
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        print("Build completed successfully!")
        if on_success then
          on_success() -- Execute the callback if provided
        end
      else
        print("Build failed with code:", code)
        vim.cmd("copen") -- Open the quickfix list
      end
    end,
  })
end

-- Helper function to build the project
local function build_project(on_success)
  local project_type = detect_project_type()
  if project_type == "cs" then
    build_cs_project(on_success)
  elseif project_type == "cpp" then
    build_cpp_project(on_success)
  else
    print("Error: Unknown project type. Cannot build.")
   end
end

-- DAP and Build keymaps
M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = { "<cmd> DapToggleBreakpoint <CR>", "Add breakpoint at line" },
    ["<leader>dr"] = {
      function()
        -- Build project first, then start debugging
        build_project(function()
          vim.cmd("DapContinue") -- Start debugging after a successful build
        end)
      end,
      "Build project and start debugging",
    },
    ["<leader>mb"] = {
      function()
        build_project()
      end,
      "Build project (C# or C++)",
    },
  },
}

-- Helper function to rename the current file
local function rename_file()
  local current_file = vim.fn.expand('%:p')
  local new_name = vim.fn.input('Rename to: ', current_file)
  if new_name ~= '' and new_name ~= current_file then
    vim.cmd('saveas ' .. new_name)
    vim.cmd('silent !rm ' .. current_file)
    print('File renamed to ' .. new_name)
  else
    print('Rename cancelled.')
  end
end



local hebrew_mode = false

local function toggle_hebrew_mode()
  local api = vim.api
  if hebrew_mode then
    vim.o.keymap = ""
    vim.o.rightleft = false
    -- Don't set arabic here
    api.nvim_echo({{"Switched to English mode", "None"}}, false, {})
    hebrew_mode = false
  else
    vim.o.keymap = "hebrew"
    vim.o.rightleft = true
    -- Do NOT set arabic here for Hebrew
    api.nvim_echo({{"Switched to Hebrew mode", "None"}}, false, {})
    hebrew_mode = true
  end
end


-- Helper function to clean and rebuild C++ projects
local function clean_rebuild_cpp_project(on_success)
  local local_config = load_project_config()
  if not local_config or not local_config.project_sln then
    print("Error: project_sln not defined in local.lua")
    return
  end

  -- MSBuild clean and rebuild command
  local cmd_clean = string.format("msbuild \"%s\" /target:Clean /nologo", local_config.project_sln)
  local cmd_rebuild = string.format("msbuild \"%s\" /target:Rebuild /nologo /p:Configuration=Debug", local_config.project_sln)

  -- Run clean command first
  vim.fn.jobstart(cmd_clean, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        print("Clean completed successfully! Starting rebuild...")
        -- Run rebuild command after clean
        vim.fn.jobstart(cmd_rebuild, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_stdout = function(_, data)
            if data then
              vim.fn.setqflist({}, "r", { title = "MSBuild Rebuild", lines = data })
            end
          end,
          on_stderr = function(_, data)
            if data then
              vim.fn.setqflist({}, "a", { title = "MSBuild Rebuild Errors", lines = data })
            end
          end,
          on_exit = function(_, code)
            if code == 0 then
              print("Rebuild completed successfully!")
              if on_success then
                on_success()
              end
            else
              print("Rebuild failed with code:", code)
              vim.cmd("copen")
            end
          end,
        })
      else
        print("Clean failed with code:", code)
        vim.cmd("copen")
      end
    end,
  })
end

-- Helper function to clean and rebuild C# projects
local function clean_rebuild_cs_project(on_success)
  local cmd_clean = "dotnet clean"
  local cmd_rebuild = "dotnet build"

  -- Run clean command first
  vim.fn.jobstart(cmd_clean, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        print("Clean completed successfully! Starting rebuild...")
        -- Run rebuild command after clean
        vim.fn.jobstart(cmd_rebuild, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_stdout = function(_, data)
            if data then
              vim.fn.setqflist({}, "r", { title = "dotnet Rebuild", lines = data })
            end
          end,
          on_stderr = function(_, data)
            if data then
              vim.fn.setqflist({}, "a", { title = "dotnet Rebuild Errors", lines = data })
            end
          end,
          on_exit = function(_, code)
            if code == 0 then
              print("Rebuild completed successfully!")
              if on_success then
                on_success()
              end
            else
              print("Rebuild failed with code:", code)
              vim.cmd("copen")
            end
          end,
        })
      else
        print("Clean failed with code:", code)
        vim.cmd("copen")
      end
    end,
  })
end

-- Helper function to clean and rebuild the project
local function clean_rebuild_project(on_success)
  local project_type = detect_project_type()
  if project_type == "cs" then
    clean_rebuild_cs_project(on_success)
  elseif project_type == "cpp" then
    clean_rebuild_cpp_project(on_success)
  else
    print("Error: Unknown project type. Cannot clean and rebuild.")
  end
end


-- General keymaps

M.general = {
  n = {
    ["<leader>rf"] = {
      rename_file,
      "Rename current file",
    },
    ["<leader>lh"] = { toggle_hebrew_mode, "Toggle Hebrew Mode" },
    ["<leader>md"] = {
      function()
        -- Run cmake build, capture output and populate quickfix list
        local output = vim.fn.systemlist("cmake --build build 2>&1")
        vim.fn.setqflist({}, ' ', {
          title = 'CMake Build',
          lines = output,
        })
        vim.cmd("copen")
      end,
      "Build project with CMake and open quickfix",
    },
  },
}

-- Add keybinding for clean and rebuild
M.general.n["<leader>cr"] = {
  function()
    clean_rebuild_project()
  end,
  "Clean and rebuild project (C# or C++)",
}


return M

