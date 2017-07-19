#!/usr/bin/env bcc-lua

local ffi = require("ffi")
local json = require("dkjson")
local bpf_preamble = require("circll").text

local mods = {
  io = require("mod_iolatency"),
  runq = require("mod_runqlat"),
}
local INTERVAL = tonumber(arg[1]) or 60

ffi.cdef "unsigned int sleep(unsigned int seconds);"

local function submit_nad(metrics)
  io.stdout:write(json.encode(metrics))
  io.stdout:write("\n\n")
  io.stdout:flush()
end

return function(BPF)
  io.stdout:write("{}\n") -- submit empty sample set, so we don't block nad
  io.stdout:write("\n") -- extra blank line to finalize metric set
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
  while(true) do
    ffi.C.sleep(INTERVAL)
    local metrics = {}
    for mod_name, mod in pairs(mods) do
      for metric_name, val in pairs(mod:read()) do
        metrics[mod_name .. '`' .. metric_name] = val
      end
    end
    submit_nad(metrics)
  end
end
