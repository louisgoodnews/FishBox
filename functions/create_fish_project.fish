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
    #   create_fish_project [target_dir] project_name
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

    # Set target directory
    set -l target_dir

    # Set project name
    set -l project_name

    # If only one argument is provided
    if test (count $argv) -eq 1
        set project_name $argv[1]
        set target_dir .
    # If two arguments were provided
    else if test (count $argv) -eq 2
        set target_dir $argv[1]
        set project_name $argv[2]
    else
    	# Print usage message
        echo ""
        echo "Usage: create_fish_project [target_dir] project_name"
        echo ""
        echo "Example:"
        echo "  create_fish_project myfishplugin"
        echo "  create_fish_project ~/Projects coolfish"
        
        # Return with error code
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
    mkdir -p $proj_dir/tests
    mkdir -p $proj_dir/docs
    echo "done"

    # Create general boilerplate files
    echo "Creating boilerplate files ..."
    touch $proj_dir/README.md
    touch $proj_dir/LICENSE
    touch $proj_dir/functions/__init__.fish
    touch $proj_dir/functions/$project_name.fish
    touch $proj_dir/tests/__init__.fish
    touch $proj_dir/docs/index.md
    echo "done"

    # Git integration
    echo "Setting up Git repository ..."
    git init $proj_dir >/dev/null
    echo "# Ignore temporary and system files" > $proj_dir/.gitignore
    echo ".DS_Store" >> $proj_dir/.gitignore
    echo "*.swp" >> $proj_dir/.gitignore
    echo "thumbs.db" >> $proj_dir/.gitignore
    echo "done"

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
    echo "# Auto-load functions and completions for $project_name" > $conf_loader
    echo "for f in $proj_dir/functions/*.fish" >> $conf_loader
    echo "    source \$f" >> $conf_loader
    echo "end" >> $conf_loader
    echo "for c in $proj_dir/completions/*.fish" >> $conf_loader
    echo "    source \$c" >> $conf_loader
    echo "end" >> $conf_loader
    echo "done"

    # Sample test
    echo "Creating sample test script ..."
    set -l test_file $proj_dir/tests/test_hello.fish
    echo "function test_hello_output" > $test_file
    echo "    set output (hello)" >> $test_file
    echo "    if test \$output = 'Hello, world from $project_name!'" >> $test_file
    echo "        echo 'Test passed: hello function works.'" >> $test_file
    echo "    else" >> $test_file
    echo "        echo 'Test failed: unexpected output:' \$output" >> $test_file
    echo "    end" >> $test_file
    echo "end" >> $test_file
    echo "done"

    # Helper script
    echo "Creating optional helper script ..."
    set -l helper_script $proj_dir/scripts/setup_env.fish
    echo "#!/usr/bin/env fish" > $helper_script
    echo "echo 'Setup environment for $project_name'" >> $helper_script
    chmod +x $helper_script
    echo "done"

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
