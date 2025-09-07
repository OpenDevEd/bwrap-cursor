# bwrap-cursor

# bcursor: Run the Cursor Editor in a Secure Sandbox

`bcursor` is a shell script for Ubuntu/Linux that launches the AI-native [Cursor](https://cursor.sh/) code editor within a secure, isolated filesystem sandbox using `bubblewrap` (`bwrap`).

The primary goal is to provide peace of mind. You can leverage Cursor's powerful AI features for code generation and refactoring with confidence, knowing that the application is restricted from making accidental or unwanted changes to files outside of your specified project directory.

-----

## The Rationale: Containing AI's Power

Integration of AI in software development has brought significant changes. AI is capable of understanding and executing complex commands like "refactor this module" or "remove all unused dependencies from the project." The open architecture of VSCODE has given rise to AI plugins for VSCODE, as well as forks of VSCODE like cursor. While the use of AI is incredibly powerful, this also introduces a new risk: ambiguity and malfunction.

An AI might misinterpret a broad command. A request to "clean up the project" could, in a worst-case scenario, be misinterpreted and lead to the deletion of important files in a parent directory, your home folder, or elsewhere on the system if the application has unrestricted filesystem access.

`bcursor` mitigates this risk by enforcing strict boundaries. It creates a sandboxed environment where Cursor's world is limited to only what it absolutely needs, ensuring that even an errant AI command has a contained "blast radius."

## How It Works: The Sandbox Explained

`bcursor` uses the Linux utility `bubblewrap` to construct a temporary, isolated environment for the Cursor process on-the-fly. Think of it as building a secure, virtual room for the application to run in. The rules for this room are very strict:

1.  **Default Read-Only:** The entire host filesystem, from the root (`/`) down, is mounted as **read-only**. By default, Cursor can see your files but cannot change or delete any of them. This read-only approach was chosen specifically to avoid networking issues that arise when trying to whitelist individual system directories for DNS resolution.

2.  **Creating Writable "Portholes":** The script then selectively makes a few specific locations writable. These are the only places Cursor can make changes:

      * **Your Project Directory:** The folder you are actively editing (`bcursor <your-project>`) is mounted as read-write. This is essential for you to be able to save your work.
      * **Cursor's Profile:** Your settings, extensions, and cache (`~/.config/Cursor`, `~/.cache/Cursor`, etc.) are mounted as read-write. This ensures your configuration is persistent across sessions, just like a normal installation.

3.  **Complete Isolation:** Everything else is either read-only or doesn't exist in the sandbox. The script also provides a private `/tmp` directory that is destroyed when Cursor is closed.

4.  **Controlled System Access:** To ensure Cursor functions as a proper desktop application, it is given minimal, necessary access to system services like the display server (X11/Wayland), GPU drivers for hardware acceleration, and the D-Bus for desktop integration.

## Features

  * **🔒 Enhanced Security:** Confines Cursor and its AI features, preventing file modifications outside the designated project directory.
  * **🤖 Confident AI Usage:** Use powerful AI prompts without the fear of accidental system-wide changes.
  * **💾 State Persistence:** All your Cursor settings, themes, and extensions are saved and loaded normally.
  * **🚀 Hardware Accelerated:** Supports GPU passthrough (`/dev/dri`, NVIDIA) for a smooth, native-like performance.
  * **💻 Seamless Workflow:** Acts as a drop-in replacement for the standard `cursor` command, supporting file and directory arguments.

## Prerequisites

This tool is designed for Ubuntu/Linux systems. Before using `bcursor`, you need to have the following software installed:

  * **Cursor:** The script assumes the `cursor` executable is available at `/usr/bin/cursor`.
  * **Bubblewrap:** The core sandboxing tool. You can install it on most Linux distributions via the package manager (e.g., `sudo apt install bubblewrap` on Debian/Ubuntu, `sudo dnf install bubblewrap` on Fedora).
  * **coreutils:** The script uses `realpath` or `readlink` to resolve file paths, which are standard system utilities.

## Installation

1.  **Make the script executable:**

    ```bash
    chmod +x bcursor.sh
    ```

2.  **Move the script to a directory in your `$PATH` for system-wide access.** A common location is `/usr/local/bin`.

    ```bash
    sudo mv bcursor.sh /usr/local/bin/bcursor
    ```

## Alternative Implementations

This repository contains multiple approaches to sandboxing Cursor:

### Main Implementation (`bcursor.sh`)
The primary implementation that mounts your project directory as read-write while keeping the rest of the filesystem read-only. This approach shares Cursor's configuration with your regular (non-sandboxed) installation.

### Alternative Implementation (`bwrap_alternatives/bcursor_uses_work.sh`)
An alternative approach that creates a completely isolated home directory (`~/.cursor`) for the sandboxed Cursor instance. The project directory is mounted at `/home/app/work` within the sandbox. This provides stronger isolation but requires separate configuration management.

**Key differences:**
- Uses `~/.cursor` as the sandboxed home directory
- Project is mounted at `/home/app/work` instead of the original path
- Complete isolation from your regular Cursor configuration
- May require reconfiguring extensions and settings

See [bwrap_alternatives/README.md](bwrap_alternatives/README.md) for detailed information about this approach and potential improvements.

### Firejail Attempt (`do_not_use/firejail_cursor`)
An early attempt using Firejail that was abandoned due to networking issues. The file is preserved for reference but should not be used.

**Why Firejail was abandoned:**
- Complex networking configuration requirements
- Difficult to properly whitelist all necessary DNS resolution files
- Less reliable than the bwrap approach

## Usage

You can now use `bcursor` just as you would use the `cursor` command.

  * **Open the current directory:**

    ```bash
    cd ~/projects/my-website
    bcursor
    ```

  * **Open a specific project directory:**

    ```bash
    bcursor ~/projects/my-website
    ```

  * **Open a specific file (this will open the parent directory and focus the file):**

    ```bash
    bcursor ~/projects/my-website/src/app.js
    ```

## Security Considerations & Trade-offs

  * **⚠️ Do Not Sandbox High-Level Directories:** The security model relies on you providing a specific project path. The script includes built-in protection against running on high-level directories. It will refuse to run if you attempt to use `/`, `/usr`, `/etc`, or your home directory (`$HOME`) as the project path, as this would defeat the purpose of the sandbox.

  * **D-Bus for Convenience:** This script allows access to the D-Bus by default. This is what allows Cursor to do things like open a native file-picker dialog or integrate with your system theme. While this presents a minor theoretical risk (a compromised app could ask other apps to do things), it is necessary for a good user experience. For maximum security, you can comment out the `DBUS_SESSION_BUS_ADDRESS` line in the script, but be aware this will degrade functionality.

  * **Shared config directories for cursor with/without sandbox:** By design, the config directories for both sandboxed cursor and unsandboxed cursor are the same. Therefore, this sandboxing model is not suitable for testing e.g. extensions which you do not trust.

  * **GPU Passthrough:** The script automatically detects and passes through GPU devices (`/dev/dri`, NVIDIA devices) for hardware acceleration. This is necessary for smooth performance but grants the sandboxed application access to GPU resources.

  * **X11/Wayland Access:** The script passes through display server sockets and environment variables, which is necessary for GUI functionality but allows the sandboxed application to interact with your display system.

  * **$HOME Access:** The entire `$HOME` directory remains accessible (read-only) to the sandboxed application. This is a security consideration, as Cursor can read all files in your home directory. However, this is similar to how most desktop applications operate - they typically have access to your home directory for configuration, themes, and other user data. The key difference is that `bcursor` prevents Cursor from *modifying* anything outside your project directory.


## Removing DBUS access

Disabling D-Bus access for just the sandboxed Cursor application is a valid security-hardening step.

### A potential route for disabling DBUS

To disable D-Bus access in your `bcursor.sh` script, you can try to comment out or delete the line that sets the D-Bus environment variable.

Find this line in the `Session env passthrough` section:

```bash
[ -S "${XDG_RT}/bus" ]        && env_args+=( --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=${XDG_RT}/bus" )
```

And change it to:

```bash
# [ -S "${XDG_RT}/bus" ]        && env_args+=( --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=${XDG_RT}/bus" )
```

I haven't tested this, but it should disable DBUS access.

### What to Expect (The Consequences)

By preventing Cursor from communicating with the desktop's "switchboard," the following features will likely break or degrade:

  * **Native File Dialogs Will Fail:** When you click **"File \> Open..."** or **"Save As..."**, Cursor won't be able to ask your desktop environment to show its standard file picker. It might fall back to a clunky, built-in file dialog, or the feature might not work at all.

  * **No "Reveal in File Manager":** The option to right-click a file in the sidebar and have it opened in your system's file manager will stop working.

  * **Opening Links Will Break:** Clicking on a web link (e.g., `http://...`) inside a document will do nothing, as Cursor can't ask the system to open the URL in your default browser.

  * **Loss of Theme Integration:** Cursor may no longer respect your system's theme, such as **dark mode**, icon sets, or font settings. It will likely default to its own standard theme.

  * **No Single Instance Control:** Normally, if Cursor is already open and you run `bcursor` on another file, the existing instance will just open a new window. Without D-Bus, the script might launch a completely separate, new instance of the entire application every time, using more memory.

  * **Desktop Notifications Won't Appear:** If any Cursor tasks or extensions try to send you a desktop notification (e.g., "Indexing complete"), it will fail silently.

### The Trade-Off ⚖️

  * **What You Gain (Security):** You eliminate the "Confused Deputy" attack vector. The sandboxed Cursor application can no longer ask other, unsandboxed applications to perform actions on its behalf. It becomes more strictly confined.

  * **What You Lose (Convenience):** You lose the seamless integration that makes an application feel like a part of the desktop.

For most users, the convenience of desktop integration is worth the small risk, but if you're working in a high-security environment or with potentially untrusted code, disabling D-Bus is a reasonable step.

## Separate config dirs

Separate config dirs are possible, and the script could be amended to use a dedicated set of dirs (e.g., located in a `$HOME/.cursor_home` directory or similar).

## Why not firejail?

I started with `firejail` but encountered several issues that made it less suitable for this use case. The bwrap approach is simpler, more reliable, and provides better security isolation with less configuration complexity. See [do_not_use/README.md](do_not_use/README.md) for detailed information about the Firejail attempt and why it was abandoned.

## Repository Structure

```
bwrap-cursor/
├── bcursor.sh                           # Main implementation (shared config)
├── bwrap_alternatives/
│   ├── bcursor_uses_work.sh            # Alternative implementation (isolated config)
│   └── README.md                       # Documentation about alternative approach
├── do_not_use/
│   ├── firejail_cursor                 # Abandoned Firejail implementation
│   └── README.md                       # Documentation about abandoned approaches
├── .cursorignore                       # Cursor IDE ignore file
├── .gitignore                          # Git ignore file
└── README.md                           # This file
```

- **`bcursor.sh`**: The primary script that most users should use
- **`bwrap_alternatives/`**: Contains alternative implementations with different security models
- **`do_not_use/`**: Contains experimental or abandoned implementations for reference
