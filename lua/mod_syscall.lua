local circll = require("circll")

local SYSCALLS = {
  "sys_clone",
  -- "sys_read",
}

local BPF_TEXT = [[
#include <uapi/linux/ptrace.h>

typedef struct {
  u32          id;
  circll_bin_t bin;
} syscall_dist_key_t;

BPF_HASH(syscall_start, u64, u64);
BPF_HASH(syscall_dist,  circll_bin_t, u64);

int syscall_trace_start(struct pt_regs *ctx) {
  // bpf_trace_printk("trace_start\n");
  u64 pid_tgid = bpf_get_current_pid_tgid();
  u64 t = bpf_ktime_get_ns();
  syscall_start.update(&pid_tgid, &t);
  return 0;
}

int syscall_trace_completion(struct pt_regs *ctx){
  u64 pid_tgid = bpf_get_current_pid_tgid();
  u64 *start_ns = syscall_start.lookup(&pid_tgid);
  if (!start_ns) return 0;
  u64 delta = bpf_ktime_get_ns() - *start_ns;

  // syscall_dist_key_t key;
  circll_bin_t key = circll_bin(delta, -9);
  // key.id = 1;
  u64 zero = 0;
  u64 *val;
  val = syscall_dist.lookup_or_init(&key, &zero);
  (*val)++;
  return 0;
}
]]

local function probe_text(id, name)
  return BPF_PROBE_TEMPLATE
    :gsub("$NAME",name)
    :gsub("$ID",id)
end

local function bpf_text()
  local parts = { BPF_TEXT }
  for id, name in ipairs(SYSCALLS) do
    parts[#parts + 1] = string.format("// PROBE %d : %s\n", id, name)
    parts[#parts + 1] = probe_text(id,name)
  end
  return table.concat(parts)
end

local out = {

  text = BPF_TEXT;

  init = function(self, bpf)
    bpf:attach_kprobe { event="sys_clone", fn_name="syscall_trace_start" }
    bpf:attach_kprobe { event="sys_clone", fn_name="syscall_trace_completion", retprobe = 1 }
    self.pipe = bpf:get_table("syscall_dist")
  end,

  pull = function(self)
    for k,v in self.pipe:items() do
      print(string.format("%d :: H[%.1e]=%d", 0, circll.bin(k), tonumber(v)))
    end
    circll.clear(self.pipe)
    return {}
  end
}

print(out.text)

return out
