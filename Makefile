SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.RECIPEPREFIX := >
.ONESHELL:
.DEFAULT_GOAL := help

PYTHON ?= python3.11
UV ?= uv
UV_EXE := $(shell command -v $(UV) 2>/dev/null || true)
NPM ?= npm
PORT ?= 8000
HOST ?= 127.0.0.1

VENV ?= .venv
VENV_DIR := $(abspath $(VENV))
VENV_BIN := $(VENV_DIR)/bin
VENV_PYTHON := $(VENV_BIN)/python

AGENT_GENERATOR_REPO ?= https://github.com/ruslanmv/agent-generator.git
AGENT_GENERATOR_DIR ?= .tools/agent-generator

MATRIX_DESIGNER_REPO ?= https://github.com/agent-matrix/matrix-designer.git
MATRIX_DESIGNER_DIR ?= .tools/matrix-designer

MATRIX_BUILDER_REPO ?= https://github.com/agent-matrix/matrix-builder.git
MATRIX_BUILDER_DIR ?= .tools/matrix-builder

GOVERNED_REQUIRED_CMDS ?= mdesign mb gitpilot

export PYTHONNOUSERSITE := 1
export UV_LINK_MODE := copy

.PHONY: help install install-node install-venv install-governed-tools build verify smoke design generate run clean clean-venv normalize-eol

help:
> echo "Contract Quest workflow targets"
> echo ""
> echo "  make install                Create .venv with uv, install npm + governed Python tools"
> echo "  make build                  Run strict from-zero governed generation"
> echo "  make verify                 Run ./build.sh verify"
> echo "  make smoke                  Run npm smoke script"
> echo "  make design                 Run ./build.sh design"
> echo "  make generate               Run ./build.sh from-zero"
> echo "  make run [PORT=8000]        Serve frontend locally"
> echo "  make clean                  Remove workflow caches"
> echo "  make clean-venv             Remove .venv"
> echo ""
> echo "Required watsonx env before build/generate:"
> echo "  GITPILOT_PROVIDER=watsonx"
> echo "  WATSONX_API_KEY=..."
> echo "  WATSONX_PROJECT_ID=..."
> echo "  WATSONX_URL=https://us-south.ml.cloud.ibm.com"
> echo "  GITPILOT_WATSONX_MODEL=openai/gpt-oss-120b"
> echo ""
> echo "This Makefile uses uv + .venv and disables user site packages with PYTHONNOUSERSITE=1."
> echo "Default Python is $(PYTHON). GitPilot requires Python 3.11 or 3.12, not Python 3.13."

install: install-node install-governed-tools

install-node:
> echo "==> Installing npm dependencies"
> if [ -f package-lock.json ]; then
>   $(NPM) install
> else
>   $(NPM) install --package-lock=false
> fi

install-venv:
> echo "==> Creating isolated Python virtual environment with uv"
> if [ -z "$(UV_EXE)" ]; then
>   echo "ERROR: uv is not installed or not on PATH."
>   echo "Install uv first, then rerun make install."
>   echo "Recommended:"
>   echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
>   exit 1
> fi
> if ! command -v "$(PYTHON)" >/dev/null 2>&1; then
>   echo "ERROR: $(PYTHON) was not found."
>   echo "Install Python 3.11 or run:"
>   echo "  make install PYTHON=python3.12"
>   exit 1
> fi
> echo "==> External uv: $(UV_EXE)"
> echo "==> Requested Python: $(PYTHON)"
> rm -rf "$(VENV_DIR)"
> "$(UV_EXE)" venv "$(VENV_DIR)" --python "$(PYTHON)"
> echo "==> Using Python:"
> "$(VENV_PYTHON)" --version
> echo "==> Verifying .venv isolation"
> "$(VENV_PYTHON)" -c 'import sys, site; print("python:", sys.executable); print("usersite enabled:", site.ENABLE_USER_SITE)'
> echo "==> Upgrading base packaging tools in .venv"
> "$(UV_EXE)" pip install --python "$(VENV_PYTHON)" --upgrade pip setuptools wheel

