# Using bash to run commands gives us a stable foundation to build upon.
SHELL := bash

MAKE-ROOT := $(shell pwd -P)

# Note:
# * All Makefile variables should be 2 or more words separated by '-'.
#   Shell vars can't contain '-' so it provides a clear separation.

# This system is intended only to be used in a Git repository.
GIT-DIR := $(shell \
  dir=$$(git rev-parse --git-common-dir 2>/dev/null); \
  [[ $$dir && $$dir == *.git && -d $$dir ]] && \
  (cd "$$dir" && pwd -P))
ifeq (,$(GIT-DIR))
$(error Not inside a git repo)
endif

GIT-EXT := $(GIT-DIR)/.ext
GIT-ROOT := $(shell dirname $(GIT-DIR))

# We intend everything written to disk to be inside this repo by default.
# We cache under .git/0/ and use .git/0/tmp for /tmp/.
PREFIX := $(GIT-EXT)
CACHE  := $(GIT-EXT)/cache
TMPDIR := $(GIT-EXT)/tmp
TARGET := $(GIT-EXT)/make
ifeq (,$(wildcard $(CACHE)))
$(shell mkdir -p $(CACHE))
endif
ifeq (,$(wildcard $(TMPDIR)))
$(shell mkdir -p $(TMPDIR))
endif
ifeq (,$(wildcard $(TARGET)))
$(shell mkdir -p $(TARGET))
endif

override PATH := $(PREFIX)/bin:$(PATH)

export PATH PREFIX TMPDIR

USER-UID := $(shell id -u)
USER-GID := $(shell id -g)

# 'test' rules are always phony.
.PHONY: test

default::
