# bwrapper

A generic bwrap sandboxing helper that uses configuration files to define how applications should be sandboxed.

## Features

- **Configuration-based**: Define sandboxing rules in simple configuration files
- **Generic**: Works with any application, not just Cursor
- **Secure**: Built-in security checks to prevent dangerous operations
- **Editable**: Use `--edit` flag to modify configurations with your preferred editor
- **Flexible**: Support for environment variables, bind mounts, and custom bwrap arguments

## Usage

Config-based usage:
```bash
# Run an application with a configuration
./bwrapper <config> [files...]

# Edit a configuration
./bwrapper --edit <config>

# List available configurations
./bwrapper --list

```

Command-line arguments
```bash
# Run an application with command-line options
./bwrapper --exec <program> [options] [files...]


# Save a config for reuse:
./bwrapper --exec <program> [options] --save config
```

Help:
```bash
# Show help
./bwrapper --help
```

## Examples

### Example without home directory isolation


```bash
# Create test directories
mkdir path1 path2 

# Run bash with isolated home
./bwrapper --exec bash path1 path2
```

You should find that `path1` and `path2` are writable, but anything else is not.

### Complex example: Running cursor with explicit command line arguments

```bash
# Basic command-line usage
./bwrapper --exec /usr/bin/cursor /path/to/project

# With specific Cursor arguments
./bwrapper --exec /usr/bin/cursor --arg=-a --arg=-b /path/to/project

# With read-write paths for Cursor's config and cache
./bwrapper --exec /usr/bin/cursor \
  --rw=$HOME/.config/Cursor \
  --rw=$HOME/.cache/Cursor \
  /path/to/project

# With environment variables
./bwrapper --exec /usr/bin/cursor \
  --env=DISPLAY=:0 \
  --env=WAYLAND_DISPLAY=wayland-0 \
  /path/to/project

# With isolated home directory
./bwrapper --exec /usr/bin/cursor \
  --home ~/cursor-sandbox \
  /path/to/project

# With work subdirectory
./bwrapper --exec /usr/bin/cursor \
  --home ~/cursor-sandbox \
  --work projects \
  /path/to/project1 /path/to/project2

# Save configuration for reuse
./bwrapper --exec /usr/bin/cursor \
  --home ~/cursor-sandbox \
  --work projects \
  --rw=$HOME/.config/Cursor \
  --rw=$HOME/.cache/Cursor \
  --save cursor_2

# Use saved configuration
./bwrapper cursor_2 /path/to/project
```


### Running Cursor from the ready-made 'cursor profile'

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



### Home Directory Isolation

The `--home` option creates an isolated home directory, hiding your real `$HOME` and mounting specified files/directories in the sandbox.

#### Basic Home Isolation

```bash
# Create test directories
mkdir path1 path2 sandbox-home

# Run bash with isolated home
./bwrapper --exec bash --home sandbox-home path1 path2

# Inside the sandbox, run:
find ~
```

**Output:**
```
/home/app
/home/app/path1
/home/app/path2
```

Your real home directory is completely hidden, and `path1` and `path2` are mounted as `/home/app/path1` and `/home/app/path2`.

#### Home Isolation with Work Directory

```bash
# Create test directories
mkdir project1 project2 sandbox-home

# Run bash with work subdirectory
./bwrapper --exec bash --home sandbox-home --work work project1 project2

# Inside the sandbox, run:
find ~
```

**Output:**
```
/home/app
/home/app/work
/home/app/work/project1
/home/app/work/project2
```

Files are now organized under `/home/app/work/` instead of directly in the home directory.

#### Comparison: With vs Without Home Isolation

**Without `--home` (normal mode):**
```bash
# Run bash normally
./bwrapper --exec bash /path/to/project

# Inside sandbox:
ls ~
# Shows your real home directory contents
pwd
# Shows /path/to/project (mounted read-write)
```

**With `--home`:**
```bash
# Run bash with isolated home
./bwrapper --exec bash --home ~/sandbox-home /path/to/project

# Inside sandbox:
ls ~
# Shows only /home/app (your isolated home)
ls ~/project
# Shows the project files
echo $HOME
# Shows /home/app (not your real home)
```

### Command-Line Options

```bash
# Basic command-line usage
./bwrapper --exec /usr/bin/cursor --arg=-a --arg=-b /path/to/project

# With read-write paths
./bwrapper --exec /usr/bin/cursor --rw=$HOME/.config/app --rw=$HOME/.cache/app /path/to/project

# With environment variables
./bwrapper --exec /usr/bin/cursor --env=DEBUG=1 --env=LOG_LEVEL=debug /path/to/project

# Save configuration for reuse
./bwrapper --exec /usr/bin/cursor --home ~/myhome --work projects --save myconfig

# Use saved configuration
./bwrapper myconfig /path/to/project
```

### Advanced Examples

#### Development Environment

```bash
# Create isolated development environment
mkdir -p ~/dev-home/{projects,configs,cache}

# Run development tools with isolated home
./bwrapper --exec bash --home ~/dev-home --work projects \
  /path/to/project1 /path/to/project2 /path/to/project3

# Inside sandbox:
# - Real home is hidden
# - Projects are at ~/projects/project1, ~/projects/project2, etc.
# - Config files go to ~/configs/
# - Cache files go to ~/cache/
```

