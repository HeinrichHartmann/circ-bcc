#include <stdlib.h>
#include <unistd.h>
//
// Binary setuid wrapper
//
// We can't use setuid on scripts directly.
//
int main() {
  setuid(geteuid());
  putenv("LUA_PATH=/opt/circonus/circ-bcc/lua/?.lua");
  system("/opt/circonus/circ-bcc/bpf.lua");
}
