include ./Makefile.inc

RUST_DEBUG_BIN_DIR=./target/debug
RUST_RELEASE_BIN_DIR=./target/release
VARLINK_SRV_EXEC=npd
VARLINK_SRV_EXEC_DEBUG=$(RUST_DEBUG_BIN_DIR)/$(VARLINK_SRV_EXEC)
VARLINK_SRV_EXEC_RELEASE=$(RUST_RELEASE_BIN_DIR)/$(VARLINK_SRV_EXEC)
CLI_EXEC=npc
CLI_EXEC_DEBUG=$(RUST_DEBUG_BIN_DIR)/$(CLI_EXEC)
CLIB_HEADER=nispor.h
CLIB_HEADER_IN=src/clib/$(CLIB_HEADER).in
CLIB_SO_DEV_RELEASE=$(RUST_RELEASE_BIN_DIR)/$(CLIB_SO_DEV)
CLIB_PKG_CONFIG_FILE=nispor.pc
CLIB_PKG_CONFIG_FILE_IN=src/clib/$(CLIB_PKG_CONFIG_FILE).in
PYTHON_MODULE_NAME=nispor
PYTHON_MODULE_SRC=src/python/nispor
CLI_EXEC_RELEASE=$(RUST_RELEASE_BIN_DIR)/$(CLI_EXEC)
SOCKET_FILE=/run/nispor/nispor.so
SOCKET_DIR=$(dir $(SOCKET_FILE))
SOCKET_ADDR=unix:$(SOCKET_FILE)
SYSTEMD_SERVICE_FILE=src/varlink/systemd/nispor.service
SYSTEMD_SOCKET_FILE=src/varlink/systemd/nispor.socket
PREFIX ?= /usr/local

CPU_BITS = $(shell getconf LONG_BIT)
ifeq ($(CPU_BITS), 32)
    LIBDIR ?= $(PREFIX)/lib
else
    LIBDIR ?= $(PREFIX)/lib$(CPU_BITS)
endif

INCLUDE_DIR ?= $(PREFIX)/include
PKG_CONFIG_LIBDIR ?= $(LIBDIR)/pkgconfig

SKIP_PYTHON_INSTALL ?=0

all: $(VARLINK_SRV_EXEC_DEBUG) $(CLI_EXEC_DEBUG) \
    $(VARLINK_SRV_EXEC_RELEASE) $(CLI_EXEC_RELEASE)

SYSTEMD_SYS_UNIT_DIR ?= $(shell \
	pkg-config --variable=systemdsystemunitdir systemd)

PYTHON3_SITE_DIR ?=$(shell \
	python3 -c \
		"from distutils.sysconfig import get_python_lib; \
		 print(get_python_lib())")

# Always invoke cargo build for debug
.PHONY: $(VARLINK_SRV_EXEC_DEBUG) $(CLI_EXEC_DEBUG)

debug: $(CLI_EXEC_DEBUG)
	$(CLI_EXEC_DEBUG) $(ARGS)


$(CLI_EXEC_DEBUG) $(VARLINK_SRV_EXEC_DEBUG):
	cargo build --all

$(CLI_EXEC_RELEASE) $(VARLINK_SRV_EXEC_RELEASE) $(CLIB_SO_DEV_RELEASE):
	cargo build --all --release

check:
	cargo test -- --test-threads=1 --show-output
	make check -C test/clib

srv: $(VARLINK_SRV_EXEC_DEBUG)
	echo $(SOCKET_DIR)
	if [ ! -d $(SOCKET_DIR) ]; then \
		sudo mkdir $(SOCKET_DIR); \
		sudo chmod 0777 $(SOCKET_DIR); \
	fi
	$(VARLINK_SRV_EXEC_DEBUG) $(SOCKET_ADDR)

cli:
	varlink call $(SOCKET_ADDR)/info.nispor.Get

clean:
	cargo clean
	make clean -C test/clib

