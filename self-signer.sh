#!/bin/bash

# Simple bash script to self-sign binaries.
# > Shout out to my homie @dagonet1 for the core logic.
# > (i made it prettier tho)

# Define file names and variables
SIGNER_NAME="Super Secure Signer"
CERT_PASS="P@ssw0rd!"

PRIVATE_KEY="private.key"
CERTIFICATE="certificate.pem"
PFX_FILE="certificate.pfx"
TIMESTAMP_SERVER="http://timestamp.digicert.com"

EXECUTABLE_TO_SIGN=$1
#SIGNED_EXECUTABLE="${EXECUTABLE_TO_SIGN%.*}_signed.${EXECUTABLE_TO_SIGN##*.}"
TEMP_SIGNED_FILE=$(mktemp)

# Define colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7)


# Function to generate a self-signed certificate
generate_certificate() {
    echo "${yellow}[!] Generating a self-signed private key and certificate...${white}"
    
    # Generate the private key
    openssl genrsa -out "$PRIVATE_KEY" 2048
    
    # Generate the self-signed certificate
    openssl req -x509 -new -nodes -key "$PRIVATE_KEY" -sha256 -days 3650 \
        -out "$CERTIFICATE" -subj "/CN=$SIGNER_NAME"
    
    # Create a PKCS#12 file for osslsigncode
    openssl pkcs12 -export -out "$PFX_FILE" -inkey "$PRIVATE_KEY" \
        -in "$CERTIFICATE" -passout pass:"$CERT_PASS"

    echo " o  Certificate generation complete."
    echo " o  --> Private Key : ${green}$PRIVATE_KEY${white}"
    echo " o  --> Certificate : ${green}$CERTIFICATE${white}"
    echo " o  --> PFX File    : ${green}$PFX_FILE${white}"
}


# Function to sign a Windows executable
sign_executable() {
    local input_file=$1
    local output_file=$2
    
    if [[ -z "$input_file" ]]; then
        echo "{red}[!] Error: No executable specified to sign.${white}"
        exit 1
    fi
    
    echo "${yellow}[!] Signing '${green}$input_file${yellow}'...${white}"

    if [[ -f "$output_file" ]]; then
        rm "$output_file"
    fi
    
    osslsigncode sign \
        -pkcs12 "$PFX_FILE" \
        -pass "$CERT_PASS" \
        -n "$SIGNER_NAME" \
        -t "$TIMESTAMP_SERVER" \
        -in "$input_file" \
        -out "$output_file"
    
    if [[ $? -eq 0 ]]; then
        echo " o  Successfully signed executable to: ${green}$output_file${white}"
    else
        echo "${red}[!] Error! Signing failed.${white}"
        exit 1
    fi
}

# Cleanup Artifacts
cleanup() {
    echo "${yellow}[!] Cleaning up artifacts...${white}"
    echo " o  Original file overwritten with the signed version."
    mv "$TEMP_SIGNED_FILE" "$EXECUTABLE_TO_SIGN"
    
    echo " o  Temporary certificate files removed."
    rm "$PRIVATE_KEY" "$CERTIFICATE" "$PFX_FILE"
}


### MAIN LOGIC ###

# Check for dependencies & proper usage
if ! command -v osslsigncode &> /dev/null; then
    echo "${red}[!] Error! 'osslsigncode' is not installed. Please install it to continue.${white}"
    exit 1
elif [ "$#" -ne 1 ]; then
    echo "${yellow}Usage:${white} $0 <path_to_exe>" 
    exit 1
fi

# Generate certificate, sign executable, and remove artifacts
generate_certificate
sign_executable "$EXECUTABLE_TO_SIGN" "$TEMP_SIGNED_FILE"
cleanup