install-governed-tools: install-venv
> echo "==> Installing governed workflow Python tools into .venv"
> echo "    Agent Generator repo: $(AGENT_GENERATOR_REPO)"
> echo "    Matrix Designer repo: $(MATRIX_DESIGNER_REPO)"
> echo "    Matrix Builder repo: $(MATRIX_BUILDER_REPO)"
> echo "    Required commands after install: $(GOVERNED_REQUIRED_CMDS)"
> export PATH="$(VENV_BIN):$$PATH"
> status=0
> echo "==> Removing conflicting standalone/global packages from .venv"
> "$(UV_EXE)" pip uninstall --python "$(VENV_PYTHON)" gitpilot agent-generator matrix-builder matrix-designer -y >/dev/null 2>&1 || true
> echo "==> Installing base governed packages with LiteLLM/watsonx support"
> "$(UV_EXE)" pip install --python "$(VENV_PYTHON)" --upgrade \
>   gitcopilot \
>   "crewai[litellm]" \
>   litellm \
>   tokenizers \
>   ibm-watsonx-ai \
>   langchain-ibm \
>   python-dotenv \
>   rich \
>   typer || status=$$?
> echo "==> Installing Agent Generator"
> if [ -d "$(AGENT_GENERATOR_DIR)/.git" ]; then
>   echo "==> Updating Agent Generator checkout"
>   git -C "$(AGENT_GENERATOR_DIR)" pull --ff-only || status=$$?
> else
>   echo "==> Cloning Agent Generator"
>   rm -rf "$(AGENT_GENERATOR_DIR)"
>   mkdir -p "$$(dirname "$(AGENT_GENERATOR_DIR)")"
>   git clone "$(AGENT_GENERATOR_REPO)" "$(AGENT_GENERATOR_DIR)" || status=$$?
> fi
> if [ -d "$(AGENT_GENERATOR_DIR)" ]; then
>   "$(UV_EXE)" pip install --python "$(VENV_PYTHON)" --upgrade -e "$(AGENT_GENERATOR_DIR)" || status=$$?
> fi
> echo "==> Installing Matrix Designer"
> if [ -d "$(MATRIX_DESIGNER_DIR)/.git" ]; then
>   echo "==> Updating Matrix Designer checkout"
>   git -C "$(MATRIX_DESIGNER_DIR)" pull --ff-only || status=$$?
> else
>   echo "==> Cloning Matrix Designer"
>   rm -rf "$(MATRIX_DESIGNER_DIR)"
>   mkdir -p "$$(dirname "$(MATRIX_DESIGNER_DIR)")"
>   git clone "$(MATRIX_DESIGNER_REPO)" "$(MATRIX_DESIGNER_DIR)" || status=$$?
> fi
# Non-editable on purpose: matrix-designer uses a src/ layout, and an editable
# install can leave the `mdesign` entry point present while `matrix_designer`
# stays unimportable (ModuleNotFoundError at build time). A regular install
# copies the package into site-packages and is self-contained.
> if [ -d "$(MATRIX_DESIGNER_DIR)" ]; then
>   "$(UV_EXE)" pip install --python "$(VENV_PYTHON)" --upgrade "$(MATRIX_DESIGNER_DIR)" || status=$$?
> fi
> echo "==> Installing Matrix Builder"
> if [ -d "$(MATRIX_BUILDER_DIR)/.git" ]; then
>   echo "==> Updating Matrix Builder checkout"
>   git -C "$(MATRIX_BUILDER_DIR)" pull --ff-only || status=$$?
> else
>   echo "==> Cloning Matrix Builder"
>   rm -rf "$(MATRIX_BUILDER_DIR)"
>   mkdir -p "$$(dirname "$(MATRIX_BUILDER_DIR)")"
>   git clone "$(MATRIX_BUILDER_REPO)" "$(MATRIX_BUILDER_DIR)" || status=$$?
> fi
> if [ -d "$(MATRIX_BUILDER_DIR)" ]; then
>   "$(UV_EXE)" pip install --python "$(VENV_PYTHON)" --upgrade "$(MATRIX_BUILDER_DIR)" || status=$$?
> fi
> echo "==> Verifying Python imports inside .venv"
> "$(VENV_PYTHON)" -c 'import sys, importlib; print("python:", sys.executable); mods=["crewai","litellm","tokenizers","ibm_watsonx_ai","langchain_ibm","agent_generator","matrix_designer"]; [importlib.import_module(m) for m in mods]; import agent_generator.mb; from tokenizers import Tokenizer; [print("ok: "+m) for m in mods]; print("ok: agent_generator.mb"); print("ok: tokenizers.Tokenizer")' || status=$$?
> echo "==> Verifying governed commands from .venv"
> for cmd in $(GOVERNED_REQUIRED_CMDS); do
>   command -v "$$cmd" >/dev/null 2>&1 || { echo "WARNING: required governed command not found: $$cmd"; status=1; }
> done
> echo "==> Verifying mb comes from .venv"
> mb_path="$$(command -v mb || true)"
> echo "mb path: $$mb_path"
> case "$$mb_path" in
>   "$(VENV_BIN)"/*)
>     echo "ok: mb is isolated in .venv"
>     ;;
>   *)
>     echo "ERROR: mb is not coming from .venv."
>     echo "       Found: $$mb_path"
>     echo "       Expected: $(VENV_BIN)/mb"
>     status=1
>     ;;
> esac
> echo "==> Verifying mdesign comes from .venv"
> mdesign_path="$$(command -v mdesign || true)"
> echo "mdesign path: $$mdesign_path"
> case "$$mdesign_path" in
>   "$(VENV_BIN)"/*)
>     echo "ok: mdesign is isolated in .venv"
>     ;;
>   *)
>     echo "ERROR: mdesign is not coming from .venv."
>     echo "       Found: $$mdesign_path"
>     echo "       Expected: $(VENV_BIN)/mdesign"
>     status=1
>     ;;
> esac
> echo "==> Verifying gitpilot comes from .venv"
> gitpilot_path="$$(command -v gitpilot || true)"
> echo "gitpilot path: $$gitpilot_path"
> case "$$gitpilot_path" in
>   "$(VENV_BIN)"/*)
>     echo "ok: gitpilot is isolated in .venv"
>     ;;
>   *)
>     echo "ERROR: gitpilot is not coming from .venv."
>     echo "       Found: $$gitpilot_path"
>     echo "       Expected: $(VENV_BIN)/gitpilot"
>     status=1
>     ;;
> esac
> if command -v gitpilot >/dev/null 2>&1; then
>   echo "==> GitPilot CLI check"
>   gitpilot --help >/dev/null 2>&1 || status=$$?
>   if gitpilot generate --help >/dev/null 2>&1; then
>     echo "ok: gitpilot generate available"
>   else
>     echo "WARNING: gitpilot generate is not available. Install your local-generate GitPilot build."
>     status=1
>   fi
> fi
> if [ "$$status" -ne 0 ]; then
>   echo "ERROR: governed Python tools could not be fully installed into .venv."
>   echo "       Fix the messages above, then run:"
>   echo "       make install"
>   exit "$$status"
> fi
> echo "==> Governed Python tools installed successfully into .venv"

# Strip any CRLF from build.sh so a Windows/WSL checkout never fails with
# "/usr/bin/env: 'bash\r': No such file or directory".
normalize-eol:
> sed -i 's/\r$$//' build.sh 2>/dev/null || true

build: normalize-eol
> echo "==> Running governed build workflow"
> PATH="$(VENV_BIN):$$PATH" PYTHONNOUSERSITE=1 REQUIRE_GOVERNED_TOOLS=1 bash ./build.sh from-zero

verify: normalize-eol
> PATH="$(VENV_BIN):$$PATH" PYTHONNOUSERSITE=1 bash ./build.sh verify

smoke:
> $(NPM) run smoke

design: normalize-eol
> PATH="$(VENV_BIN):$$PATH" PYTHONNOUSERSITE=1 bash ./build.sh design

generate: normalize-eol
> PATH="$(VENV_BIN):$$PATH" PYTHONNOUSERSITE=1 REQUIRE_GOVERNED_TOOLS=1 bash ./build.sh from-zero

run:
> echo "==> Serving Contract Quest at http://$(HOST):$(PORT)"
> "$(VENV_PYTHON)" -m http.server "$(PORT)" --bind "$(HOST)" --directory frontend

clean:
> echo "==> Removing local workflow caches"
> rm -rf .mb .build .pytest_cache test-results playwright-report dist

clean-venv:
> echo "==> Removing .venv"
> rm -rf "$(VENV_DIR)"