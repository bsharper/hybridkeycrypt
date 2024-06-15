# hybrid_keyscrypt.sh - Asymmetric Encryption Tool

This script provides a simple command-line tool for asymmetric encryption and decryption using OpenSSL. It encrypts files with AES256 with a randomly generated secret key, which is then encrypted with an RSA public key (~/.ssh/id_rsa by default). The encrypted file and the encrypted secret key are combined into a single output file.

## Why?

I wrote this initially to learn about openssl. The idea was that files could be stored encrypted and secured with `~/.ssh/id_rsa`, so if secret files were accidently included in an archive, it wouldn't matter as long as `~/.ssh/id_rsa` wasn't. 

This is not a robust, production ready script. The current path workspace is geared more for testing that everyday use. It could be modified to use a temporary directory, but care should be taken to make sure any intermediate files are securely removed after use.

## Prerequisites

- OpenSSL installed and available in your system's PATH.
- RSA key pair (public and private keys).

## Usage

```bash
./hybrid_keycrypt.sh [encrypt filename (public_keyfile) | decrypt filename (private_keyfile)]
```

### Encrypt

To encrypt a file, use the `encrypt` or `-e` option followed by the file to encrypt and optionally the public key file.

```bash
./hybrid_keycrypt.sh encrypt <filename> [public_keyfile]
```

- `<filename>`: The file you want to encrypt.
- `[public_keyfile]`: The public key file to use for encryption (default: `~/.ssh/id_rsa`).

### Decrypt

To decrypt a file, use the `decrypt` or `-d` option followed by the encrypted file and optionally the private key file.

```bash
./hybrid_keycrypt.sh decrypt <filename.enc> [private_keyfile]
```

- `<filename.enc>`: The encrypted file to decrypt.
- `[private_keyfile]`: The private key file to use for decryption (default: `~/.ssh/id_rsa`).

### Decrypt and Display Only

To decrypt a file and display the contents without saving, use the `--` option after the filename.

```bash
./hybrid_keycrypt.sh decrypt <filename.enc> --
```

## Example

Encrypt a file (assumes ~/.ssh/id_rsa exists):

```bash
./hybrid_keycrypt.sh encrypt myfile.txt 
```

Decrypt a file (uses alternative RSA keypair):

```bash
./hybrid_keycrypt.sh decrypt myfile.txt.enc ~/.ssh/id_rsa_file_encryption
```

## Notes

- The script automatically cleans up temporary files after encryption or decryption.
- Look at the filenames used under the `finish` function and make sure no files in the current path use those filenames.
- Ensure your RSA keys are properly configured and accessible.
