function update
    # -------------------------------------------------------------------------
    # update (fish shell function)
    #
    # Description:
    #   Orchestrates system updates using one or more package managers.
    #
    # Usage:
    #   update [target]
    #
    # Arguments:
    #   target (optional): Which manager to update. One of:
    #     - "-all" (default) or empty string: run all supported managers
    #     - "pacman" | "yay" | "paru" | "flatpak": run only that manager
    #
    # Return codes:
    #   0  All requested updates completed (even if some managers were skipped
    #      because they are not installed)
    #   1  Invalid argument or at least one requested manager failed to update
    #
    # Examples:
    #   update               # run all managers
    #   update -all          # explicit all
    #   update pacman        # only pacman
    #   update yay           # only yay
    #   update paru          # only paru
    #   update flatpak       # only flatpak
    #
    # Notes on concurrency:
    #   - `pacman` is executed first and synchronously to avoid potential
    #     database locks and to ensure system libs are updated before AUR.
    #   - AUR helpers and `flatpak` are executed in background jobs and then
    #     synchronized via `wait`.
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # cecho
    #
    # Description:
    #   Minimal helper for colored line output using ANSI escape codes.
    #   Prints the provided text followed by a newline.
    #
    # Usage:
    #   cecho <color> <text>
    #
    # Arguments:
    #   color: one of red|green|yellow|blue (anything else results in default)
    #   text : full message string to print
    #
    # Notes:
    #   - Uses 31/32/33/34 for colors and 0 for default.
    #   - Keeps output consistent across the script.
    # -------------------------------------------------------------------------
    function cecho
        set color $argv[1]
        set text $argv[2]
        switch $color
            case red; set code 31
            case green; set code 32
            case yellow; set code 33
            case blue; set code 34
            case '*'; set code 0
        end
        printf "\e[%sm%s\e[0m\n" $code $text
    end

    # -------------------------------------------------------------------------
    # try_update
    #
    # Description:
    #   Best-effort wrapper that checks if a package manager exists and, if so,
    #   executes its update command. Emits user-friendly progress and error
    #   messages via `cecho`.
    #
    # Usage:
    #   try_update <manager_name> <command_string>
    #
    # Arguments:
    #   manager_name   Name of the executable to check with `type -q`.
    #   command_string Full update command to run when the manager is present.
    #
    # Return codes:
    #   0  Manager is absent (skip) or command launched successfully
    #   1  Manager present but command failed to execute
    #
    # Notes:
    #   - Called in both foreground and background contexts from `update`.
    #   - The actual update command string is executed by fish's command
    #     substitution. If it fails, a red error line is printed.
    # -------------------------------------------------------------------------
    function try_update
        set mgr $argv[1]
        set cmd $argv[2]

        if type -q $mgr
            # Inform user which manager is running
            cecho blue "Updating $mgr..."
            # Execute the provided update command. If it fails, report and
            # bubble up a non-zero status so callers can track failures.
            if not $cmd
                cecho red "Failed to update $mgr!"
                return 1
            end
        else
            # Manager not present: this is not an error for the orchestration,
            # so we just inform the user and continue.
            cecho yellow "$mgr not installed, skipping."
        end
    end

    # Determine the target from the first CLI argument; default to "-all" so the
    # function is convenient to run without parameters.
    set target (or $argv[1] "-all")

    # Collect names of managers whose updates fail. Used for a final summary.
    set failed_managers ""

    # Dispatch based on the requested target.
    switch $target
        case "-all" ""
            # Update pacman first (not in parallel) to avoid lock/contention
            # issues and to ensure base system packages are up to date.
            if not try_update pacman "sudo pacman -Syu"
                set failed_managers $failed_managers pacman
            end

            # Parallelize AUR/Flatpak updates. Background jobs cannot modify
            # parent variables reliably, so collect failures in a temp file.
            set -l tmp_fail (mktemp)
            # Each job writes its name to tmp_fail if it fails
            begin; try_update yay "yay -Syu"; or echo yay >> $tmp_fail; end &
            begin; try_update paru "paru -Syu"; or echo paru >> $tmp_fail; end &
            begin; try_update flatpak "flatpak update -y"; or echo flatpak >> $tmp_fail; end &
            wait
            if test -s $tmp_fail
                set failed_managers $failed_managers (cat $tmp_fail)
            end
            rm -f $tmp_fail
        case "pacman"
            if not try_update pacman "sudo pacman -Syu"
                set failed_managers $failed_managers pacman
            end
        case "yay"
            if not try_update yay "yay -Syu"
                set failed_managers $failed_managers yay
            end
        case "paru"
            if not try_update paru "paru -Syu"
                set failed_managers $failed_managers paru
            end
        case "flatpak"
            if not try_update flatpak "flatpak update -y"
                set failed_managers $failed_managers flatpak
            end
        case '*'
            cecho red "Unknown argument: $target"
            cecho blue "Usage: update [target]"
            cecho blue "Example: update -all"
            return 1
    end

    # Print a concise summary of outcomes for visibility.
    if test (count $failed_managers) -gt 0
        cecho red "Update failed for: $failed_managers"

        return 1
    else
        cecho green "All updates successful!"
    end

    return 0
end
