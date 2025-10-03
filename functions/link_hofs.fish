function link_hofs --description "Places symlinks for .hof files in all OMSI2 vehicle folders"
    # Basisverzeichnisse
    set -l base "/data/nvme1n1/louisgoodnews/steamapps/common/OMSI 2/Vehicles"
    set -l source "$base/.hofdateien"

    # optionales Dry-Run-Flag
    set -l DRY 0
    for a in $argv
        if test $a = "--dry-run"
            set DRY 1
        end
    end

    # Prüfungen
    if not test -d "$base"
        echo "Fehler: Base-Ordner nicht gefunden: $base" >&2
        return 1
    end

    if not test -d "$source"
        echo "Fehler: Source-Ordner nicht gefunden: $source" >&2
        return 1
    end

    # Liste aller .hof-Dateien im source (robust bzgl. Leerzeichen)
    set -l src_list (find "$source" -maxdepth 1 -type f -name '*.hof' -print0 | string split0)
    if test (count $src_list) -eq 0
        echo "Keine .hof-Dateien im Source-Ordner: $source"
        return 0
    end

    for dir in $base/*
        # nur Verzeichnisse bearbeiten
        if not test -d "$dir"
            continue
        end

        # Source-Ordner überspringen
        if test (basename $dir) = ".hofdateien"
            continue
        end

        # Prüfen, ob im aktuellen Zielordner überhaupt .hof-Dateien vorhanden sind
        set -l any_hof (find "$dir" -maxdepth 1 -type f -name '*.hof' -print -quit)
        if test -z "$any_hof"
            continue
        end

        echo "Bearbeite: $dir"

        # vorhandene .hof-Dateien löschen (nur reguläre Dateien, keine Symlinks)
        set -l del_list (find "$dir" -maxdepth 1 -type f -name '*.hof' -print0 | string split0)
        for f in $del_list
            if test $DRY -eq 1
                echo "  DRY: löschen: $f"
            else
                echo "  Lösche: $f"
                rm -- "$f"
            end
        end

        # für jede .hof im source einen Symlink anlegen, falls Ziel noch nicht existiert
        for src in $src_list
            set -l base_name (basename $src)
            set -l target "$dir/$base_name"
            if not test -e "$target"
                if test $DRY -eq 1
                    echo "  DRY: ln -s $src $target"
                else
                    ln -s "$src" "$target"
                    echo "  Link erstellt: $target"
                end
            else
                echo "  Überspringe (existiert): $target"
            end
        end
    end
end
