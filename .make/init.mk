# Using bash to run commands gives us a stable foundation to build upon.
SHELL := bash

# Note:
# * All Makefile variables should be 2 or more words separated by '-'.
#   Shell vars can't contain '-' so it provides a clear separation.

# This system is intended only to be used in a Git repository.
GIT-DIR := $(shell git rev-parse --git-common-dir 2>/dev/null)
GIT-DIR := $(shell [[ '$(GIT-DIR)' && '$(GIT-DIR)' == *.git && -d '$(GIT-DIR)' ]] && echo $(GIT-DIR))
ifeq (,$(GIT-DIR))
$(error Not inside a git repo)
endif
GIT-DIR := $(shell cd $(GIT-DIR) && pwd -P)
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
