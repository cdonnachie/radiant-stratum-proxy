# Binaries Directory

This directory contains the blockchain node binaries used by Docker containers.

## Directory Structure

```
binaries/
└── radiant/          # Radiant blockchain binaries
    ├── radiantd      # Radiant daemon
    └── radiant-cli   # Radiant CLI client
```

## Required Binaries

### Radiant (`binaries/radiant/`)

| Binary        | Description          | Required |
| ------------- | -------------------- | -------- |
| `radiantd`    | Radiant node daemon  | ✅ Yes   |
| `radiant-cli` | Command-line client  | ✅ Yes   |

## Download Sources

### Radiant Node

**Official Repository:**
https://github.com/radiantblockchain/radiant-node/releases

Download the latest Linux x86_64 release and extract the binaries.

## Binary Requirements

### Platform

⚠️ **Critical**: Docker containers run Linux. You must use Linux binaries!

| Platform     | Works in Docker? | Notes                                 |
| ------------ | ---------------- | ------------------------------------- |
| Linux x86_64 | ✅ Yes           | Required for Docker                   |
| Windows      | ❌ No            | .exe files won't run in Linux container |
| macOS        | ❌ No            | Mach-O binaries won't run in Linux     |
| Linux ARM64  | ❌ No            | Wrong architecture                    |

### Verification

Check binary format with the `file` command:

**Linux (correct):**

```bash
$ file binaries/radiant/radiantd
binaries/radiant/radiantd: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped
```

**Windows (wrong):**

```
binaries/radiant/radiantd.exe: PE32+ executable (console) x86-64, for MS Windows
```

**macOS (wrong):**

```
binaries/radiant/radiantd: Mach-O 64-bit executable x86_64
```

### Permissions

Binaries need execute permission. Docker handles this automatically, but for native execution:

```bash
chmod +x binaries/radiant/radiantd
chmod +x binaries/radiant/radiant-cli
```

## Setup Instructions

1. **Download binaries** from official sources above

2. **Extract** to the appropriate directory:

   ```bash
   # Example for Radiant
   tar -xzf radiant-node-x.x.x-x86_64-linux-gnu.tar.gz
   cp radiant-node-x.x.x/bin/radiantd binaries/radiant/
   cp radiant-node-x.x.x/bin/radiant-cli binaries/radiant/
   ```

3. **Verify** binary format:

   ```bash
   file binaries/radiant/radiantd
   ```

4. **Check with script**:
   ```bash
   ./check-binaries.sh    # Linux/Mac
   check-binaries.bat     # Windows
   ```

## Troubleshooting

### "No such file or directory" when binary exists

Usually means wrong binary format (Windows/macOS instead of Linux).

### "Permission denied"

Set execute permission:

```bash
chmod +x binaries/radiant/*
```

### Binary won't start in Docker

Check Docker logs:

```bash
docker compose logs radiant
```

Common issues:

- Wrong binary architecture
- Missing library dependencies
- Corrupt download (re-download)

## Security Notes

- Always download from official sources
- Verify checksums when available
- Keep binaries updated for security patches
- Don't run untrusted binaries
