ifndef CURSOR_DOCKER_ROOT
  $(error CURSOR_DOCKER_ROOT not set. Try: source .../cursor-docker/.rc)
endif

include $(CURSOR_DOCKER_ROOT)/.make/init.mk

ROOT := $(GIT-ROOT)
C := $(CACHE)
T := $(TARGET)
TMP := $(TMPDIR)

YS-VERSION := 0.1.96
YS := $(PREFIX)/bin/ys-$(YS-VERSION)

DOCKER-IMAGE := cursor-image:latest
CURSOR-JSON-FILE := $C/cursor-version-history.json
CURSOR-JSON-URL := \
  https://github.com/oslook/cursor-ai-downloads/raw/main/version-history.json
CURSOR-URL-FILE := $C/cursor-url
CURSOR-APP := $C/Cursor.AppImage
CURSOR-BUILD := $T/cursor-build
CURSOR-SERVER := $T/cursor-server
CURSOR-CLIENT := $T/cursor-client
CURSOR-LOG := $(TMP)/cursor.log

CONFIG := .cursor-docker/config.yaml

CURSOR-VERSION := latest
ifneq (,$(wildcard $(CONFIG)))

  ifeq (,$(wildcard $(YS)))
    O := $(shell set -x; export PATH=$(PATH); curl -s 'https://yamlscript.org/install' | BIN=1 VERSION=$(YS-VERSION) bash)
  endif

  val := $(shell ys '.cursor.version' < $(CONFIG))
  ifneq (,$(val))
    CURSOR-VERSION := $(val)
  endif

  val := $(shell ys '.apt-get' < $(CONFIG))
  ifneq (,$(val))
    APT-GET := $(val)
  endif
endif

cursor: $(CURSOR-CLIENT)

build: $(CURSOR-BUILD)

shell: server
	docker exec -it \
	  -w $(ROOT) \
	  cursor-server \
	  bash

server: $(CURSOR-SERVER)

stop:
	-docker kill cursor-client
	$(RM) $(CURSOR-CLIENT)

stop-server: stop
	xhost -local:docker
	-docker kill cursor-server
	$(RM) $(CURSOR-SERVER)

clean:
	$(RM) $(CURSOR-BUILD)

realclean: stop-server

distclean: realclean
	$(RM) -r $(CACHE)

$(CURSOR-BUILD):
	-docker kill cursor-server
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

$(CURSOR-SERVER): $(CURSOR-APP) $(CURSOR-BUILD)
	$(RM) $@
	touch $(TMP)/.bash_history
	docker run -d --rm \
	  --device /dev/fuse \
	  --privileged \
	  --hostname=cursor-docker \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(TMP)/.bash_history:$(HOME)/.bash_history \
	  -v $(HOME)/.config:$(HOME)/.config \
	  -v $(HOME)/.cursor:$(HOME)/.cursor \
	  -v $(ROOT):$(ROOT) \
	  -v $<:/usr/bin/cursor \
	  -e DISPLAY=$$DISPLAY \
	  --name cursor-server \
	  $(DOCKER-IMAGE) \
	  sleep 999999999 > $@

$(CURSOR-CLIENT): $(CURSOR-SERVER)
	xhost +local:docker
	docker exec -d -it \
	  -e USER=$(USER) \
	  -u $(USER) \
	  -w $(ROOT) \
	  cursor-server \
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

$(CURSOR-APP): $(CURSOR-URL-FILE)
	curl -s $$(< $<) > $@
	chmod +x $@
	touch $@

$(CURSOR-URL-FILE): $(CURSOR-JSON-FILE) $(YS)
	ys '(_.versions.drop-while(\(_.version != "$(CURSOR-VERSION)")).first() ||| _.versions.first()).platforms.linux-x64 ||| die("Cannot find Cursor version $(CURSOR-VERSION)")' < $< > $@

$(CURSOR-JSON-FILE):
	curl -sL $(CURSOR-JSON-URL) > $@

$(YS):
	curl -s https://yamlscript.org/install | \
	  BIN=1 VERSION=$(YS-VERSION) bash
