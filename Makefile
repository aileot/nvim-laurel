SHELL := /usr/bin/bash
.ONESHELL:
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

FENNEL ?= fennel
VUSTED ?= vusted

REPO_ROOT:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_ROOT:=$(REPO_ROOT)/tests

TEST_DEPS:=$(TEST_ROOT)/.test-deps

FNL_TESTS:=$(wildcard tests/spec/*_spec.fnl)
LUA_TESTS:=$(FNL_TESTS:%.fnl=%.lua)

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

%_spec.lua: %_spec.fnl ## Compile fnl spec file into lua
	@$(FENNEL) \
		--correlate \
		--add-macro-path "$(REPO_MACRO_PATH)" \
		--compile $< > $@

.PHONY: clean
clean: ## Clean lua test files compiled from fnl
	@rm $(LUA_TESTS) || exit 0

.PHONY: test
test: clean $(LUA_TESTS) ## Run test
	@$(VUSTED) \
		--shuffle \
		--output=utfTerminal \
		./tests
