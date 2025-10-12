function create_go_project
    # -------------------------------------------------------------------------
    # create_go_project (fish shell function)
    #
    # Description:
    #   Automates creation of a new Go project with standard structure.
    #   Supports optional flags:
    #     --no-git   → skip git initialization
    #     --no-build → skip initial build
    #
    # Usage:
    #   create_go_project [--no-git] [--no-build] [--module <path>] [target_dir] project_name
    #
    # Example:
    #   create_go_project myapp
    #   create_go_project ~/Projects coolapp
    # -------------------------------------------------------------------------

    # Default options
    set -l target_dir .
    set -l project_name
    set -l do_git 1
    set -l do_build 1

    # Parse flags
    set -l argv_filtered
    set -l module_path
    set -l mode normal
    for arg in $argv
        switch $arg
            case "--no-git"
                set do_git 0
            case "--no-build"
                set do_build 0
            case "--module"
                # Next token will be the module path
                set mode module
            case '*'
                if test $mode = module
                    set module_path $arg
                    set mode normal
                else
                    set argv_filtered $argv_filtered $arg
                end
        end
    end

    # Parse target_dir and project_name
    if test (count $argv_filtered) -eq 1
        set project_name $argv_filtered[1]
    else if test (count $argv_filtered) -eq 2
        set target_dir $argv_filtered[1]
        set project_name $argv_filtered[2]
    else
        echo ""
        echo "Usage: create_go_project [--no-git] [--no-build] [--module <path>] [target_dir] project_name"
        echo ""
        echo "Optional flags:"
        echo "  --no-git    Skip git initialization"
        echo "  --no-build  Skip initial build"
        echo "  --module    Set module path for 'go mod init' (e.g. github.com/user/repo)"
        return 1
    end

    # Paths
    set -l abs_target_dir (realpath $target_dir)
    set -l proj_dir $abs_target_dir/$project_name

    echo "🐹 Creating Go project '$project_name' in '$proj_dir' ..."
    mkdir -p \
        $proj_dir/cmd \
        $proj_dir/pkg \
        $proj_dir/internal \
        $proj_dir/api \
        $proj_dir/configs \
        $proj_dir/build \
        $proj_dir/scripts \
        $proj_dir/tools \
        $proj_dir/tests \
        $proj_dir/docs \
        $proj_dir/.github/workflows
    # Keep otherwise-empty folders tracked
    for d in api configs build scripts tools docs tests pkg internal
        touch $proj_dir/$d/.gitkeep
    end
    echo "✅ Directories created."

    # Initialize Go module
    cd $proj_dir
    if test -n "$module_path"
        go mod init $module_path
    else
        go mod init $project_name
    end
    echo "✅ go.mod initialized."

    # Create main.go in cmd/$project_name
    mkdir -p $proj_dir/cmd/$project_name
    begin
        echo "package main"
        echo ""
        echo "import \"fmt\""
        echo ""
        echo "func main() {"
        echo "    fmt.Println(\"Hello, $project_name!\")"
        echo "}"
    end > $proj_dir/cmd/$project_name/main.go
    echo "✅ main.go created."

    # Standard files
    # README
    begin
        echo "# $project_name"
        echo ""
        echo "Generic Go project scaffold created by create_go_project."
        echo ""
        echo "## Run"
        echo ""
        echo "\`\`\`bash"
        echo "go run ./cmd/$project_name"
        echo "\`\`\`"
        echo ""
        echo "## Test"
        echo ""
        echo "\`\`\`bash"
        echo "go test ./..."
        echo "\`\`\`"
    end > $proj_dir/README.md
    # LICENSE (MIT)
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
        echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
        echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
        echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
        echo "SOFTWARE."
    end > $proj_dir/LICENSE

    # NEXT_STEPS.md
    set next_steps_file $proj_dir/NEXT_STEPS.md
    begin
        echo "# 🐹 Next Steps: Getting Started with Your Go Project"
        echo ""
        echo "## Typical Structure"
        echo "."
        echo "├── cmd/ ← Main applications / binaries"
        echo "│ └── $project_name/ ← Main executable"
        echo "├── pkg/ ← Public packages"
        echo "├── internal/ ← Private/internal packages"
        echo "├── api/ ← API definitions/specs"
        echo "├── configs/ ← Configuration files"
        echo "├── build/ ← Packaging/build scripts"
        echo "├── scripts/ ← Developer scripts"
        echo "├── tools/ ← Tooling (e.g., linters)"
        echo "├── tests/ ← Integration / system tests"
        echo "├── docs/ ← Documentation"
        echo "├── .github/workflows/ ← CI pipelines"
        echo "├── Makefile, Dockerfile, .editorconfig, .golangci.yml"
        echo "├── go.mod ← Go module definition"
        echo "└── README.md"
        echo ""
        echo "## Common Commands"
        echo ""
        echo "- Build all binaries:"
        echo ""
        echo "\`\`\`bash"
        echo "go build ./..."
        echo "\`\`\`"
        echo ""
        echo "- Run main binary:"
        echo ""
        echo "\`\`\`bash"
        echo "go run ./cmd/$project_name"
        echo "\`\`\`"
        echo ""
        echo "- Run tests:"
        echo ""
        echo "\`\`\`bash"
        echo "go test ./..."
        echo "\`\`\`"
        echo ""
        echo "- Add new package:"
        echo ""
        echo "\`\`\`bash"
        echo "mkdir -p pkg/mypkg"
        echo "touch pkg/mypkg/mypkg.go"
        echo "\`\`\`"
        echo ""
        echo "- Remove package:"
        echo ""
        echo "\`\`\`bash"
        echo "rm -rf pkg/mypkg"
        echo "\`\`\`"
    end > $next_steps_file

    echo "✅ NEXT_STEPS.md created."
    echo ""
    echo "✅ Go project '$project_name' successfully created!"
    echo "👉 For next steps, open:"
    echo "   $proj_dir/NEXT_STEPS.md"
end