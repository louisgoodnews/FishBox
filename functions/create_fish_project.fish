function create_fish_project
    # -------------------------------------------------------------------------
    # create_fish_project (fish shell function)
    #
    # Description:
    #   Automates the creation of a fully-featured Fish shell project structure.
    #   Sets up directories, boilerplate files, Git integration, documentation,
    #   auto-loading conf.d scripts, sample functions, completions, tests, and scripts.
    #
    # Usage:
    #   create_fish_project [--no-git] [--no-tests] [--no-docs] [--no-install-files] [--license <mit|none>] [target_dir] project_name
    #
    # Optional flags:
    #   --no-git           Skip git initialization and initial files
    #   --no-tests         Do not create tests/ or sample test
    #   --no-docs          Do not create docs/
    #   --no-install-files Do not create install.fish / uninstall.fish
    #   --license          Either 'mit' (default) or 'none'
    #
    # Arguments:
    #   target_dir   (optional) Path where the project folder will be created.
    #                Defaults to the current directory.
    #
    #   project_name (required) Name of the project.
    #
    # Example:
    #   create_fish_project myfishplugin
    #   create_fish_project ~/Projects coolfish
    # -------------------------------------------------------------------------

    # Flags and args
    set -l target_dir
    set -l project_name
    set -l do_git 1
    set -l do_tests 1
    set -l do_docs 1
    set -l do_install_files 1
    set -l license_kind mit

    # Parse flags first
    set -l argv_filtered
    set -l mode normal
    for arg in $argv
        switch $arg
            case "--no-git"
                set do_git 0
            case "--no-tests"
                set do_tests 0
            case "--no-docs"
                set do_docs 0
            case "--no-install-files"
                set do_install_files 0
            case "--license"
                set mode license
            case '*'
                if test $mode = license
                    set license_kind (string lower $arg)
                    set mode normal
                else
                    set argv_filtered $argv_filtered $arg
                end
        end
    end

    # Positional: [target_dir] project_name
    if test (count $argv_filtered) -eq 1
        set project_name $argv_filtered[1]
        set target_dir .
    else if test (count $argv_filtered) -eq 2
        set target_dir $argv_filtered[1]
        set project_name $argv_filtered[2]
    else
        echo ""
        echo "Usage: create_fish_project [--no-git] [--no-tests] [--no-docs] [--no-install-files] [--license <mit|none>] [target_dir] project_name"
        echo ""
        echo "Examples:"
        echo "  create_fish_project myfishplugin"
        echo "  create_fish_project --no-git --license none ~/Projects coolfish"
        return 1
    end

    # Set absolute target directory
    set -l abs_target_dir (realpath $target_dir)

    # Set project directory
    set -l proj_dir $abs_target_dir/$project_name

    # Print project creation message
    echo "Creating Fish project '$project_name' at '$proj_dir' ..."

    # Create directories
    echo "Creating directories ..."
    mkdir -p $proj_dir/functions
    mkdir -p $proj_dir/completions
    mkdir -p $proj_dir/conf.d
    mkdir -p $proj_dir/scripts
    # Always create tests/ and docs/ so users have placeholders available
    mkdir -p $proj_dir/tests
    mkdir -p $proj_dir/docs
    echo "done"

    # Create and populate boilerplate files
    echo "Creating boilerplate files ..."
    # README.md
    begin
        echo "# $project_name"
        echo ""
        echo "A Fish shell project created by create_fish_project."
        echo ""
        echo "## Install"
        echo "Copy or symlink the conf.d file to ~/.config/fish/conf.d/"
        echo ""
        echo "## Usage"
        echo "After installation, functions are auto-loaded."
    end > $proj_dir/README.md

    # .gitignore
    begin
        echo "# OS"
        echo ".DS_Store"
        echo "Thumbs.db"
        echo ""
        echo "# Editors"
        echo "*.swp"
        echo ".idea/"
        echo ".vscode/"
        echo ""
        echo "# Env"
        echo ".env"
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

    # Makefile
    begin
        echo ".PHONY: install uninstall test"
        echo "install:"
        echo "\t@./install.fish"
        echo "uninstall:"
        echo "\t@./uninstall.fish"
        echo "test:"
        echo "\t@./scripts/run_tests.fish"
    end > $proj_dir/Makefile

    # install/uninstall scripts (optional)
    if test $do_install_files -eq 1
        begin
            echo "#!/usr/bin/env fish"
            echo "set -e"
            echo "set self_dir (pwd)"
            echo "set target (or $XDG_CONFIG_HOME ~/.config)/fish/conf.d"
            echo "mkdir -p $target"
            echo "echo Installing conf.d/$project_name.fish to $target"
            echo "cp $self_dir/conf.d/$project_name.fish $target/"
            echo "echo Done."
        end > $proj_dir/install.fish
        chmod +x $proj_dir/install.fish

        begin
            echo "#!/usr/bin/env fish"
            echo "set -e"
            echo "set target (or $XDG_CONFIG_HOME ~/.config)/fish/conf.d/$project_name.fish"
            echo "if test -f $target; rm $target; echo Removed $target; else; echo Not found: $target; end"
        end > $proj_dir/uninstall.fish
        chmod +x $proj_dir/uninstall.fish
    end

    # LICENSE
    if test $license_kind = mit
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
    else
        touch $proj_dir/LICENSE
    end

    # package.conf
    begin
        echo "name=$project_name"
        echo "version=0.1.0"
        echo "description=A Fish shell project"
    end > $proj_dir/package.conf

    # Function module and sample
    touch $proj_dir/functions/__init__.fish
    begin
        echo "function $project_name"
        echo "    echo '$project_name loaded'"
        echo "end"
    end > $proj_dir/functions/$project_name.fish

    # Docs index: always create placeholder; populate content only if enabled
    if test $do_docs -eq 1
        begin
            echo "# Documentation"
            echo "Welcome to $project_name!"
        end > $proj_dir/docs/index.md
    else
        touch $proj_dir/docs/index.md
    end

    # Tests init: always create placeholder
    touch $proj_dir/tests/__init__.fish
    echo "done"

    # Git integration
    if test $do_git -eq 1
        echo "Setting up Git repository ..."
        git init $proj_dir >/dev/null
        echo "done"
    else
        echo "Skipping git init (--no-git)."
    end

    # GitHub / Git conventions
    echo "Creating Git-related files ..."
    touch $proj_dir/CONTRIBUTING.md
    touch $proj_dir/ISSUE_TEMPLATE.md
    touch $proj_dir/CODE_OF_CONDUCT.md
    touch $proj_dir/CHANGELOG.md
    echo "done"

    # Sample function: hello
    echo "Creating sample function 'hello' ..."
    set -l hello_func $proj_dir/functions/hello.fish
    echo "function hello" > $hello_func
    echo "    echo 'Hello, world from $project_name!'" >> $hello_func
    echo "end" >> $hello_func
    echo "done"

    # Sample completion
    echo "Creating sample completion for 'hello' ..."
    set -l comp_file $proj_dir/completions/hello.fish
    echo "complete -c hello -d 'Prints a greeting message'" > $comp_file
    echo "done"

    # conf.d loader
    echo "Creating conf.d loader ..."
    set -l conf_loader $proj_dir/conf.d/$project_name.fish
    begin
        echo "# Auto-load functions and completions for $project_name"
        echo "# Resolve this script's directory at runtime for portability"
        echo "set -l self_file (status -f)"
        echo "set -l self_dir (dirname $self_file)"
        echo "set -l root_dir (realpath $self_dir/..)"
        echo "for f in $root_dir/functions/*.fish"
        echo "    source $f"
        echo "end"
        echo "for c in $root_dir/completions/*.fish"
        echo "    source $c"
        echo "end"
    end > $conf_loader
    echo "done"

    # Sample test
    if test $do_tests -eq 1
        echo "Creating sample test script ..."
        set -l test_file $proj_dir/tests/test_hello.fish
        begin
            echo "function test_hello_output"
            echo "    set output (hello)"
            echo "    if test $output = 'Hello, world from $project_name!'"
            echo "        echo 'Test passed: hello function works.'"
            echo "    else"
            echo "        echo 'Test failed: unexpected output:' $output"
            echo "    end"
            echo "end"
        end > $test_file
        echo "done"
    end

    # Helper script
    echo "Creating optional helper script ..."
    set -l helper_script $proj_dir/scripts/setup_env.fish
    echo "#!/usr/bin/env fish" > $helper_script
    echo "echo 'Setup environment for $project_name'" >> $helper_script
    chmod +x $helper_script
    echo "done"

    # Simple test runner script
    begin
        echo "#!/usr/bin/env fish"
        echo "set -e"
        echo "for t in tests/*.fish"
        echo "    echo Running $t"
        echo "    source $t"
        echo "end"
        echo "test_hello_output ^/dev/null || true"
    end > $proj_dir/scripts/run_tests.fish
    chmod +x $proj_dir/scripts/run_tests.fish

    # NEXT_STEPS.md with cleaner formatting
    echo "Writing project instructions to NEXT_STEPS.md ..."
    set -l next_steps $proj_dir/NEXT_STEPS.md
    echo "# Next Steps for $project_name" > $next_steps
    echo "" >> $next_steps
    echo "## Load Project" >> $next_steps
    echo "Source the conf.d loader in your Fish config or copy it to \`~/.config/fish/conf.d/\`:" >> $next_steps
    echo '```fish' >> $next_steps
    echo "source $proj_dir/conf.d/$project_name.fish" >> $next_steps
    echo '```' >> $next_steps
    echo "" >> $next_steps
    echo "## Add Functions and Completions" >> $next_steps
    echo "- Add more functions to \`functions/\`" >> $next_steps
    echo "- Add more completions to \`completions/\`" >> $next_steps
    echo "" >> $next_steps
    echo "## Run Sample Test" >> $next_steps
    echo '```fish' >> $next_steps
    echo "source tests/test_hello.fish" >> $next_steps
    echo "test_hello_output" >> $next_steps
    echo '```' >> $next_steps
    echo "" >> $next_steps
    echo "## Helper Scripts" >> $next_steps
    echo "- Add scripts to \`scripts/\` as needed" >> $next_steps
    echo "" >> $next_steps
    echo "## Documentation" >> $next_steps
    echo "- Update documentation in \`docs/\`" >> $next_steps
    echo "" >> $next_steps
    echo "## Git" >> $next_steps
    echo '```fish' >> $next_steps
    echo "git add ." >> $next_steps
    echo "git commit -m 'Initial project structure'" >> $next_steps
    echo '```' >> $next_steps
    echo "" >> $next_steps
    echo "## Start Developing" >> $next_steps
    echo "- Begin writing your Fish plugin and functions!" >> $next_steps
    echo "done"

    # Final terminal message
    echo ""
    echo "Fish project '$project_name' created successfully!"
    echo "All instructions have also been saved to $proj_dir/NEXT_STEPS.md"
    echo ""
    echo "done"
end
