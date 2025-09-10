# FishBox

FishBox is a personal repository for all your custom [Fish shell](https://fishshell.com/) scripts.  
It provides a central location to store, organize, and share functions, completions, scripts, and helper tools across multiple devices.

---

## Purpose

FishBox is designed to:

- Serve as a library of custom Fish shell functions for any purpose.
- Keep all scripts and completions organized in a consistent structure.
- Make it easy to sync and use your Fish scripts on multiple machines.
- Provide a place for tests, documentation, and helper scripts related to your Fish setup.

---

## Project Structure

```
FishBox/
├── functions/          # Custom Fish functions
├── completions/        # Custom completions for your commands
├── conf.d/             # Loader to automatically source functions & completions
├── scripts/            # Standalone executable scripts
├── tests/              # Test scripts for your functions
├── docs/               # Documentation and usage instructions
├── .gitignore          # Ignore temporary/system files
├── CONTRIBUTING.md     # Guidelines for contributing (optional)
├── CHANGELOG.md        # Track changes and updates
├── NEXT_STEPS.md       # Instructions for setting up and using FishBox
└── LICENSE             # License for your code
```

---

## Getting Started

1. **Clone the repository** to your local machine:

```fish
git clone <your-git-repo-url> ~/Projects/FishBox
```

2. **Source the loader** in your Fish configuration (`~/.config/fish/config.fish`):

```fish
source ~/Projects/FishBox/conf.d/FishBox.fish
```

3. **Use your custom functions and scripts** immediately:

```fish
# Example
hello
```

4. **Add new scripts or functions** to the respective directories to extend FishBox.

---

## Recommended Workflow

- Organize functions in `functions/` and completions in `completions/`.
- Keep scripts executable in `scripts/` with the proper shebang (`#!/usr/bin/env fish`).
- Test your functions using scripts in `tests/`.
- Update documentation in `docs/` for reference or sharing.
- Commit and push changes to sync across devices.

---

## Contribution

FishBox is primarily personal, but feel free to adapt or extend it.  
If collaborating with others, update `CONTRIBUTING.md` and follow best practices for Git.

---

## License

Specify your preferred license, e.g., MIT License.
