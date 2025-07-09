# Using the "Makes" Makefile setup - https://github.com/makeplus/makes
M := $(or $(MAKES_REPO_DIR),.cache/makes)
$(shell [ -d $M ] || git clone -q https://github.com/makeplus/makes $M)
include $M/init.mk
include $M/clean.mk

CURSOR-VERSION ?= 0.50.1
include $M/cursor.mk

SECURSOR-VERSION ?= 0.1.1
SECURSOR_ROOT ?= $(ROOT)

# Generate a make-include-file from the SECursor config files:
CONFIG := \
  $(shell TMPDIR=$(LOCAL-TMP) $(SECURSOR_ROOT)/sbin/secursor-config)
ifeq (,$(CONFIG))
  $(error Error in SECursor config files)
endif
# This can override the CURSOR-DOWNLOAD value:
include $(CONFIG)

REPO := $(ROOT)
TMP := $(LOCAL-TMP)
NAME := $(shell basename $(REPO))
TARGET := $(LOCAL-ROOT)/target
$(shell mkdir -p $(TARGET))

C := $(LOCAL-CACHE)
T := $(TARGET)
N := $(NAME)
V := $(SECURSOR-VERSION)

DOCKER-IMAGE := ingy/secursor-$N:$V
BUILD-FILE := $T/secursor-build-$N
CONTAINER-NAME := secursor-$N
CONTAINER-FILE := $T/$(CONTAINER-NAME)

APPARMOR_PROFILE ?= unconfined

# If container not running, remove the file that says that it is running:
ifeq (,$(shell docker ps --format '{{.Names}}' | grep $(CONTAINER-NAME)))
$(shell $(RM) $(CONTAINER-FILE))
endif

# Print SECursor version
version:
	@echo SECursor v$(SECURSOR-VERSION)

# Start the cursor app
start: $(CONTAINER-FILE)
	#
	# Starting the Cursor application for $(NAME)
	#
	xhost +local:docker
	docker exec -d -it \
	  -e USER=$(USER) \
	  -u $(USER) \
	  -w $(REPO) \
	  $(CONTAINER-NAME) \
	  cursor --no-sandbox .

# Kill the app server container
kill:
	#
	# Killing the SECursor Docker container for $(NAME)
	#
	-docker kill $(CONTAINER-NAME)
	xhost -local:docker
	$(RM) $(CONTAINER-FILE)

rmi: kill
	docker rmi $(DOCKER-IMAGE)
	$(RM) $(BUILD-FILE)

# Build the custom container image for this repo
build: $(BUILD-FILE)

publish:
	docker push $(DOCKER-IMAGE)

# Start a Bash shell in the app server container
shell:
	docker exec -it \
	  -w $(REPO) \
	  $(CONTAINER-NAME) \
	  bash --rcfile /tmp/rcfile


status:
	-docker ps | grep $(CONTAINER-NAME)
	@echo
	-docker images | grep $(CONTAINER-NAME)
	@echo

status-all:
	-docker ps | grep secursor
	@echo
	-docker images | grep secursor
	@echo

clean::
	$(RM) $(BUILD-FILE)

realclean:: kill


$(BUILD-FILE): $(SECURSOR_ROOT)/Dockerfile
	#
	# Building the SECursor Docker image for $(NAME)
	#
	-docker kill $(CONTAINER-NAME)
	$(RM) $@
	docker build \
	  -f $< \
	  --build-arg USER=$$USER \
	  --build-arg UID=$(USER-UID) \
	  --build-arg GID=$(USER-GID) \
	  --build-arg APT='$(APT-INSTALL)' \
	  --build-arg URL=$(CURSOR-DOWNLOAD) \
	  --build-arg DATE="$(shell date)" \
	  --tag $(DOCKER-IMAGE) \
	  .
	touch $@

$(CONTAINER-FILE): $(BUILD-FILE)
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
	  -v $(HOME)/.cursor:$(HOME)/.cursor \
	  -v $(HOME)/.secursor:$(HOME)/.secursor \
	  -v $(REPO):$(REPO) \
	  -e DISPLAY=$$DISPLAY \
	  --name $(CONTAINER-NAME) \
	  $(DOCKER-IMAGE) \
	  sleep infinity > $@
