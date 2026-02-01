# Radiant Binaries

Place your Radiant node daemon and CLI binaries in this directory.

## Required Files

- `radiantd` - The Radiant daemon executable (**Linux x86_64 ELF binary**)
- `radiant-cli` - The Radiant CLI client (**Linux x86_64 ELF binary**)

⚠️ **Important**: Only Linux binaries work with Docker containers! Do NOT use Windows .exe or macOS binaries.

## Where to Get Them

Download from the official Radiant Node releases:
https://github.com/radiantblockchain/radiant-node/releases

1. Download the latest `radiant-node-x.x.x-x86_64-linux-gnu.tar.gz`
2. Extract the archive
3. Copy `bin/radiantd` and `bin/radiant-cli` to this directory

## File Permissions

The Docker build process will automatically set execute permissions on these files.

For native execution, set permissions manually:

```bash
chmod +x radiantd radiant-cli
```

## Verification

Check if you have the correct binary format:

```bash
file radiantd
file radiant-cli
```

**Expected output:**

```
radiantd: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped
radiant-cli: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped
```

❌ **Wrong formats (will NOT work):**

- Windows: `PE32+ executable (console) x86-64, for MS Windows`
- macOS: `Mach-O 64-bit executable x86_64`

## Directory Structure

```
binaries/radiant/
├── radiantd      # Radiant daemon
└── radiant-cli   # Radiant CLI client
```

## Troubleshooting

**"exec format error"** - Wrong binary format (Windows/macOS instead of Linux)

**"Permission denied"** - Run `chmod +x radiantd radiant-cli`

**"No such file or directory"** - Binary may be for wrong glibc version or architecture
