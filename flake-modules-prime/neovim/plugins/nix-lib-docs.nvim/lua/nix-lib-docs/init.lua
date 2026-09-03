local M = {}

-- In-memory cache of documentation entries: { [name] = docstring }
M._docs = {}
M._sources = {}
M._loaded_files = {}
M._base_docs_loaded = false

-- Safely decode a JSON file and merge its contents into M._docs
function M._merge_json_file(file_path)
  if not file_path or file_path == "" or vim.fn.filereadable(file_path) == 0 then
    return false
  end

  local ok, content = pcall(vim.fn.readfile, file_path)
  if not ok or not content or #content == 0 then
    return false
  end

  local json_str = table.concat(content, "\n")
  local decode_ok, decoded = pcall(vim.fn.json_decode, json_str)
  if not decode_ok or type(decoded) ~= "table" then
    return false
  end

  for k, v in pairs(decoded) do
    if type(v) == "string" then
      M._docs[k] = v
    elseif v == vim.NIL or v == nil then
      M._docs[k] = "No documentation available."
    end
  end

  M._loaded_files[file_path] = true
  return true
end

-- Load base documentation from the runtimepath (generated at build time via nixdoc)
function M.load_base_docs()
  if M._base_docs_loaded then
    return
  end
  M._base_docs_loaded = true

  local rtp_files = vim.api.nvim_get_runtime_file("data/nixpkgs-lib.json", false)
  for _, file in ipairs(rtp_files) do
    M._merge_json_file(file)
  end

  -- Backward compatibility with vim.g.noogle_extra_data
  if vim.g.noogle_extra_data and type(vim.g.noogle_extra_data) == "string" then
    local path = vim.fn.expand(vim.g.noogle_extra_data)
    M._merge_json_file(path)
  end
end

-- Register a documentation source
-- spec can contain:
--   - file: path to a pre-generated JSON docs file
--   - expr: Nix expression that evaluates to/builds a JSON docs file
--   - data: in-memory Lua table of { [name] = "docstring" }
function M.register_source(name, spec)
  if not name or not spec then
    return
  end
  M._sources[name] = spec

  if spec.data and type(spec.data) == "table" then
    for k, v in pairs(spec.data) do
      M._docs[k] = v
    end
  end

  if spec.file and type(spec.file) == "string" then
    local path = vim.fn.expand(spec.file)
    M._merge_json_file(path)
  end

  if spec.expr and type(spec.expr) == "string" then
    M._resolve_expr_async(name, spec.expr, spec.cwd)
  end
end

-- Resolves a Nix expression asynchronously using `nix build --no-link --print-out-paths --impure`
-- Caches the resulting store path locally in Neovim's cache dir for instant 0ms loads
function M._resolve_expr_async(name, expr, cwd)
  local cache_dir = vim.fn.stdpath("cache") .. "/nix-lib-docs-sources"
  vim.fn.mkdir(cache_dir, "p")
  local cache_file = cache_dir .. "/" .. name .. ".json"

  -- If a cached file exists from a previous session, load it immediately (0ms startup latency)
  if vim.fn.filereadable(cache_file) == 1 then
    M._merge_json_file(cache_file)
  end

  -- Verify or update asynchronously in background via nix build
  if vim.fn.executable("nix") == 1 then
    local sys_opts = { text = true }
    if cwd and type(cwd) == "string" and vim.fn.isdirectory(cwd) == 1 then
      sys_opts.cwd = cwd
    end

    vim.system(
      { "nix", "build", "--no-link", "--print-out-paths", "--impure", "--expr", expr },
      sys_opts,
      function(obj)
        if obj.code == 0 and obj.stdout then
          local store_path = vim.trim(obj.stdout)
          if store_path ~= "" and vim.fn.filereadable(store_path) == 1 then
            vim.schedule(function()
              M._merge_json_file(store_path)
              local ok, lines = pcall(vim.fn.readfile, store_path)
              if ok and lines then
                pcall(vim.fn.writefile, lines, cache_file)
              end
            end)
          end
        else
          if obj.stderr and obj.stderr ~= "" then
            vim.schedule(function()
              vim.notify("nix-lib-docs (" .. name .. "): " .. vim.trim(obj.stderr), vim.log.levels.WARN)
            end)
          end
        end
      end
    )
  end
end

function M.get_docs()
  if not M._base_docs_loaded then
    M.load_base_docs()
  end
  return M._docs
end

function M.open(opts)
  local picker = require("nix-lib-docs.picker")
  picker.open(opts or {})
end

return M
