local slash = require("scratch.utils").Slash()
local utils = require("scratch.utils")

---@alias mode
---| '"n"'
---| '"i"'
---| '"v"'
---
---@alias Scratch.WindowCmd
---| '"popup"'
---| '"vsplit"'
---| '"edit"'
---| '"tabedit"'
---| '"rightbelow vsplit"'

---@class Scratch.LocalKey
---@field cmd string
---@field key string
---@field modes mode[]

---@class Scratch.LocalKeyConfig
---@field filenameContains string[] as long as the filename contains any one of the string in the list
---@field LocalKeys Scratch.LocalKey[]
--
---@class Scratch.Cursor
---@field location number[]
---@field insert_mode boolean

---@class Scratch.FiletypeDetail
---@field filename? string | fun(ft: string, parentDir: string): string 
---@field requireDir? boolean -- TODO: conbine requireDir and subdir into one table
---@field subdir? string
---@field content? string[]
---@field cursor? Scratch.Cursor
--
---@class Scratch.FiletypeDetails
---@field [string] Scratch.FiletypeDetail

---@class Scratch.Config
---@field scratch_file_dir string
---@field filetypes string[]
---@field window_cmd  string
---@field file_picker? "fzflua" | "telescope" | nil
---@field filetype_details Scratch.FiletypeDetails
---@field localKeys Scratch.LocalKeyConfig[]
---@field filename? fun(ft: string, parentDir: string): string -- global filename generator function, fallback when filetype_details[ft].filename is not set
---@field hooks Scratch.Hook[]
local default_config = {
  scratch_file_dir = vim.fn.stdpath("cache") .. slash .. "scratch.nvim", -- where your scratch files will be put
  filetypes = { "lua", "js", "py", "sh" }, -- you can simply put filetype here
  window_cmd = "edit", -- 'vsplit' | 'split' | 'edit' | 'tabedit' | 'rightbelow vsplit'
  file_picker = "fzflua",
  filetype_details = {},
  localKeys = {},
  hooks = {},
}

---@type Scratch.Config
vim.g.scratch_config = default_config

---@param user_config? Scratch.Config
local function setup(user_config)
  user_config = user_config or {}

  vim.g.scratch_config = vim.tbl_deep_extend("force", default_config, user_config or {})
    or default_config
end

local function get_config()
  return vim.g.scratch_config
end

---@param ft string
---@return string
local function get_abs_path(ft)
  local config_data = vim.g.scratch_config

  local parentDir = config_data.scratch_file_dir
  local subdir = config_data.filetype_details[ft] and config_data.filetype_details[ft].subdir
  if subdir ~= nil then
    parentDir = parentDir .. slash .. subdir
  end
  vim.fn.mkdir(parentDir, "p")

  local require_dir = config_data.filetype_details[ft]
      and config_data.filetype_details[ft].requireDir
    or false

  local directory = utils.genDirectoryPath(parentDir, require_dir)

  local filename_config = config_data.filetype_details[ft] and config_data.filetype_details[ft].filename
  local filename
  if type(filename_config) == "function" then
    filename = filename_config(ft, directory)
  elseif filename_config then
    filename = filename_config
  elseif config_data.filename then
    filename = config_data.filename(ft, directory)
  else
    filename = tostring(os.date("%y-%m-%d_%H-%M-%S")) .. "." .. ft
  end

  return utils.getFilepath(filename, directory)
end

return {
  setup = setup,
  get_config = get_config,
  get_abs_path = get_abs_path,
}