#### Testing with Different Configurations

```bash
# Test application with different home directories
./bwrapper --exec myapp --home ~/test-home-1 /test/data1
./bwrapper --exec myapp --home ~/test-home-2 /test/data2

# Each run gets a completely isolated environment
```

#### File Organization

```bash
# Organize files by category
mkdir -p ~/work-home/{docs,code,data}

./bwrapper --exec bash --home ~/work-home --work docs /path/to/documentation
./bwrapper --exec bash --home ~/work-home --work code /path/to/source-code
./bwrapper --exec bash --home ~/work-home --work data /path/to/datasets
```

## Practical Demonstrations

### Demonstration 1: Basic Home Isolation

```bash
# Create test directories
mkdir path1 path2 sandbox-home

# Run bash with isolated home
./bwrapper --exec bash --home sandbox-home path1 path2

# Inside the sandbox, run:
find ~
```

**Expected output:**
```
/home/app
/home/app/path1
/home/app/path2
```

**What happened:**
- Your real home directory is completely hidden
- `sandbox-home` becomes the sandbox home at `/home/app`
- `path1` and `path2` are mounted as `/home/app/path1` and `/home/app/path2`
- `$HOME` is set to `/home/app`

### Demonstration 2: Work Subdirectory

```bash
# Create test directories
mkdir project1 project2 sandbox-home

# Run bash with work subdirectory
./bwrapper --exec bash --home sandbox-home --work work project1 project2

# Inside the sandbox, run:
find ~
```

**Expected output:**
```
/home/app
/home/app/work
/home/app/work/project1
/home/app/work/project2
```

**What happened:**
- Files are organized under `/home/app/work/` instead of directly in home
- `project1` becomes `/home/app/work/project1`
- `project2` becomes `/home/app/work/project2`

### Demonstration 3: Comparison - With vs Without Home Isolation

**Without `--home` (normal mode):**
```bash
# Run bash normally
./bwrapper --exec bash /path/to/project

# Inside sandbox:
ls ~
# Shows your real home directory contents
echo $HOME
# Shows your real home path
pwd
# Shows /path/to/project
```

**With `--home`:**
```bash
# Run bash with isolated home
./bwrapper --exec bash --home ~/sandbox-home /path/to/project

# Inside sandbox:
ls ~
# Shows only /home/app (your isolated home)
echo $HOME
# Shows /home/app (not your real home)
ls ~/project
# Shows the project files
```

### Demonstration 4: File Conflicts and Validation

```bash
# This will work - different basenames
./bwrapper --exec bash --home sandbox-home /path/to/project1 /path/to/project2

# This will fail - same basename
./bwrapper --exec bash --home sandbox-home /path/to/project1 /different/path/project1
# Error: Final directories would not be distinct: '/home/app/project1'
```

### Demonstration 5: Environment Variables

```bash
# Run with custom environment
./bwrapper --exec bash --home sandbox-home --env=TEST_VAR=hello --env=DEBUG=1 path1

# Inside sandbox:
echo $TEST_VAR
# Output: hello
echo $DEBUG
# Output: 1
echo $HOME
# Output: /home/app
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
- **home_path**: Custom home directory for isolation (optional)
- **work_path**: Work subdirectory within home (optional, requires home_path)

## Command-Line Options

When using `--exec`, you can specify options directly:

- **--exec <program>**: Program to execute in the sandbox
- **--arg <argument>**: Add argument to pass to the program (can be used multiple times)
- **--rw <path>**: Add read-write path to bind (can be used multiple times)
- **--env <key=value>**: Set environment variable (can be used multiple times)
- **--home <path>**: Use custom home directory (isolates $HOME)
- **--work <path>**: Mount files under work subdirectory (requires --home)
- **--save <config>**: Save CLI options as configuration file
- **--dryrun**: Show the command that would be executed

## Default Behavior

The script automatically provides:
- **Read-only filesystem**: Entire host filesystem is mounted read-only (`--ro-bind / /`)
- **Essential system paths**: `/proc`, `/dev`, `/tmp` are properly mounted
- **Environment variables**: `DISPLAY`, `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, `HOME`, `DBUS_SESSION_BUS_ADDRESS`
- **X11/GPU passthrough**: X11 sockets and GPU devices are automatically detected and bound
- **Security checks**: Prevents opening high-level system directories
- **Project directory**: The current directory or specified path is always writable

### Home Isolation Behavior

When using `--home`:

- **Real home hidden**: Your actual `$HOME` directory is completely hidden
- **Isolated home**: The specified home directory becomes `/home/app` in the sandbox
- **File mounting**: Specified files/directories are mounted using their basename
- **Work subdirectory**: With `--work`, files are mounted under `/home/app/work/`
- **Environment**: `$HOME` is set to `/home/app` inside the sandbox
- **Validation**: Ensures final directory names are distinct to prevent conflicts

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
