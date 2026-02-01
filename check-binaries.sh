#!/bin/bash

# Binary setup helper script for Radiant Stratum Proxy

set -e

echo "🔧 Binary Setup Helper"
echo "======================"

# Function to check if a file exists and is executable
check_binary() {
    local file=$1
    local name=$2
    
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo "✅ $name: Found and executable"
            
            # Check architecture
            if file "$file" | grep -q "ELF 64-bit"; then
                echo "   📋 Architecture: Linux x86_64 ✓"
            else
                echo "   ⚠️  Architecture: $(file "$file" | cut -d: -f2)"
            fi
            
            # Check glibc requirements
            if command -v objdump >/dev/null 2>&1; then
                local glibc_vers=$(objdump -p "$file" 2>/dev/null | grep GLIBC_ | sed 's/.*GLIBC_/GLIBC_/' | sort -V | tail -1)
                if [ ! -z "$glibc_vers" ]; then
                    echo "   🔗 Required: $glibc_vers"
                    case "$glibc_vers" in
                        "GLIBC_2.3"[4-5]*) echo "   💡 Suggestion: Use Ubuntu 22.04+ dockerfile" ;;
                        "GLIBC_2.36"*) echo "   💡 Suggestion: Use Ubuntu 24.04 or Debian dockerfile" ;;
                        "GLIBC_2.3"[7-9]*) echo "   💡 Suggestion: May need newer base or custom glibc" ;;
                    esac
                fi
            else
                echo "   ℹ️  Install objdump to check glibc requirements"
            fi
        else
            echo "⚠️  $name: Found but not executable"
            echo "   💡 Fix: chmod +x $file"
        fi
    else
        echo "❌ $name: Missing"
        echo "   📁 Expected location: $file"
    fi
}

echo "📦 Checking Radiant binaries..."
check_binary "binaries/radiant/radiantd" "Radiant Daemon"
check_binary "binaries/radiant/radiant-cli" "Radiant CLI"

echo ""
echo "📋 Directory structure:"
echo "binaries/"
echo "└── radiant/"
if [ -d "binaries/radiant" ]; then
    for file in binaries/radiant/*; do
        if [ -f "$file" ]; then
            echo "    ├── $(basename "$file")"
        fi
    done
else
    echo "    └── (directory missing)"
fi

echo ""

# Check if all required binaries are present
missing_binaries=0
required_files=(
    "binaries/radiant/radiantd"
    "binaries/radiant/radiant-cli" 
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_binaries=$((missing_binaries + 1))
    fi
done

if [ $missing_binaries -eq 0 ]; then
    echo "🎉 All required binaries are present!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Build Docker images: docker compose build"
    echo "2. Start services: docker compose up -d"
    echo "3. Check logs: docker compose logs -f"
else
    echo "⚠️  Missing $missing_binaries required binaries"
    echo ""
    echo "📝 To fix:"
    echo "1. Download Radiant Node from https://github.com/radiantblockchain/radiant-node/releases"
    echo "2. Extract radiantd and radiant-cli to binaries/radiant/"
    echo "3. Run this script again to verify"
    echo "4. Build Docker images: docker compose build"
fi

echo ""
echo "💡 Help:"
echo "  Binary requirements: See binaries/README.md"
echo "  Radiant setup: See binaries/radiant/README.md"
