--- Utility class to manipulate files.
--
-- @class xyz.File
-- @inherits xyz.Base
xyz.File = class('xyz.File', xyz.Base)

--- Seek constants.
--
-- These constants can be used with `seek()`.
--
-- @section seekconst
-- @compact

--- Seek from the beginning of the file.
xyz.File.static.SEEK_SET = 'set'
--- Seek from the current position.
xyz.File.static.SEEK_CUR = 'cur'
--- Seek to the end of the file.
xyz.File.static.SEEK_END = 'end'

--- Class API.
--- @section api

--- Opens a new file.
--
-- @example
--   f = xyz.File('/etc/passwd')
--   f.seek(xyz.File.SEEK_END)
--
-- @tparam string name the path to the file to open
-- @tparam string|nil mode the access mode, where `r` is read-only and `w` is read-write.
--   Nil assumes `r`.
-- @treturn xyz.File a new file object
-- @display xyz.File
function xyz.File:initialize(name, mode)
    -- ...
end

--- Seeks within the file.
--
-- @tparam seekconst|nil whence position to seek from, or nil to get current position
-- @tparam number|nil offset the number of bytes relative to `whence` to seek
-- @treturn number byte position within the file
function xyz.File:seek(whence, offset)
  -- ...
end