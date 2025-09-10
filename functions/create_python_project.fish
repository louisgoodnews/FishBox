function create_python_project
    # -------------------------------------------------------------------------
    # create_python_project (fish shell function)
    #
    # Description:
    #   Automates the creation of a new Python project structure.
    #   It sets up directories, boilerplate files, and a virtual environment.
    #
    # Usage:
    #   create_python_project [target_dir] project_name
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

    # The target directory
    set -l target_dir

    # The name of the project
    set -l outer_project_name

    # Check if the user provided a target directory and a project name
    if test (count $argv) -eq 1
        # Set the project name to the first argument
        set outer_project_name $argv[1]
        # Set the target directory to the current directory
        set target_dir .
    # Check if the user provided a target directory and a project name
    else if test (count $argv) -eq 2
        # Set the target directory to the first argument
        set target_dir $argv[1]
        # Set the project name to the second argument
        set outer_project_name $argv[2]
    # If the user provided an invalid number of arguments
    else
        # Print the usage message
        echo ""
        echo "Usage: create_python_project [target_dir] project_name"
        echo ""
        echo "Example:"
        echo "  create_python_project myapp"
        echo "  create_python_project ~/Projects coolapp"

        # Return an error code
        return 1
    end

    # The project inner directory name
    set inner_project_name (string lower $outer_project_name)

    # The absolute path to the target directory
    set -l abs_target_dir (realpath $target_dir)
    # The absolute path to the project directory
    set -l proj_dir $abs_target_dir/$outer_project_name

    # Print the project name and the target directory
    echo "Creating project '$outer_project_name' in '$proj_dir' ..."

    # Create the project directory
    echo "Creating directories ..."
    mkdir -p $proj_dir/docs
    mkdir -p $proj_dir/examples
    mkdir -p $proj_dir/tests
    mkdir -p $proj_dir/thirdparty
    mkdir -p $proj_dir/src/$inner_project_name/core
    mkdir -p $proj_dir/src/$inner_project_name/utils
    mkdir -p $proj_dir/.github/workflows
    echo "done"

    # Create the __init__.py files
    echo "Creating __init__.py files ..."
    touch $proj_dir/tests/__init__.py
    touch $proj_dir/examples/__init__.py
    touch $proj_dir/src/__init__.py
    touch $proj_dir/src/$inner_project_name/__init__.py
    touch $proj_dir/src/$inner_project_name/core/__init__.py
    touch $proj_dir/src/$inner_project_name/utils/__init__.py
    echo "done"

    # Create the empty project files
    echo "Creating empty project files ..."
    touch $proj_dir/.gitignore
    touch $proj_dir/.editorconfig
    touch $proj_dir/.pre-commit-config.yaml
    touch $proj_dir/LICENSE
    touch $proj_dir/README.md
    touch $proj_dir/CHANGELOG.md
    touch $proj_dir/CONTRIBUTING.md
    touch $proj_dir/CODE_OF_CONDUCT.md
    touch $proj_dir/ISSUE_TEMPLATE.md
    touch $proj_dir/requirements.txt
    touch $proj_dir/setup.py
    touch $proj_dir/setup.cfg
    touch $proj_dir/pyproject.toml
    touch $proj_dir/docs/conf.py
    touch $proj_dir/docs/index.rst
    touch $proj_dir/tox.ini
    touch $proj_dir/Makefile
    touch $proj_dir/Dockerfile
    echo "done"

    # Create the main and debug scripts
    echo "Creating main and debug scripts ..."
    touch $proj_dir/src/$inner_project_name/main.py
    touch $proj_dir/src/$inner_project_name/debug.py
    echo "done"

    # Create the core and utils scripts
    echo "Creating core and utils scripts ..."
    touch $proj_dir/src/$inner_project_name/core/core.py
    touch $proj_dir/src/$inner_project_name/utils/utils.py
    echo "done"

    # Create the virtual environment
    echo "Creating virtual environment ..."
    python3 -m venv $proj_dir/.venv
    echo "Python virtual environment created at $proj_dir/.venv"
    echo "To activate the venv, run:"
    echo "  source $proj_dir/.venv/bin/activate"

    # Print a message indicating that the project structure has been created
    echo "Project structure created."

    # Activate the virtual environment
    echo "Activating virtual environment to update pip..."
    source $proj_dir/.venv/bin/activate
    echo "done"

    # Upgrade pip
    echo "Upgrading pip ..."
    pip install --upgrade pip
    echo "done"

    # Install dependencies
    echo "Installing dependencies ..."
    pip install -r $proj_dir/requirements.txt
    echo "done"

    echo "DO NOT FORGET TO ACTIVATE THE VENV BEFORE USING IT!"
    echo "To activate the venv, run:"
    echo "  source $proj_dir/.venv/bin/activate"
end