install: $(VARLINK_SRV_EXEC_RELEASE) $(CLI_EXEC_RELEASE)
	install -p -v -D -m755 $(VARLINK_SRV_EXEC_RELEASE) \
		$(DESTDIR)$(PREFIX)/bin/$(VARLINK_SRV_EXEC)
	install -p -v -D -m755 $(CLI_EXEC_RELEASE) \
		$(DESTDIR)$(PREFIX)/bin/$(CLI_EXEC)
	install -p -v -D -m644 $(SYSTEMD_SOCKET_FILE) \
		$(DESTDIR)$(SYSTEMD_SYS_UNIT_DIR)/nispor.socket
	install -p -D -m644 $(SYSTEMD_SERVICE_FILE) \
		$(DESTDIR)$(SYSTEMD_SYS_UNIT_DIR)/nispor.service
	install -p -D -m755 $(CLIB_SO_DEV_RELEASE) \
		$(DESTDIR)$(LIBDIR)/$(CLIB_SO_FULL)
	ln -sfv $(CLIB_SO_FULL) $(DESTDIR)$(LIBDIR)/$(CLIB_SO_MAN)
	ln -sfv $(CLIB_SO_FULL) $(DESTDIR)$(LIBDIR)/$(CLIB_SO_DEV)
	if [ $(SKIP_PYTHON_INSTALL) != 1 ];then \
	    install -p -v -D -d -m755 $(PYTHON_MODULE_SRC) \
		    $(DESTDIR)$(PYTHON3_SITE_DIR)/$(PYTHON_MODULE_NAME); \
	    install -p -v -D -m644 $(PYTHON_MODULE_SRC)/*.py \
		    $(DESTDIR)$(PYTHON3_SITE_DIR)/$(PYTHON_MODULE_NAME)/; \
	fi
	install -p -v -D -m644 $(CLIB_HEADER_IN) \
		$(DESTDIR)$(INCLUDE_DIR)/$(CLIB_HEADER)
	sed -i -e 's/@_VERSION_MAJOR@/$(CLIB_VERSION_MAJOR)/' \
		$(DESTDIR)$(INCLUDE_DIR)/$(CLIB_HEADER)
	sed -i -e 's/@_VERSION_MINOR@/$(CLIB_VERSION_MINOR)/' \
		$(DESTDIR)$(INCLUDE_DIR)/$(CLIB_HEADER)
	sed -i -e 's/@_VERSION_MICRO@/$(CLIB_VERSION_MICRO)/' \
		$(DESTDIR)$(INCLUDE_DIR)/$(CLIB_HEADER)
	install -p -v -D -m644 $(CLIB_PKG_CONFIG_FILE_IN) \
		$(DESTDIR)$(PKG_CONFIG_LIBDIR)/$(CLIB_PKG_CONFIG_FILE)
	sed -i -e 's/@VERSION@/$(CLIB_VERSION)/' \
		$(DESTDIR)$(PKG_CONFIG_LIBDIR)/$(CLIB_PKG_CONFIG_FILE)
	sed -i -e 's/@PREFIX@/$(subst /,\/,$(PREFIX))/' \
		$(DESTDIR)$(PKG_CONFIG_LIBDIR)/$(CLIB_PKG_CONFIG_FILE)
	sed -i -e 's/@LIBDIR@/$(subst /,\/,$(LIBDIR))/' \
		$(DESTDIR)$(PKG_CONFIG_LIBDIR)/$(CLIB_PKG_CONFIG_FILE)
	sed -i -e 's/@INCLUDE_DIR@/$(subst /,\/,$(INCLUDE_DIR))/' \
		$(DESTDIR)$(PKG_CONFIG_LIBDIR)/$(CLIB_PKG_CONFIG_FILE)


uninstall:
	- rm -fv $(DESTDIR)$(PREFIX)/bin/$(VARLINK_SRV_EXEC)
	- rm -fv $(DESTDIR)$(PREFIX)/bin/$(CLI_EXEC)
	- rm -fv $(DESTDIR)$(SYSTEMD_SYS_UNIT_DIR)/nispor*
	- rm -fv $(DESTDIR)$(LIBDIR)/$(CLIB_SO_DEV)
	- rm -fv $(DESTDIR)$(LIBDIR)/$(CLIB_SO_MAN)
	- rm -fv $(DESTDIR)$(LIBDIR)/$(CLIB_SO_MIN)
	- rm -fv $(DESTDIR)$(LIBDIR)/$(CLIB_SO_FULL)
	- rm -fv $(DESTDIR)$(INCLUDE_DIR)/$(CLIB_HEADER)
	- if [ $(SKIP_PYTHON_INSTALL) != 1 ];then \
		rm -rfv $(DESTDIR)$(PYTHON3_SITE_DIR)/$(PYTHON_MODULE_NAME); \
	fi
