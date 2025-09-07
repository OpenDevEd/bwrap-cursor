# bwrapper

A generic bwrap sandboxing helper that uses configuration files to define how applications should be sandboxed.

## Features

- **Configuration-based**: Define sandboxing rules in simple configuration files
- **Generic**: Works with any application, not just Cursor
- **Secure**: Built-in security checks to prevent dangerous operations
- **Editable**: Use `--edit` flag to modify configurations with your preferred editor
- **Flexible**: Support for environment variables, bind mounts, and custom bwrap arguments

## Usage

```bash
# Run an application with a configuration
./bwrapper <config> [files...]

# Edit a configuration
./bwrapper --edit <config>

# List available configurations
./bwrapper --list

# Show help
./bwrapper --help
```

## Example: Running Cursor

```bash
# Open current directory in Cursor
./bwrapper cursor

# Open specific directory
./bwrapper cursor /path/to/project

# Open specific file
./bwrapper cursor /path/to/file.txt

# Open multiple files/projects
./bwrapper cursor /path/to/project /path/to/file.txt /path/to/project2
```

## Configuration Files

Configuration files are stored in `./configurations/` and use a simple YAML-like format. The script provides sensible defaults, so you only need to specify what's different:

```yaml
# Application to run
executable: /usr/bin/cursor
args: []

# Read-write paths (only what needs to be writable)
rw_paths: []
  - $HOME/.config/Cursor
  - $HOME/.cache/Cursor
```

## Configuration Options

- **executable**: Path to the program to run (required)
- **args**: Array of default arguments to pass to the program (optional)
- **rw_paths**: Array of paths to bind read-write (optional)
- **additional_bwrap_args**: Array of additional arguments to pass to bwrap (optional)
- **env_vars**: Hash of custom environment variables to set (optional)

## Default Behavior

The script automatically provides:
- **Read-only filesystem**: Entire host filesystem is mounted read-only (`--ro-bind / /`)
- **Essential system paths**: `/proc`, `/dev`, `/tmp` are properly mounted
- **Environment variables**: `DISPLAY`, `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, `HOME`, `DBUS_SESSION_BUS_ADDRESS`
- **X11/GPU passthrough**: X11 sockets and GPU devices are automatically detected and bound
- **Security checks**: Prevents opening high-level system directories
- **Project directory**: The current directory or specified path is always writable

## Security Features

- **Root directory protection**: Prevents opening high-level system directories
- **Environment variable expansion**: Safe expansion of `$VAR` syntax
- **Minimal bind mounts**: Only necessary directories are made writable

## Creating New Configurations

1. Create a new `.conf` file in the `configurations/` directory
2. Define the application and its sandboxing requirements
3. Use `./bwrapper --edit <config>` to modify it
4. Test with `./bwrapper <config>`

## Migration from bcursor.sh

The included `cursor.conf` provides the same functionality as the original `bcursor.sh` script, but with the flexibility to easily modify the sandboxing behavior.

## Verification

Use the included comparison script to verify that `bwrapper cursor` produces identical results to `bcursor.sh`:

```bash
# Compare both scripts
./compare-scripts.sh

# Compare with specific files
./compare-scripts.sh file1.txt file2.txt project
```

## Requirements

- Perl 5.x
- bwrap (bubblewrap)
- A text editor (nano, vi, or your preferred editor via $EDITOR)
