all:
	gcc nad-plugin.c -o nad-plugin.elf

install: all
	chown root:root nad-plugin.elf
	mkdir -p /opt/circonus/circ-bcc
	rsync -av . /opt/circonus/circ-bcc
	chmod +s /opt/circonus/circ-bcc/nad-plugin.elf

install-nad: install
	ln -s -f /opt/circonus/circ-bcc/nad-plugin.elf /opt/circonus/nad/etc/node-agent.d/bpf.elf
