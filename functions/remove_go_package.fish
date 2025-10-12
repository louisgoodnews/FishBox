function remove_go_package
    # -------------------------------------------------------------------------
    # remove_go_package (Fish Shell)
    #
    # Usage:
    #   remove_go_package [project_path] package_name [--internal]
    #
    # Examples:
    #   remove_go_package ~/Projects/myapp parser --internal
    #   remove_go_package ~/Projects/myapp math
    # -------------------------------------------------------------------------

    if test (count $argv) -lt 2
        echo "Usage: remove_go_package [project_path] package_name [--internal]"
        return 1
    end

    set -l proj_dir $argv[1]
    set -l pkg_name $argv[2]
    set -l internal 0

    for arg in $argv[3..-1]
        switch $arg
            case "--internal"
                set internal 1
        end
    end

    if test $internal -eq 1
        set pkg_dir $proj_dir/internal/$pkg_name
    else
        set pkg_dir $proj_dir/pkg/$pkg_name
    end

    if not test -d $pkg_dir
        echo "⚠️ Package '$pkg_name' does not exist at $pkg_dir"
        return 1
    end

    rm -rf $pkg_dir
    echo "🗑️ Package '$pkg_name' removed from $pkg_dir"
end
