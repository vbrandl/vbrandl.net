.PHONY: default clean

TARGETS = $(shell find . -type f -name '*.html')
TARGETS += $(shell find . -type f -name '*.asc')
TARGETS += $(shell find . -type f -name '*.css')
TARGETS += $(shell find . -type f -name '*.js')
TARGETS += $(shell find . -type f -name '*.txt')
TARGETS += $(shell find . -type f -name '*.xml')
TARGETS += $(shell find . -type f -name '*.svg')
TARGETS_GZ = $(patsubst %, %.gz, $(TARGETS))

CC=gzip
CFLAGS=-k -f -9

default: $(TARGETS_GZ)

%.gz : %
	$(CC) $(CFLAGS) $<

clean:
	rm -f $(TARGETS_GZ)
