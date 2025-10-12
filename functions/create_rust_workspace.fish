function create_rust_workspace
    # -------------------------------------------------------------------------
    # create_rust_workspace (fish shell function)
    #
    # Description:
    #   Creates a complete Rust workspace with multiple crates, shared settings,
    #   and a ready-to-use development environment (Devcontainer, CI/CD, etc.).
    #
    # Usage:
    #   create_rust_workspace [target_dir] workspace_name
    #
    # Example:
    #   create_rust_workspace myworkspace
    #   create_rust_workspace ~/Projects awesome_toolchain
    #
    # Features:
    #   - Initializes a Cargo workspace (multi-crate structure)
    #   - Adds default crates: core, cli, utils
    #   - Includes docs/, examples/, scripts/, .github/, .devcontainer/
    #   - Adds shared config files (rustfmt.toml, clippy.toml)
    #   - Includes CI/CD workflow and Makefile
    #   - Initializes git repo and optionally runs build/test
    #
    # Requirements:
    #   - Rust and Cargo installed
    #   - Git available
    # -------------------------------------------------------------------------

    # Default target directory is the current working directory
    set -l target_dir "."
    # Workspace name will be derived from positional args
    set -l workspace_name

    # Parse arguments: support either
    # - 1 arg: workspace_name (target_dir defaults to ".")
    # - 2 args: target_dir workspace_name
    if test (count $argv) -eq 1
        # Single positional becomes the workspace name
        set workspace_name $argv[1]
    else if test (count $argv) -eq 2
        # First positional is target directory, second is name
        set target_dir $argv[1]
        set workspace_name $argv[2]
    else
        echo ""
        echo "Usage: create_rust_workspace [target_dir] workspace_name"
        echo ""
        echo "Example:"
        echo "  create_rust_workspace myworkspace"
        echo "  create_rust_workspace ~/Projects coolsuite"
        return 1
    end

    # Resolve absolute path for deterministic layout
    set -l abs_target_dir (realpath $target_dir)
    # Final workspace directory path
    set -l workspace_dir $abs_target_dir/$workspace_name

    echo "Creating Rust workspace '$workspace_name' in '$workspace_dir' ..."
    mkdir -p $workspace_dir

    # Initialize Cargo workspace
    # Create top-level folders commonly used across multi-crate repos
    echo "Creating Cargo workspace structure ..."
    mkdir -p $workspace_dir/{crates,examples,docs,scripts,.github/workflows,.devcontainer}
    echo "done"

    # Create workspace Cargo.toml
    # - members: default crates included in the workspace
    # - resolver = "2": modern feature resolver
    # - [workspace.dependencies]: shared versions
    echo "Creating Cargo.toml ..."
    begin
        echo "[workspace]"
        echo "members = ["
        echo "    \"crates/core\"," 
        echo "    \"crates/cli\"," 
        echo "    \"crates/utils\""
        echo "]"
        echo "resolver = \"2\""
        echo ""
        echo "[workspace.dependencies]"
        echo "anyhow = \"1\""
        echo "thiserror = \"2\""
        echo "log = \"0.4\""
        echo "serde = { version = \"1\", features = [\"derive\"] }"
    end > $workspace_dir/Cargo.toml

    # Shared config files
    # rustfmt/clippy provide consistent formatting and lint rules across crates
    echo "Creating shared configuration files ..."
    begin
        echo "edition = \"2021\""
        echo "max_width = 100"
        echo "use_field_init_shorthand = true"
        echo "use_small_heuristics = \"Max\""
    end > $workspace_dir/rustfmt.toml

    begin
        echo "warn = [\"clippy::pedantic\", \"clippy::nursery\"]"
        echo "allow = [\"clippy::module_name_repetitions\"]"
    end > $workspace_dir/clippy.toml

    begin
        echo "root = true"
        echo ""
        echo "[*]"
        echo "charset = utf-8"
        echo "end_of_line = lf"
        echo "insert_final_newline = true"
        echo "indent_style = space"
        echo "indent_size = 4"
    end > $workspace_dir/.editorconfig

    # .gitignore
    # Keep build artifacts and editor files out of version control
    echo "Creating .gitignore ..."
    begin
        echo "target/"
        echo "Cargo.lock"
        echo ".DS_Store"
        echo ".idea/"
        echo ".vscode/"
    end > $workspace_dir/.gitignore

    # LICENSE & README
    # MIT license boilerplate and an initial README with the workspace name
    echo "Creating LICENSE and README ..."
    set current_year (date +%Y)
    begin
        echo "MIT License"
        echo ""
        echo "Copyright (c) $current_year"
        echo ""
        echo "Permission is hereby granted, free of charge, to any person obtaining a copy"
        echo "of this software and associated documentation files (the \"Software\"), to deal"
        echo "in the Software without restriction..."
    end > $workspace_dir/LICENSE

    begin
        echo "# $workspace_name"
    end > $workspace_dir/README.md

    # Makefile
    # Simple phony targets for common tasks over the entire workspace
    echo "Creating Makefile ..."
    begin
        echo ".PHONY: build test fmt lint audit"
        echo ""
        echo "build:"
        echo "\tcargo build --workspace"
        echo ""
        echo "test:"
        echo "\tcargo test --workspace"
        echo ""
        echo "fmt:"
        echo "\tcargo fmt --all"
        echo ""
        echo "lint:"
        echo "\tcargo clippy --workspace -- -D warnings"
        echo ""
        echo "audit:"
        echo "\tcargo audit || true"
        echo "\tcargo deny check licenses || true"
    end > $workspace_dir/Makefile

    # Create sub-crates
    # - core: library crate for shared logic
    # - cli: binary crate as entrypoint
    # - utils: library crate for utilities/helpers
    echo "Creating default crates ..."
    cargo new --lib $workspace_dir/crates/core
    cargo new --bin $workspace_dir/crates/cli
    cargo new --lib $workspace_dir/crates/utils
    echo "done"

    # Update CLI main.rs
    # Minimal main that compiles and prints a greeting
    echo "Configuring CLI entrypoint ..."
    begin
        echo "use anyhow::Result;"
        echo ""
        echo "fn main() -> Result<()> {"
        echo "    println!(\"Hello from CLI!\");"
        echo "    Ok(())"
        echo "}"
    end > $workspace_dir/crates/cli/src/main.rs

    # Add Devcontainer
    # Devcontainer pre-installs Rust tooling and runs a workspace build on create
    echo "Creating Devcontainer setup ..."
    begin
        echo "{"
        echo "    \"name\": \"Rust Workspace Dev\"," 
        echo "    \"image\": \"mcr.microsoft.com/devcontainers/rust:latest\"," 
        echo "    \"features\": {"
        echo "        \"ghcr.io/devcontainers/features/common-utils:2\": {}"
        echo "    },"
        echo "    \"postCreateCommand\": \"cargo build --workspace\"," 
        echo "    \"customizations\": {"
        echo "        \"vscode\": {"
        echo "            \"extensions\": ["
        echo "                \"rust-lang.rust-analyzer\"," 
        echo "                \"tamasfe.even-better-toml\""
        echo "            ]"
        echo "        }"
        echo "    }"
        echo "}"
    end > $workspace_dir/.devcontainer/devcontainer.json

    # CI Workflow
    # GitHub Actions pipeline to build/test/lint/format-check on pushes and PRs
    echo "Creating CI workflow ..."
    begin
        echo "name: Rust Workspace CI"
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
        echo "        run: cargo build --workspace --verbose"
        echo "      - name: Test"
        echo "        run: cargo test --workspace --verbose"
        echo "      - name: Lint"
        echo "        run: cargo clippy --workspace -- -D warnings"
        echo "      - name: Format check"
        echo "        run: cargo fmt --all -- --check"
    end > $workspace_dir/.github/workflows/ci.yml

    # Initialize git
    # Only init if not already a repo (idempotency)
    if not test -d $workspace_dir/.git
        echo "Initializing git repository ..."
        cd $workspace_dir
        git init
        git add .
        git commit -m "Initial Rust workspace setup"
        echo "done"
    end

    # Optional: install audit tools
    # Install only when missing to avoid unnecessary work
    echo "Installing optional cargo tools (if missing) ..."
    for tool in cargo-audit cargo-deny
        if not type -q $tool
            echo "Installing $tool ..."
            cargo install $tool ^/dev/null
        end
    end

    # Initial formatting and build
    echo "Running cargo fmt and build ..."
    cd $workspace_dir
    cargo fmt
    cargo build --workspace
    echo "done"

    echo ""
    echo "✅ Rust workspace '$workspace_name' created successfully!"
    echo "Location: $workspace_dir"
    echo ""
    echo "To start developing:"
    echo "  cd $workspace_dir"
    echo "  cargo run -p cli"
end
