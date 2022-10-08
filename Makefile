SHELL := /usr/bin/bash
.ONESHELL:
# .SHELLFLAGS := -eu -o pipefail

# ifeq ($(origin .RECIPEPREFIX), undefined)
# 	$(error Please use GNU Make 4.0 or later which supports .RECIPEPREFIX)
# endif
# .RECIPEPREFIX = >
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

REPO_ROOT:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_ROOT:=$(REPO_ROOT)/tests

TEST_DEPS:=$(TEST_ROOT)/.test-deps
vusted:=$(REPO_ROOT)/lua_modules/bin/vusted

FNL_TESTS:=$(wildcard tests/fnl/*_spec.fnl)
LUA_TESTS:=$(FNL_TESTS:%.fnl=%.lua)

REPO_MACRO_DIR := $(REPO_ROOT)/fnl
REPO_MACRO_PATH := $(shell echo "$(REPO_MACRO_DIR)" | sed -e "s#.*#\0/?.fnl;\0/?/init.fnl#g")

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

# TODO: Install vusted into $(test-deps)
$(vusted): ## Install a busted wrapper for testing neovim plugin
	luarocks --lua-version=5.1 init
	luarocks --lua-version=5.1 install vusted

%.lua: %.fnl ## Compile fnl file into lua
	@fennel \
		--correlate \
		--add-macro-path "$(REPO_MACRO_PATH)" \
		--compile $< > $@

.PHONY: clean
clean: ## Clean lua test files compiled from fnl
	@rm $(LUA_TESTS) || exit 0

.PHONY: test
test: clean $(LUA_TESTS) $(vusted) ## Run test
	@RTP_DEP="$(REPO_ROOT)" \
		VUSTED_ARGS="--headless --clean -u $(TEST_ROOT)/init.lua" \
		$(vusted) \
		--shuffle \
		--output=utfTerminal \
		./tests
