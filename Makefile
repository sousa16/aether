.PHONY: all build test clean

BINARY_DIR := .
NETLINK_CTL := $(BINARY_DIR)/aether-ctl

all: build

build: netlink-controller

netlink-controller:
	go build -o $(NETLINK_CTL) ./src/cmd/netlink-controller/

test:
	sudo -E env "PATH=$(PATH)" go test -v ./src/cmd/netlink-controller/

clean:
	rm -f $(NETLINK_CTL)