ifndef CURSOR_DOCKER_ROOT
  $(error CURSOR_DOCKER_ROOT not set. Try: source .../cursor-docker/.rc)
endif

include $(CURSOR_DOCKER_ROOT)/.make/init.mk

CURSOR-DOCKER-VERSION := 0.1.0
V := $(CURSOR-DOCKER-VERSION)

CURSOR-VERSION := latest

CONFIG := $(shell TMPDIR=$(TMPDIR) $$CURSOR_DOCKER_ROOT/bin/cursor-docker-config)
ifeq (,$(CONFIG))
$(error Error in cursor-docker config files)
endif
include $(CONFIG)

ROOT := $(GIT-ROOT)
C := $(CACHE)
T := $(TARGET)
TMP := $(TMPDIR)
NAME := $(shell basename $(ROOT))
N := $(NAME)

YS-VERSION := 0.1.96
YS := $(PREFIX)/bin/ys-$(YS-VERSION)

DOCKER-IMAGE := cursor-image-$N:$V
VERSIONS-FILE := $C/cursor-version-history.json
VERSIONS-FILE-URL := \
  https://github.com/oslook/cursor-ai-downloads/raw/main/version-history.json
CURSOR-URL-FILE := $C/cursor-url
CURSOR-BINARY := $C/Cursor-$(CURSOR-VERSION).AppImage
BUILD-FILE := $T/cursor-build-$N
CONTAINER-NAME := cursor-docker-$N
CONTAINER-FILE := $T/$(CONTAINER-NAME)
CURSOR-FILE := $T/cursor-client-$N
LOG-FILE := $(TMP)/cursor.log

APPARMOR_PROFILE ?= unconfined

ifneq (0,$(shell docker ps --format '{{.Names}}' | grep -q $(CONTAINER-NAME); echo $$?))
_ := $(shell rm -f $(CURSOR-FILE) $(CONTAINER-FILE))
endif

version:
	@echo cursor-docker v$(CURSOR-DOCKER-VERSION)

start: $(CURSOR-FILE)

stop:
	-docker kill $(CONTAINER-NAME)
	xhost -local:docker
	$(RM) $(CURSOR-FILE) $(CONTAINER-FILE)

build: $(BUILD-FILE)

shell: $(CONTAINER-FILE)
	docker exec -it \
	  -w $(ROOT) \
	  $(CONTAINER-NAME) \
	  bash

clean:
	$(RM) $(BUILD-FILE)

realclean: stop-container

distclean: realclean
	$(RM) -r $(GIT-EXT)

$(BUILD-FILE):
	-docker kill $(CONTAINER-NAME)
	$(RM) $@
	docker build \
	  -f $(CURSOR_DOCKER_ROOT)/Dockerfile \
	  --build-arg USER=$$USER \
	  --build-arg UID=$(USER-UID) \
	  --build-arg GID=$(USER-GID) \
	  --build-arg APT='$(APT-GET)' \
	  --tag $(DOCKER-IMAGE) \
	  .
	touch $@

$(CONTAINER-FILE): $(CURSOR-BINARY) $(BUILD-FILE)
	$(RM) $@
	touch $(TMP)/.bash_history
	docker run -d --rm \
	  --device /dev/fuse \
	  --cap-add SYS_ADMIN \
	  --security-opt apparmor:$(APPARMOR_PROFILE) \
	  --hostname=cursor-docker \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(TMP)/.bash_history:$(HOME)/.bash_history \
	  -v $(HOME)/.config:$(HOME)/.config \
	  -v $(HOME)/.cursor:$(HOME)/.cursor \
	  -v $(HOME)/.cursor-docker:$(HOME)/.cursor-docker \
	  -v $(ROOT):$(ROOT) \
	  -v $<:/usr/bin/cursor \
	  -e DISPLAY=$$DISPLAY \
	  --name $(CONTAINER-NAME) \
	  $(DOCKER-IMAGE) \
	  sleep infinity > $@

$(CURSOR-FILE): $(CONTAINER-FILE)
	$(RM) $@
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
	touch $@

$(CURSOR-BINARY): $(CURSOR-URL-FILE)
	curl -s $$(< $<) > $@
	chmod +x $@
	touch $@

define get-cursor
endef

$(CURSOR-URL-FILE): $(VERSIONS-FILE) $(YS)
	ys '(_.versions.drop-while(\(_.version != "$(CURSOR-VERSION)")).first() ||| _.versions.first()).platforms.linux-x64 ||| die("Cannot find Cursor version $(CURSOR-VERSION)")' < $< > $@

$(VERSIONS-FILE):
	curl -sL $(VERSIONS-FILE-URL) > $@

$(YS):
	curl -s https://yamlscript.org/install | \
	  BIN=1 VERSION=$(YS-VERSION) bash
