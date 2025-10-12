function create_rust_project
        # -------------------------------------------------------------------------
        # create_rust_project (fish shell function)
        #
        # Description:
        #   Automates the creation of a complete Rust project structure with
        #   optional components for library or binary development, CI/CD, linting,
        #   formatting, auditing, and devcontainer support.
        #
        # Usage:
        #   create_rust_project [--lib|--bin] [--no-git] [--no-build] [target_dir] project_name
        #
        #   Optional flags:
        #     --no-git   → skip git initialization
        #     --no-build → skip automatic cargo build
        #
        # Example:
        #   create_rust_project myapp
        #   create_rust_project --lib ~/Projects mylib
        #
        # Features:
        #   - Initializes Rust project using Cargo
        #   - Supports library (--lib) or binary (--bin) templates
        #   - Adds folders: examples/, benches/, docs/, scripts/, .github/, .devcontainer/
        #   - Adds config files: rustfmt.toml, clippy.toml, .editorconfig, etc.
        #   - Adds CI/CD workflow, Makefile, Dockerfile, LICENSE, README
        #   - Optionally runs `cargo fmt`, `cargo clippy`, and `cargo build`
        #
        # Requirements:
        #   - Rust and Cargo installed
        #   - Git available
        # -------------------------------------------------------------------------

        # Default to a binary project unless --lib is provided
        set -l project_type "--bin"
        # Default target directory is the current working directory
        set -l target_dir "."
        # Project name will be derived from positional args
        set -l project_name
        # Feature toggles (enabled by default)
        set -l do_git 1
        set -l do_build 1

        # Parse arguments
        for arg in $argv
            switch $arg
                case "--lib"
                    # Explicitly request a library template
                    set project_type "--lib"
                case "--bin"
                    # Explicitly request a binary template (default)
                    set project_type "--bin"
                case "--no-git"
                    # Skip repository initialization
                    set do_git 0
                case "--no-build"
                    # Skip automatic cargo build
                    set do_build 0
                case '*'
                # Handle positional arguments:
                # - First positional becomes project_name when not set yet
                # - Second positional (if provided) is target_dir, shifting
                #   the first positional to project_name
                if not set -q project_name
                    # First positional: project name
                    set project_name $arg
                else if test $target_dir = "."
                    # Second positional: previous name becomes target_dir,
                    # current arg becomes project_name
                    set target_dir $project_name
                    set project_name $arg
                end
            end
        end

        if not set -q project_name
            # Insufficient arguments: show usage and exit non-zero
            echo ""
            echo "Usage: create_rust_project [--lib|--bin] [--no-git] [--no-build] [target_dir] project_name"
            echo ""
            echo "Optional flags:"
            echo "  --no-git    Skip git initialization"
            echo "  --no-build  Skip automatic cargo build"
            echo ""
            echo "Example:"
            echo "  create_rust_project myapp"
            echo "  create_rust_project --lib ~/Projects mylib"
            return 1
        end

        # Resolve absolute target directory to avoid relative-path confusion
        set -l abs_target_dir (realpath $target_dir)
        # The final project directory path
        set -l proj_dir $abs_target_dir/$project_name

        echo "Creating Rust project '$project_name' in '$proj_dir' ..."
        mkdir -p $abs_target_dir

        # Create base Cargo project
        echo "Initializing Cargo project ($project_type) ..."
        cargo new $project_type $proj_dir
        echo "done"

        # Create standard directories
        echo "Creating additional directories ..."
        mkdir -p $proj_dir/{examples,benches,docs,scripts,.github/workflows,.devcontainer}
        echo "done"

        # Create config files
        echo "Creating configuration files ..."
        begin
            echo "max_width = 100"
            echo "hard_tabs = false"
            echo "edition = \"2021\""
            echo "use_small_heuristics = \"Max\""
        end > $proj_dir/rustfmt.toml

        begin
            echo "warn = [\"clippy::pedantic\", \"clippy::nursery\"]"
            echo "allow = [\"clippy::module_name_repetitions\"]"
        end > $proj_dir/clippy.toml

        begin
            echo "root = true"
            echo ""
            echo "[*]"
            echo "charset = utf-8"
            echo "end_of_line = lf"
            echo "insert_final_newline = true"
            echo "indent_style = space"
        end > $proj_dir/.editorconfig
        echo "done"

        # .gitignore
        echo "Creating .gitignore ..."
        begin
            echo "target/"
            echo "Cargo.lock"
            echo ".DS_Store"
            echo ".idea/"
            echo ".vscode/"
            echo "*.iml"
        end > $proj_dir/.gitignore

        # LICENSE
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

        # Makefile
        echo "Creating Makefile ..."
        begin
            echo ".PHONY: build test fmt lint audit"
            echo ""
            echo "build:"
            echo "\tcargo build"
            echo ""
            echo "test:"
            echo "\tcargo test"
            echo ""
            echo "fmt:"
            echo "\tcargo fmt --all"
            echo ""
            echo "lint:"
            echo "\tcargo clippy -- -D warnings"
            echo ""
            echo "audit:"
            echo "\tcargo audit || true"
            echo "\tcargo deny check licenses || true"
        end > $proj_dir/Makefile

        # Dockerfile
        echo "Creating Dockerfile ..."
        begin
            echo "FROM rust:latest"
            echo "WORKDIR /app"
            echo "COPY . ."
            echo "RUN cargo build --release"
            echo "CMD [\"./target/release/app\"]"
        end > $proj_dir/Dockerfile

        # Devcontainer
        echo "Creating Devcontainer config ..."
        begin
            echo "{"
            echo "    \"name\": \"Rust Dev Container\"," 
            echo "    \"image\": \"mcr.microsoft.com/devcontainers/rust:latest\"," 
            echo "    \"features\": {"
            echo "        \"ghcr.io/devcontainers/features/common-utils:2\": {}"
            echo "    },"
            echo "    \"postCreateCommand\": \"cargo build\"," 
            echo "    \"customizations\": {"
            echo "        \"vscode\": {"
            echo "            \"extensions\": ["
            echo "                \"rust-lang.rust-analyzer\"," 
            echo "                \"tamasfe.even-better-toml\""
            echo "            ]"
            echo "        }"
            echo "    }"
            echo "}"
        end > $proj_dir/.devcontainer/devcontainer.json

        # CI workflow
        echo "Creating CI workflow ..."
        begin
            echo "name: Rust CI"
            echo ""
            echo "on: [push, pull_request]"
            echo ""
            echo "jobs:"
            echo "  build-test-lint:"
            echo "    runs-on: ubuntu-latest"
            echo "    steps:"
            echo "      - uses: actions/checkout@v4"
            echo "      - uses: dtolnay/rust-toolchain@stable"
            echo "      - name: Build"
            echo "        run: cargo build --verbose"
            echo "      - name: Test"
            echo "        run: cargo test --verbose"
            echo "      - name: Lint"
            echo "        run: cargo clippy -- -D warnings"
            echo "      - name: Format check"
            echo "        run: cargo fmt --all -- --check"
            echo "      - name: Audit"
            echo "        run: cargo install cargo-audit && cargo audit || true"
        end > $proj_dir/.github/workflows/ci.yml

        # Initialize git (unless disabled via --no-git)
        if test $do_git -eq 1
            if not test -d $proj_dir/.git
                # Only initialize if not already a git repo (idempotency)
                echo "Initializing git repository ..."
                cd $proj_dir
                git init
                git add .
                git commit -m "Initial Rust project setup"
                echo "done"
            end
        end

        # Optionally install helpful cargo tools
        echo "Installing optional cargo tools (if available) ..."
        for tool in cargo-audit cargo-deny cargo-nextest
            # Install the tool only if it is not already available in PATH
            if not type -q $tool
                echo "Installing $tool ..."
                cargo install $tool ^/dev/null
            end
        end

        # Initial formatting and optional build
        if test $do_build -eq 1
            echo "Running cargo fmt and build ..."
        else
            echo "Running cargo fmt ... (build skipped)"
        end
        # Ensure commands run inside the new project directory
        cd $proj_dir
        cargo fmt
        if test $do_build -eq 1
            cargo build
        end
        echo "done"

        echo "Creating NEXT_STEPS.md with usage instructions ..."
        set next_steps_file $proj_dir/NEXT_STEPS.md
        begin
            echo "# 🦀 Next Steps: Getting Started with Your Rust Project"
            echo ""
            echo "Welcome to your new Rust project! 🎉"
            echo "This guide highlights what was created and common commands you'll use."
            echo ""
            echo "---"
            echo ""
            echo "## 1️⃣ What Was Created"
            echo ""
            echo "This is a single Cargo project initialized by \`cargo new\` with extra tooling:"
            echo ""
            echo "."
            echo "├── Cargo.toml ← Project manifest"
            echo "├── src/ ← Your Rust source code"
            echo "├── examples/ ← Example programs (optional)"
            echo "├── benches/ ← Benchmarks (optional)"
            echo "├── docs/ ← Documentation (optional)"
            echo "├── scripts/ ← Helper scripts"
            echo "├── .github/workflows/ ← CI configuration"
            echo "├── .devcontainer/ ← Devcontainer config (VS Code Dev Containers)"
            echo "├── rustfmt.toml, clippy.toml, .editorconfig ← Formatting/linting config"
            echo "└── Makefile ← Convenience targets (build/test/fmt/lint/audit)"
            echo ""
            echo "---"
            echo ""
            echo "## 2️⃣ Common Commands"
            echo ""
            echo "Build and run (binary projects):"
            echo ""
            echo "\`\`\`bash"
            echo "cargo build"
            echo "cargo run"
            echo "\`\`\`"
            echo ""
            echo "Run tests and lints:"
            echo ""
            echo "\`\`\`bash"
            echo "cargo test"
            echo "cargo fmt --all"
            echo "cargo clippy -- -D warnings"
            echo "\`\`\`"
            echo ""
            echo "Security/license checks (if tools installed):"
            echo ""
            echo "\`\`\`bash"
            echo "cargo audit || true"
            echo "cargo deny check licenses || true"
            echo "\`\`\`"
            echo ""
            echo "---"
            echo ""
            echo "## 3️⃣ Next Steps"
            echo ""
            echo "- Edit \`src/main.rs\` (bin) or \`src/lib.rs\` (lib) and start coding."
            echo "- Add dependencies by editing \`Cargo.toml\` (or use \`cargo add\` if available)."
            echo "- Customize CI in \`.github/workflows/ci.yml\` and devcontainer settings as needed."
            echo ""
            echo "Git repository was initialized by the script if none was present. If you want to"
            echo "make an initial commit manually:"
            echo ""
            echo "\`\`\`bash"
            echo "git add ."
            echo "git commit -m \"Initial Rust project\""
            echo "\`\`\`"
            echo ""
            echo "---"
            echo ""
            echo "## 4️⃣ Considering a Workspace?"
            echo ""
            echo "If you plan to split code into multiple crates, consider using a workspace:"
            echo ""
            echo "- Create a workspace: \`create_rust_workspace\`"
            echo "- Add a crate to a workspace: \`add_crate_to_workspace\`"
            echo "- Remove a crate from a workspace: \`remove_crate_from_workspace\`"
            echo ""
            echo "Happy coding! 🦀"
            echo "— Your automated project setup"
        end > $next_steps_file
        echo "✅ NEXT_STEPS.md created."

        echo ""
        echo "✅ Rust project '$project_name' created successfully!"
        echo "Location: $proj_dir"
        echo ""
        echo "To start developing:"
        echo "  cd $proj_dir"
        echo "  cargo run"
    end
