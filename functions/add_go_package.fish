function add_go_package
    # -------------------------------------------------------------------------
    # add_go_package (Fish Shell)
    #
    # Usage:
    #   add_go_package [project_path] package_name [--internal] [--with-test]
    #
    # Examples:
    #   add_go_package ~/Projects/myapp parser --internal --with-test
    #   add_go_package ~/Projects/myapp math
    #
    # Flags:
    #   --internal  → create package in internal/
    #   --with-test → create a *_test.go file
    # -------------------------------------------------------------------------

    if test (count $argv) -lt 2
        echo "Usage: add_go_package [project_path] package_name [--internal] [--with-test]"
        return 1
    end

    set -l proj_dir $argv[1]
    set -l pkg_name $argv[2]
    set -l internal 0
    set -l with_test 0

    for arg in $argv[3..-1]
        switch $arg
            case "--internal"
                set internal 1
            case "--with-test"
                set with_test 1
        end
    end

    if test $internal -eq 1
        set pkg_dir $proj_dir/internal/$pkg_name
    else
        set pkg_dir $proj_dir/pkg/$pkg_name
    end

    if test -d $pkg_dir
        echo "⚠️ Package '$pkg_name' already exists at $pkg_dir"
        return 1
    end

    mkdir -p $pkg_dir

    # Template Go file
    begin
        echo "package $pkg_name"
        echo ""
        echo "func Hello() string {"
        echo "    return \"Hello from $pkg_name!\""
        echo "}"
    end > $pkg_dir/$pkg_name.go
    echo "✅ Package '$pkg_name' created at $pkg_dir"

    # Optional test file
    if test $with_test -eq 1
        begin
            echo "package $pkg_name"
            echo ""
            echo "import \"testing\""
            echo ""
            echo "func TestHello(t *testing.T) {"
            echo "    if Hello() != \"Hello from $pkg_name!\" {"
            echo "        t.Fatal(\"Test failed for $pkg_name.Hello()\")"
            echo "    }"
            echo "}"
        end > $pkg_dir/${pkg_name}_test.go
        echo "✅ Test file created for package '$pkg_name'"
    end
end
