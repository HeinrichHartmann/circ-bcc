#!/usr/bin/env bcc-lua

local ffi = require("ffi")
local json = require("dkjson")
local bpf_preamble = require("circll").text

ffi.cdef "unsigned int sleep(unsigned int seconds);"
  
local mods = {
  io = require("mod_iolatency"),
  runq = require("mod_runqlat"),
}

return function(BPF)
  io.stdout:write("\n") -- submit empty sample set, so we don't block nad
  io.stdout:flush()
  
  local BPF_TEXT = bpf_preamble
  for mod_name, mod in pairs(mods) do
    BPF_TEXT = BPF_TEXT .. mod.text .. "\n"
  end

  local bpf = BPF:new{ text=BPF_TEXT, debug=0 }

  for mod_name, mod in pairs(mods) do
    mod:init(bpf)
  end

  -- output
  local interval = 3
  while(true) do
    ffi.C.sleep(interval)
    local metrics = {}
    for mod_name, mod in pairs(mods) do
      metrics[mod_name] = mod:read()
    end
    io.stdout:write(json.encode(metrics))
    io.stdout:write("\n")
    io.stdout:flush()
  end
end
