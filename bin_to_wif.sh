#!/bin/bash

# Error handling function
error() {
    echo "Error: $1" >&2
    exit 1
}

# Ensure dependencies are installed
if ! command -v xxd >/dev/null 2>&1 || ! command -v openssl >/dev/null 2>&1; then
    error "Dependencies (xxd, openssl) are missing. Install them first."
fi

# Convert binary input to hexadecimal
binary_to_hex() {
    local binary_input="$1"
    hex=$(echo "$binary_input" | xxd -r -p | xxd -p -c 64)
    echo "$hex"
}

# Convert hexadecimal input to WIF format
hex_to_wif() {
    local hex="$1"
    # Add version byte (0x80 for mainnet Bitcoin)
    versioned_hex="80$hex"

    # Double SHA-256 hash for checksum
    checksum=$(echo -n "$versioned_hex" | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 64 | head -c 8)

    # Append checksum to versioned hex
    final_hex="$versioned_hex$checksum"

    # Convert to Base58
    wif=$(echo "$final_hex" | xxd -r -p | openssl base58)
    echo "$wif"
}

# Convert WIF to hexadecimal
wif_to_hex() {
    local wif="$1"
    hex_with_checksum=$(echo "$wif" | openssl base58 -d | xxd -p -c 64)

    # Extract hex without version byte and checksum
    hex_no_version=${hex_with_checksum:2:-8}
    echo "$hex_no_version"
}

# Convert hex to binary
hex_to_binary() {
    local hex="$1"
    binary=$(echo "ibase=16; obase=2; $hex" | bc | sed 's/^/00000000/' | tail -c 256)
    echo "$binary"
}

# Main function to handle conversions
main() {
    local mode="$1"
    local input="$2"

    if [ "$mode" == "binary_to_wif" ]; then
        # Remove spaces from binary input
        binary_input=$(echo "$input" | tr -d ' ')
        # Convert binary to hex
        hex=$(binary_to_hex "$binary_input")
        # Convert hex to WIF
        wif=$(hex_to_wif "$hex")
        echo "WIF: $wif"
        echo "$wif" > wif_output.txt
    elif [ "$mode" == "wif_to_binary" ]; then
        # Convert WIF to hex
        hex=$(wif_to_hex "$input")
        # Convert hex to binary
        binary=$(hex_to_binary "$hex")
        echo "Binary: $binary"
        echo "$binary" > binary_output.txt
    else
        error "Invalid mode. Use 'binary_to_wif' or 'wif_to_binary'."
    fi
}

# Check input arguments
if [ "$#" -ne 2 ]; then
    error "Usage: $0 <binary_to_wif|wif_to_binary> <input>"
fi

# Run main function
main "$1" "$2"
