SHELL := /usr/bin/bash
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

FENNEL ?= fennel
VUSTED ?= vusted

FNL_FLAGS ?= --correlate
FNL_EXTRA_FLAGS ?=

VUSTED_FLAGS ?= --shuffle --output=utfTerminal
VUSTED_EXTRA_FLAGS ?=

REPO_ROOT:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_ROOT:=$(REPO_ROOT)/test
SPEC_ROOT:=$(TEST_ROOT)

TEST_DEPS:=$(TEST_ROOT)/.test-deps

FNL_SPECS:=$(wildcard $(SPEC_ROOT)/*_spec.fnl)
LUA_SPECS:=$(FNL_SPECS:%.fnl=%.lua)

FNL_SRC:=$(wildcard fnl/nvim-laurel/*.fnl)

REPO_FNL_DIR := $(REPO_ROOT)/fnl
REPO_FNL_PATH := $(REPO_FNL_DIR)/?.fnl;$(REPO_FNL_DIR)/?/init.fnl
REPO_MACRO_DIR := $(REPO_FNL_DIR)
REPO_MACRO_PATH := $(REPO_MACRO_DIR)/?.fnl;$(REPO_MACRO_DIR)/?/init.fnl

.DEFAULT_GOAL := help
.PHONY: help
help: ## Show this help
	@echo
	@echo 'Usage:'
	@echo '  make <target> [flags...]'
	@echo
	@echo 'Targets:'
	@egrep -h '^\S+: .*## \S+' $(MAKEFILE_LIST) | sed 's/: .*##/:/' | column -t -c 2 -s ':' | sed 's/^/  /'
	@echo

fnl/nvim-laurel/: ## Create link for backward compatibility
	@ln -dsvL "$(REPO_ROOT)/fnl/laurel" "$(REPO_ROOT)/fnl/nvim-laurel"

%_spec.lua: %_spec.fnl ## Compile fnl spec file into lua
	@$(FENNEL) \
		$(FNL_FLAGS) \
		$(FNL_EXTRA_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH);$(SPEC_ROOT)/?.fnl" \
		--compile $< > $@

.PHONY: clean
clean: ## Clean lua test files compiled from fnl
	@rm $(LUA_SPECS) || exit 0

.PHONY: test
test: $(LUA_SPECS) ## Run test
	@$(VUSTED) \
		$(VUSTED_FLAGS) \
		$(VUSTED_EXTRA_FLAGS) \
		$(TEST_ROOT)
