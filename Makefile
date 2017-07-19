all:
	gcc nad-plugin.c -o nad-plugin.elf

install: all
	chown root:root nad-plugin.elf
	mkdir -p /opt/circonus/circ-bcc
	rsync -av . /opt/circonus/circ-bcc
	chmod +s /opt/circonus/circ-bcc/nad-plugin.elf
