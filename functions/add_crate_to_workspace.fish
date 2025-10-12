function add_crate_to_workspace
    # -------------------------------------------------------------------------
    # add_crate_to_workspace (fish shell function)
    #
    # Description:
    #   Adds a new crate (library or binary) to an existing Rust workspace,
    #   automatically updates Cargo.toml, and optionally links it into other crates.
    #
    # Usage:
    #   add_crate_to_workspace [--lib|--bin] [workspace_path] crate_name [--link crate1 crate2 ...]
    #
    # Examples:
    #   add_crate_to_workspace mylib
    #   add_crate_to_workspace --lib ~/Projects/coolsuite utils
    #   add_crate_to_workspace --lib ~/Projects/coolsuite data_parser --link core cli
    #
    # Features:
    #   ✅ Automatically adds new crate under crates/
    #   ✅ Updates workspace Cargo.toml members list
    #   ✅ Optionally links new crate into specified other workspace crates
    #   ✅ Auto-commits changes (if git is initialized)
    #   ✅ Builds workspace to verify integrity
    #
    # Requirements:
    #   - Rust & Cargo installed
    #   - Must be executed inside or point to a valid workspace directory
    # -------------------------------------------------------------------------

    # Default crate type is library unless overridden by --bin
    set -l project_type "--lib"
    # Default workspace path is the current directory when not provided
    set -l workspace_path "."
    # Crate name will be read from positional args
    set -l crate_name
    # Optional list of crates to link this new crate into (after --link)
    set -l link_targets

    # Argument parsing
    set -l mode normal
    for arg in $argv
        switch $arg
            case "--lib"
                # Choose library template for the new crate
                set project_type "--lib"
            case "--bin"
                # Choose binary template for the new crate
                set project_type "--bin"
            case "--link"
                # Switch to link-collection mode: subsequent args are link targets
                set mode link
            case '*'
                if test $mode = link
                    # Collect crates that should depend on the new crate
                    set link_targets $link_targets $arg
                else if not set -q crate_name
                    # First positional is the new crate name
                    set crate_name $arg
                else if test $workspace_path = "."
                    # Second positional becomes workspace path; shift name
                    set workspace_path $crate_name
                    set crate_name $arg
                end
        end
    end

    if not set -q crate_name
        echo ""
        echo "Usage: add_crate_to_workspace [--lib|--bin] [workspace_path] crate_name [--link crate1 crate2 ...]"
        echo ""
        echo "Example:"
        echo "  add_crate_to_workspace --lib ~/Projects/coolsuite data_parser --link core cli"
        return 1
    end

    # Resolve absolute workspace path for deterministic file operations
    set -l abs_workspace (realpath $workspace_path)
    # Standard location for workspace member crates
    set -l crates_dir $abs_workspace/crates
    # New crate directory path
    set -l crate_dir $crates_dir/$crate_name
    # Root workspace Cargo.toml path
    set -l cargo_file $abs_workspace/Cargo.toml

    # Validate workspace
    if not test -f $cargo_file
        echo "❌ Error: No Cargo.toml found at $abs_workspace"
        return 1
    end

    if not grep -q "^\[workspace\]" $cargo_file
        echo "❌ Error: This directory is not a Rust workspace."
        return 1
    end

    # Create crate
    echo "Creating crate '$crate_name' ($project_type) ..."
    mkdir -p $crates_dir
    cargo new $project_type $crate_dir
    echo "done"

    # Update workspace Cargo.toml members list
    echo "Updating workspace Cargo.toml ..."
    set -l tmpfile (mktemp)

    # Add the new crate if not already present
    if not grep -q "crates/$crate_name" $cargo_file
        # Update the [workspace] members list using awk:
        # - Track whether we found a `members = [` array (added=1 if yes)
        # - If found, inject the new member before the closing bracket
        # - If not found, append a minimal members array at the end
        awk -v crate_path="crates/$crate_name" '
            BEGIN {added=0}
            /^\[workspace\]/ {print; next}
            /^\s*members\s*=\s*\[/ {
                added=1
                sub(/\]/, sprintf("    \"%s\",\n]", crate_path))
            }
            {print}
            END {
                if (!added) {
                    print "members = ["
                    print "    \"" crate_path "\""
                    print "]"
                }
            }
        ' $cargo_file > $tmpfile
        mv $tmpfile $cargo_file
    else
        echo "Crate already in workspace members list."
    end
    echo "done"

    # Handle linking to other crates
    if test (count $link_targets) -gt 0
        echo "Linking new crate into: $link_targets"
        for link_target in $link_targets
            set -l link_dir $crates_dir/$link_target
            set -l link_toml $link_dir/Cargo.toml

            if not test -f $link_toml
                echo "⚠️ Warning: Target crate '$link_target' not found, skipping."
                continue
            end

            # Check if dependency already exists
            if grep -q "^$crate_name" $link_toml
                echo "🔸 $crate_name already linked in $link_target."
                continue
            end

            # Add dependency to target crate
            echo "Linking $crate_name → $link_target ..."
            echo "" >> $link_toml
            echo "[dependencies]" >> $link_toml
            echo "$crate_name = { path = \"../$crate_name\" }" >> $link_toml
        end
        echo "done"
    end

    # Git commit if repo exists
    if test -d $abs_workspace/.git
        echo "Committing changes to git ..."
        cd $abs_workspace
        git add crates/$crate_name Cargo.toml
        git commit -m "Added crate '$crate_name' to workspace"
        echo "done"
    end

    # Build workspace
    echo "Building workspace ..."
    cd $abs_workspace
    cargo build --workspace
    echo "done"

    echo ""
    echo "✅ Crate '$crate_name' added successfully!"
    echo "Location: $crate_dir"
    if test (count $link_targets) -gt 0
        echo "Linked into: $link_targets"
    end
    echo ""
    echo "To work on it:"
    echo "  cd $crate_dir"
    echo "  cargo test"
end
