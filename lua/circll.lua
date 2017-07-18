--
-- BPF circllhist helper
--
local bit = require("bit")
local xff = bit.tobit(0xff)

return {
  text = [[
#define LLN() if(v > 100) { exp++; v /= 10; } else goto good;
#define LLN2() LLN() LLN()
#define LLN4() LLN2() LLN2()
#define LLN8() LLN4() LLN4()
#define LLN16() LLN8() LLN8()
#define LLN32() LLN16() LLN16()
#define LLN64() LLN32() LLN32()
#define LLN128() LLN64() LLN64()

static unsigned int circll_slot(unsigned long v) {
  int exp = 1;
  if(v == 0) return 0;
  if(v < 10) return (v*10 << 8) | exp;
  LLN128()
  if(v > 100) return 0xff00;
 good:
  return (v << 8) | (exp & 0xff);
}
]],
  bin = function(slot)
    local slot_hi = bit.band(xff, bit.rshift(bit.tobit(tonumber(slot)), 8))
    local slot_lo = bit.band(xff, bit.tobit(tonumber(slot)))
    return slot_hi * 10.0 ^ (slot_lo - 1)
  end

}
