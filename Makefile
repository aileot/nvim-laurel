SHELL := bash
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

FENNEL ?= fennel
VUSTED ?= vusted

FNL_FLAGS ?= --correlate
FNL_EXTRA_FLAGS ?=

VUSTED_EXTRA_FLAGS ?=
VUSTED_FLAGS ?= --shuffle --output=utfTerminal $(VUSTED_EXTRA_FLAGS)

REPO_ROOT:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_ROOT:=$(REPO_ROOT)/test

FNL_SRC:=$(wildcard $(REPO_ROOT)/fnl/*/*.fnl)

FNL_SPECS:=$(wildcard $(TEST_ROOT)/*_spec.fnl)
LUA_SPECS:=$(FNL_SPECS:%.fnl=%.lua)

TEST_DEPS:=$(wildcard $(TEST_ROOT)/*/*)

REPO_MACRO_PATH := fnl/?.fnl;fnl/?/init.fnl

.DEFAULT_GOAL := help
.PHONY: help
help: ## Show this help
	@echo Targets:
	@egrep -h '^\S+: .*## \S+' $(MAKEFILE_LIST) | sed 's/: .*##/:/' | column -t -s ':' | sed 's/^/  /'

.PHONY: init
init: .envrc ## Setup for project contribution

.envrc: # Generate .envrc
	@echo "use flake" > .envrc

fnl/nvim-laurel/: ## Create link for backward compatibility
	@ln -dsvL "$(REPO_ROOT)/fnl/laurel" "$(REPO_ROOT)/fnl/nvim-laurel"

%_spec.lua: %_spec.fnl $(FNL_SRC) $(TEST_DEPS) # Compile fnl spec file into lua
	@$(FENNEL) \
		$(FNL_FLAGS) \
		$(FNL_EXTRA_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH);$(TEST_ROOT)/?.fnl" \
		--compile $< > $@

.PHONY: clean
clean: ## Clean lua test files compiled from fnl
	@rm -f $(LUA_SPECS)

.PHONY: test
test: $(LUA_SPECS) ## Run test
	@$(VUSTED) \
		$(VUSTED_FLAGS) \
		$(TEST_ROOT)
