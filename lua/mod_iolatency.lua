--
-- iolatency
--
-- based on biolatency.py
--
-- Metric 'sd' contains comulative statistics for all block devices
--

local ffi = require("ffi")
local circll = require("circll")

return {
  text = [[
#include <uapi/linux/ptrace.h>
#include <linux/blkdev.h>

typedef struct disk_key {
    char disk[DISK_NAME_LEN];
    u64 slot;
} disk_key_t;

BPF_HASH(iolat_start, struct request *);
BPF_HASH(iolat_dist, disk_key_t);

// time block I/O
int trace_req_iolat_start(struct pt_regs *ctx, struct request *req) {
    u64 ts = bpf_ktime_get_ns();
    iolat_start.update(&req, &ts);
    return 0;
}

// output
int trace_req_completion(struct pt_regs *ctx, struct request *req) {
    u64 *old, *tsp, delta, zero = 0;

    // fetch timestamp and calculate delta
    tsp = iolat_start.lookup(&req);
    if (tsp == 0) {
        return 0;   // missed issue
    }
    delta = bpf_ktime_get_ns() - *tsp;
    delta /= 1000;

    // store as histogram
    disk_key_t key = {.slot = circll_slot(delta)};
    bpf_probe_read(&key.disk, sizeof(key.disk), req->rq_disk->disk_name); // read name
    old = iolat_dist.lookup_or_init(&key, &zero);
    (*old)++;
    memcpy(key.disk, "sd", 3);
    old = iolat_dist.lookup_or_init(&key, &zero);
    (*old)++;
    iolat_start.delete(&req);
    return 0;
}
]],

  init = function(self, bpf)
    bpf:attach_kprobe{event="blk_start_request", fn_name="trace_req_iolat_start"}
    bpf:attach_kprobe{event="blk_mq_start_request", fn_name="trace_req_iolat_start"}
    bpf:attach_kprobe{event="blk_account_io_completion", fn_name="trace_req_completion"}
    self.pipe = bpf:get_table("iolat_dist")
  end,

  read = function(self)
    local metrics = {}
    for k, v in self.pipe:items() do
      local disk = ffi.string(k.disk)
      if disk ~= "" then
        metrics[disk] = metrics[disk] or circll.hist()
        metrics[disk]:add(k.slot, v)
      end
      circll.clear(self.pipe)
    end
    return metrics
  end,
}
