function remove_crate_from_workspace
    # -------------------------------------------------------------------------
    # remove_crate_from_workspace (fish shell function)
    #
    # Description:
    #   Removes a crate from a Rust workspace, cleans up Cargo.toml, and
    #   removes all dependency references from other crates automatically.
    #
    # Usage:
    #   remove_crate_from_workspace [workspace_path] crate_name
    #
    # Examples:
    #   remove_crate_from_workspace mylib
    #   remove_crate_from_workspace ~/Projects/coolsuite parser
    #
    # Features:
    #   ✅ Removes crate folder under crates/
    #   ✅ Removes crate path from workspace Cargo.toml members
    #   ✅ Cleans up dependency references in all other Cargo.toml files
    #   ✅ Commits removal if inside a git repository
    # -------------------------------------------------------------------------

    # Default workspace path is current directory unless provided
    set -l workspace_path "."
    # Crate name to remove (positional argument)
    set -l crate_name

    # Argument parsing
    # - 1 arg: crate_name (workspace_path defaults to ".")
    # - 2 args: workspace_path crate_name
    if test (count $argv) -eq 1
        set crate_name $argv[1]
    else if test (count $argv) -eq 2
        set workspace_path $argv[1]
        set crate_name $argv[2]
    else
        echo ""
        echo "Usage: remove_crate_from_workspace [workspace_path] crate_name"
        echo ""
        echo "Example:"
        echo "  remove_crate_from_workspace mylib"
        echo "  remove_crate_from_workspace ~/Projects/coolsuite parser"
        return 1
    end

    # Resolve absolute paths for deterministic operations
    set -l abs_workspace (realpath $workspace_path)
    set -l crates_dir $abs_workspace/crates
    set -l crate_dir $crates_dir/$crate_name
    set -l cargo_file $abs_workspace/Cargo.toml

    # Validation
    # Ensure this is a valid Rust workspace with a top-level Cargo.toml
    if not test -f $cargo_file
        echo "❌ Error: No Cargo.toml found at $abs_workspace"
        return 1
    end

    if not grep -q "^\[workspace\]" $cargo_file
        echo "❌ Error: This directory is not a Rust workspace."
        return 1
    end

    if not test -d $crate_dir
        echo "⚠️ Warning: Crate '$crate_name' does not exist at $crate_dir"
        return 1
    end

    echo "🗑️ Removing crate '$crate_name' from workspace ..."
    rm -rf $crate_dir
    echo "✅ Crate folder removed."

    # Remove from workspace Cargo.toml
    # Use awk to drop the crate path from the `members = [ ... ]` array:
    # - Track when inside the members array (in_members)
    # - Print all lines except those matching the removed crate path
    echo "Updating workspace Cargo.toml ..."
    set -l tmpfile (mktemp)
    awk -v crate_path="crates/$crate_name" '
        /^\s*members\s*=\s*\[/ {
            print $0
            next
        }
        /\[workspace\]/ || /^\s*members\s*=\s*\[/ {
            in_members=1
        }
        in_members && /^\]/ {
            in_members=0
        }
        !in_members || $0 !~ crate_path
    ' $cargo_file > $tmpfile
    mv $tmpfile $cargo_file
    echo "✅ Removed from workspace members."

    # Remove from dependencies in other crates
    # Iterate all `Cargo.toml` files under `crates/` and remove any
    # dependency lines for the removed crate under a [dependencies] section.
    echo "Cleaning up dependencies ..."
    for toml in (find $crates_dir -name Cargo.toml)
        if grep -q "^$crate_name" $toml
            echo "  → Removing dependency from (basename (dirname $toml))"
            awk -v crate="$crate_name" '
                /^\[dependencies\]/ {in_dep=1; print; next}
                /^\[/ && $0 !~ /\[dependencies\]/ {in_dep=0}
                !(in_dep && $1 == crate)
            ' $toml > $toml.tmp
            mv $toml.tmp $toml
        end
    end
    echo "✅ Dependency cleanup complete."

    # Git commit
    # Commit changes if the workspace is a git repository
    if test -d $abs_workspace/.git
        echo "Committing changes to git ..."
        cd $abs_workspace
        git add -A
        git commit -m "Removed crate '$crate_name' from workspace"
        echo "✅ Git commit complete."
    end

    # Optional: rebuild to verify integrity
    echo "Rebuilding workspace ..."
    cd $abs_workspace
    cargo build --workspace
    echo "✅ Workspace rebuilt successfully."

    echo ""
    echo "✅ Crate '$crate_name' removed successfully!"
end
