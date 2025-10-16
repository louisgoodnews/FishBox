function create_python_project
    # -------------------------------------------------------------------------
    # create_python_project (fish shell function)
    #
    # Description:
    #   Automates the creation of a new Python project structure.
    #   It sets up directories, boilerplate files, and a virtual environment.
    #
    # Usage:
    #   create_python_project [--no-git] [--no-venv] [--no-install] [--pkg-name <name>] [target_dir] project_name
    #
    # Optional flags:
    #   --no-git     Skip git initialization and initial commit
    #   --no-venv    Skip virtual environment creation/activation
    #   --no-install Skip pip installs (requirements.txt)
    #   --pkg-name   Override inner package name under src/
    #
    # Arguments:
    #   target_dir   (optional) Path where the project folder will be created.
    #                Defaults to the current directory.
    #
    #   project_name (required) Name of the project, also used as the
    #                top-level package name inside src/.
    #
    # Example:
    #   create_python_project myapp
    #   create_python_project ~/Projects coolapp
    #
    # Features:
    #   - Creates a standard Python project layout (src/, tests/, docs/, etc.)
    #   - Adds common project files (README.md, setup.py, requirements.txt, etc.)
    #   - Initializes Python package folders with __init__.py files
    #   - Sets up a virtual environment at .venv/
    #
    # Notes:
    #   - Requires Python 3 installed and available as `python3`.
    #   - The virtual environment is not activated automatically.
    # -------------------------------------------------------------------------

    # Default target directory (when not provided) is the current directory
    set -l target_dir

    # The name of the project (outer/top-level directory and package name)
    set -l outer_project_name

    # The name of the inner project (package name under src/)
    set -l inner_project_name

    # Feature toggles
    set -l do_git 1
    set -l do_venv 1
    set -l do_install 1
    set -l override_pkg_name

    # Parse flags then positional args
    set -l argv_filtered
    set -l mode normal
    for arg in $argv
        switch $arg
            case "--no-git"
                set do_git 0
            case "--no-venv"
                set do_venv 0
            case "--no-install"
                set do_install 0
            case "--pkg-name"
                set mode pkg
            case '*'
                if test $mode = pkg
                    set override_pkg_name $arg
                    set mode normal
                else
                    set argv_filtered $argv_filtered $arg
                end
        end
    end

    # - 1 arg: project_name (target_dir defaults to ".")
    # - 2 args: target_dir project_name
    if test (count $argv_filtered) -eq 1
        set outer_project_name $argv_filtered[1]
        set target_dir .
    else if test (count $argv_filtered) -eq 2
        set target_dir $argv_filtered[1]
        set outer_project_name $argv_filtered[2]
    else
        echo ""
        echo "Usage: create_python_project [--no-git] [--no-venv] [--no-install] [--pkg-name <name>] [target_dir] project_name"
        echo ""
        echo "Optional flags:"
        echo "  --no-git     Skip git initialization and initial commit"
        echo "  --no-venv    Skip virtual environment creation/activation"
        echo "  --no-install Skip pip installs (requirements.txt)"
        echo "  --pkg-name   Override inner package name under src/"
        echo ""
        echo "Example:"
        echo "  create_python_project myapp"
        echo "  create_python_project --pkg-name mypkg ~/Projects coolapp"
        return 1
    end

    # The project inner (import) name: override or lowercase of outer name
    if test (string length $override_pkg_name) -eq 0
        set inner_project_name (string lower $outer_project_name)
    else
        set inner_project_name $override_pkg_name
    end

    # The absolute path to the target directory to avoid relative path issues
    set -l abs_target_dir (realpath $target_dir)
    # The absolute path to the project directory
    set -l proj_dir $abs_target_dir/$outer_project_name

    # Print the project name and the target directory
    echo "Creating project '$outer_project_name' in '$proj_dir' ..."

    # Create the project directory structure
    echo "Creating directories ..."
    mkdir -p -v $proj_dir/docs
    mkdir -p -v $proj_dir/examples
    mkdir -p -v $proj_dir/tests
    mkdir -p -v $proj_dir/thirdparty
    mkdir -p -v $proj_dir/src
    mkdir -p -v $proj_dir/src/$inner_project_name
    mkdir -p -v $proj_dir/src/$inner_project_name/common
    mkdir -p -v $proj_dir/src/$inner_project_name/core
    mkdir -p -v $proj_dir/src/$inner_project_name/utils
    mkdir -p -v $proj_dir/.github/workflows
    echo "done"

    # Create the __init__.py files to make packages importable
    echo "Creating __init__.py files ..."
    touch $proj_dir/tests/__init__.py
    touch $proj_dir/examples/__init__.py
    touch $proj_dir/src/__init__.py
    touch $proj_dir/src/$inner_project_name/__init__.py
    touch $proj_dir/src/$inner_project_name/common/__init__.py
    touch $proj_dir/src/$inner_project_name/core/__init__.py
    touch $proj_dir/src/$inner_project_name/utils/__init__.py
    echo "done"

    # Create and populate common project files
    echo "Creating project files ..."
    # .gitignore
    begin
        echo "# Byte-compiled / optimized / DLL files"
        echo "__pycache__/"
        echo "*.py[cod]"
        echo "*$py.class"
        echo ""
        echo "# Virtual environments"
        echo ".venv/"
        echo "venv/"
        echo ""
        echo "# Distribution / packaging"
        echo "build/"
        echo "dist/"
        echo "*.egg-info/"
        echo ""
        echo "# Caches"
        echo ".pytest_cache/"
        echo ".mypy_cache/"
        echo ".ruff_cache/"
        echo ""
        echo "# Editors/OS"
        echo ".DS_Store"
        echo ".idea/"
        echo ".vscode/"
    end > $proj_dir/.gitignore

    # .editorconfig
    begin
        echo "root = true"
        echo ""
        echo "[*]"
        echo "charset = utf-8"
        echo "end_of_line = lf"
        echo "insert_final_newline = true"
        echo "indent_style = space"
        echo "indent_size = 4"
    end > $proj_dir/.editorconfig

    # Optional placeholder files (user can fill or remove as needed)
    touch $proj_dir/.pre-commit-config.yaml
    touch $proj_dir/CHANGELOG.md
    touch $proj_dir/CONTRIBUTING.md
    touch $proj_dir/CODE_OF_CONDUCT.md
    touch $proj_dir/ISSUE_TEMPLATE.md

    # README.md
    begin
        echo "# $outer_project_name"
        echo ""
        echo "Project scaffold created by create_python_project."
        echo ""
        echo "## Quickstart"
        echo ""
        echo "\"\"\""
    end > $proj_dir/README.md
    # Append fenced blocks via printf to preserve backticks
    printf "%s\n" "python -m venv .venv" "source .venv/bin/activate" "pip install -r requirements.txt" >> $proj_dir/README.md

    # requirements.txt (empty default)
    touch $proj_dir/requirements.txt

    # setup.py
    begin
        echo "from setuptools import setup, find_packages"
        echo ""
        echo "setup(" 
        echo "    name=\"$outer_project_name\"," 
        echo "    version=\"0.1.0\"," 
        echo "    packages=find_packages(where=\"src\")," 
        echo "    package_dir={\"\": \"src\"}," 
        echo ")"
    end > $proj_dir/setup.py

    # setup.cfg
    begin
        echo "[metadata]"
        echo "name = $outer_project_name"
        echo "version = 0.1.0"
        echo ""
        echo "[options]"
        echo "package_dir ="
        echo "    = src"
        echo "packages = find:"
        echo ""
        echo "[options.packages.find]"
        echo "where = src"
        echo ""
        echo "[tool:pytest]"
        echo "addopts = -q"
    end > $proj_dir/setup.cfg

    # pyproject.toml
    begin
        echo "[build-system]"
        echo "requires = [\"setuptools>=61.0\"]"
        echo "build-backend = \"setuptools.build_meta\""
        echo ""
        echo "[tool.black]"
        echo "line-length = 100"
        echo "target-version = [\"py311\"]"
        echo ""
        echo "[tool.isort]"
        echo "profile = \"black\""
        echo ""
        echo "[tool.pytest.ini_options]"
        echo "testpaths = [\"tests\"]"
    end > $proj_dir/pyproject.toml

    # docs/conf.py
    begin
        echo "project = \"$outer_project_name\""
        echo "extensions = []"
        echo "templates_path = ['_templates']"
        echo "exclude_patterns = []"
    end > $proj_dir/docs/conf.py

    # docs/index.rst
    begin
        echo "$outer_project_name documentation"
        echo "==============================="
        echo ""
        echo "Welcome to the docs!"
    end > $proj_dir/docs/index.rst

    # tox.ini
    begin
        echo "[tox]"
        echo "envlist = py311"
        echo ""
        echo "[testenv]"
        echo "deps = -rrequirements.txt"
        echo "commands = pytest"
    end > $proj_dir/tox.ini

    # Makefile
    begin
        echo ".PHONY: run test fmt lint type"
        echo "run:"
        echo "\tpython -m $inner_project_name.main"
        echo "test:"
        echo "\tpytest -q"
        echo "fmt:"
        echo "\tblack src tests"
        echo "lint:"
        echo "\truff check src tests || true"
        echo "type:"
        echo "\tmypy src || true"
    end > $proj_dir/Makefile

    # Dockerfile
    begin
        echo "FROM python:3.12-slim"
        echo "WORKDIR /app"
        echo "COPY . ."
        echo "RUN python -m pip install --upgrade pip && pip install -r requirements.txt"
        echo "CMD [\"python\", \"-m\", \"$inner_project_name.main\"]"
    end > $proj_dir/Dockerfile

    # .github/workflows/ci.yml
    begin
        echo "name: Python CI"
        echo "on: [push, pull_request]"
        echo "jobs:"
        echo "  build-test:"
        echo "    runs-on: ubuntu-latest"
        echo "    strategy:"
        echo "      matrix:"
        echo "        python-version: [\"3.10\", \"3.11\", \"3.12\"]"
        echo "    steps:"
        echo "      - uses: actions/checkout@v4"
        echo "      - uses: actions/setup-python@v5"
        echo "        with:"
        echo '          python-version: "${{ matrix.python-version }}"'
        echo "      - name: Install"
        echo "        run: |"
        echo "          python -m pip install --upgrade pip"
        echo "          pip install -r requirements.txt"
        echo "      - name: Test"
        echo "        run: pytest -q"
    end > $proj_dir/.github/workflows/ci.yml

    echo "done"

    # LICENSE (MIT)
    echo "Creating LICENSE (MIT) ..."
    set current_year (date +%Y)
    begin
        echo "MIT License"
        echo ""
        echo "Copyright (c) $current_year"
        echo ""
        echo "Permission is hereby granted, free of charge, to any person obtaining a copy"
        echo "of this software and associated documentation files (the \"Software\"), to deal"
        echo "in the Software without restriction, including without limitation the rights"
        echo "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"
        echo "copies of the Software, and to permit persons to whom the Software is"
        echo "furnished to do so, subject to the following conditions:"
        echo ""
        echo "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
        echo "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
        echo "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
        echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
        echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
        echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
        echo "SOFTWARE."
    end > $proj_dir/LICENSE

    # Create the main and debug scripts as starting points
    echo "Creating main and debug scripts ..."
    touch $proj_dir/src/$inner_project_name/main.py
    touch $proj_dir/src/$inner_project_name/debug.py
    echo "done"

    # Create the core and utils scripts scaffolding
    echo "Creating core and utils scripts ..."
    touch $proj_dir/src/$inner_project_name/common/constants.py
    touch $proj_dir/src/$inner_project_name/core/constants.py
    touch $proj_dir/src/$inner_project_name/core/core.py
    touch $proj_dir/src/$inner_project_name/utils/constants.py
    touch $proj_dir/src/$inner_project_name/utils/utils.py
    echo "done"

    # Enter project directory for subsequent operations
    echo "Entering project directory ..."
    cd $proj_dir
    echo "done"

    # Create the virtual environment (optional)
    if test $do_venv -eq 1
        echo "Creating virtual environment ..."
        python3 -m venv $proj_dir/.venv
        if test -f $proj_dir/.venv/bin/activate.fish
            echo "Python virtual environment created at $proj_dir/.venv"
            echo "To activate the venv, run:"
            echo "  source $proj_dir/.venv/bin/activate.fish"
        else
            echo "⚠️ Could not find activate.fish; virtualenv creation may have failed."
        end
    else
        echo "Skipping virtual environment creation (--no-venv)."
    end

    # Print a message indicating that the project structure has been created
    echo "Project structure created."

    # Activate venv and install dependencies
    if test $do_venv -eq 1
        if test -f $proj_dir/.venv/bin/activate.fish
            echo "Activating virtual environment to update pip..."
            source $proj_dir/.venv/bin/activate.fish
            echo "done"
            if test $do_install -eq 1
                echo "Upgrading pip ..."
                pip install --upgrade pip
                echo "Installing requirements ..."
                pip install -r $proj_dir/requirements.txt
                echo "done"
            else
                echo "Skipping pip installs (--no-install)."
            end
        end
    else
        echo "Skipping installs due to --no-venv."
    end

    # Initialize git repository (optional)
    if test $do_git -eq 1
        echo "Initializing git repository ..."
        git init
        git add .
        git commit -m "Initial Python project setup" >/dev/null ^/dev/null
        echo "done"
    else
        echo "Skipping git init (--no-git)."
    end

    # Create NEXT_STEPS.md
    set next_steps_file $proj_dir/NEXT_STEPS.md
    begin
        echo "# 🐍 Next Steps: Getting Started with $outer_project_name"
        echo ""
        echo "## Structure"
        echo "."
        echo "├── src/$inner_project_name/"
        echo "├── tests/"
        echo "├── docs/"
        echo "├── .github/workflows/"
        echo "├── Makefile, Dockerfile, pyproject.toml, setup.cfg, setup.py"
        echo "└── requirements.txt"
        echo ""
        echo "## Common Commands"
        echo "- Create venv: python -m venv .venv"
        echo "- Activate: source .venv/bin/activate"
        echo "- Install: pip install -r requirements.txt"
        echo "- Test: pytest -q"
        echo "- Format: black src tests"
        echo "- Lint: ruff check src tests"
        echo ""
        echo "## CI"
        echo "GitHub Actions config at .github/workflows/ci.yml runs tests on 3.10–3.12."
    end > $next_steps_file

    echo "DO NOT FORGET TO ACTIVATE THE VENV BEFORE USING IT!"
    echo "To activate the venv, run:"
    echo "  source $proj_dir/.venv/bin/activate.fish"
end