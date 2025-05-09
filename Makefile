SECURSOR-VERSION := 0.1.1
CURSOR-VERSION := latest
YS-VERSION := 0.1.96

SECURSOR_ROOT ?= $(shell pwd -P)

include $(SECURSOR_ROOT)/.make/init.mk

YS := $(PREFIX)/bin/ys-$(YS-VERSION)
ifeq (,$(wildcard $(YS)))
  $(shell export PREFIX='$(PREFIX)' BIN=1 VERSION='$(YS-VERSION)' && $(SECURSOR_ROOT)/sbin/install-ys &> out)
endif

# Generate a make include file from the SECursor config files
CONFIG := $(shell TMPDIR=$(TMPDIR) $(YS) $(SECURSOR_ROOT)/sbin/secursor-config)
ifeq (,$(CONFIG))
$(error Error in SECursor config files)
endif
# This can override the CURSOR-VERSION value:
include $(CONFIG)

ROOT := $(GIT-ROOT)
TMP := $(TMPDIR)
NAME := $(shell basename $(ROOT))

C := $(CACHE)
T := $(TARGET)
N := $(NAME)
V := $(SECURSOR-VERSION)

DOCKER-IMAGE := secursor-$N:$V
VERSIONS-FILE := $C/cursor-version-history.json
VERSIONS-FILE-URL := \
  https://github.com/oslook/cursor-ai-downloads/raw/main/version-history.json
CURSOR-URL-FILE := $C/cursor-url
CURSOR-BINARY := $C/Cursor-$(CURSOR-VERSION).AppImage
BUILD-FILE := $T/secursor-build-$N
CONTAINER-NAME := secursor-$N
CONTAINER-FILE := $T/$(CONTAINER-NAME)
LOG-FILE := $(TMP)/secursor.log

APPARMOR_PROFILE ?= unconfined

ifneq (0,$(shell docker ps --format '{{.Names}}' | grep -q $(CONTAINER-NAME); echo $$?))
_ := $(shell rm -f $(CONTAINER-FILE))
endif

version:
	@echo SECursor v$(SECURSOR-VERSION)

start: $(CONTAINER-FILE)
	#
	# Starting the Cursor application for $(NAME)
	#
	xhost +local:docker
	docker exec -d -it \
	  -e USER=$(USER) \
	  -u $(USER) \
	  -w $(ROOT) \
	  $(CONTAINER-NAME) \
	  bash -c '\
	    sudo service dbus start; \
	    export XDG_RUNTIME_DIR=/run/user/$$(id -u); \
	    sudo mkdir $$XDG_RUNTIME_DIR; \
	    sudo chmod 700 $$XDG_RUNTIME_DIR; \
	    sudo chown $$(id -un):$$(id -gn) $$XDG_RUNTIME_DIR; \
	    export DBUS_SESSION_BUS_ADDRESS=unix:path=$$XDG_RUNTIME_DIR/bus; \
	    dbus-daemon --session \
	    --address=$$DBUS_SESSION_BUS_ADDRESS \
	    --nofork --nopidfile --syslog-only & \
	    cursor --no-sandbox .'

kill:
	#
	# Killing the SECursor Docker container for $(NAME)
	#
	-docker kill $(CONTAINER-NAME)
	xhost -local:docker
	$(RM) $(CONTAINER-FILE)

build: $(BUILD-FILE)

shell: $(CONTAINER-FILE)
	docker exec -it \
	  -w $(ROOT) \
	  $(CONTAINER-NAME) \
	  bash

clean:
	$(RM) $(BUILD-FILE)

realclean: kill

distclean: realclean

sysclean: distclean
	$(RM) -r $(GIT-EXT)

$(BUILD-FILE):
	#
	# Building the SECursor Docker image for $(NAME)
	#
	-docker kill $(CONTAINER-NAME)
	$(RM) $@
	docker build \
	  -f $(SECURSOR_ROOT)/Dockerfile \
	  --build-arg USER=$$USER \
	  --build-arg UID=$(USER-UID) \
	  --build-arg GID=$(USER-GID) \
	  --build-arg APT='$(APT-GET)' \
	  --tag $(DOCKER-IMAGE) \
	  .
	touch $@

$(CONTAINER-FILE): $(CURSOR-BINARY) $(BUILD-FILE)
	#
	# Starting SECursor Docker container for $(NAME)
	#
	$(RM) $@
	touch $(TMP)/.bash_history
	docker run -d --rm \
	  --device /dev/fuse \
	  --cap-add SYS_ADMIN \
	  --security-opt apparmor:$(APPARMOR_PROFILE) \
	  --hostname=SECursor \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(TMP)/.bash_history:$(HOME)/.bash_history \
	  -v $(HOME)/.config/Cursor:$(HOME)/.config/Cursor \
	  -v $(HOME)/.config/exercism:$(HOME)/.config/exercism \
	  -v $(HOME)/.cursor:$(HOME)/.cursor \
	  -v $(HOME)/.secursor:$(HOME)/.secursor \
	  -v $(ROOT):$(ROOT) \
	  -v $<:/usr/bin/cursor \
	  -e DISPLAY=$$DISPLAY \
	  --name $(CONTAINER-NAME) \
	  $(DOCKER-IMAGE) \
	  sleep infinity > $@

$(CURSOR-BINARY): $(CURSOR-URL-FILE)
	#
	# Downloading Cursor version '$(CURSOR-VERSION)' binary
	#
	curl -s $$(< $<) > $@
	chmod +x $@
	touch $@

$(CURSOR-URL-FILE): $(VERSIONS-FILE) $(YS)
	#
	# Getting the URL for Cursor version '$(CURSOR-VERSION)'
	#
	$(YS) '(_.versions.drop-while(\(_.version != "$(CURSOR-VERSION)")).first() ||| _.versions.first()).platforms.linux-x64 ||| die("Cannot find Cursor version $(CURSOR-VERSION)")' < $< > $@

$(VERSIONS-FILE):
	#
	# Downloading the Cursor version history file
	#
	curl -sL $(VERSIONS-FILE-URL) > $@

$(YS):
	#
	# Installing ys version '$(YS-VERSION)' locally in $(NAME)/.git/.ext/bin
	#
	BIN=1 VERSION=$(YS-VERSION) $(SECURSOR_ROOT)/sbin/install-ys
