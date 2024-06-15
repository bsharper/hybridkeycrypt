#!/bin/bash

# hybrid_keycrypt
# @bsharper
#
# asymmetric encryption tool
# uses id_rsa

function lreadlink() {
  (
  cd $(dirname $1)
  echo $PWD/$(basename $1)
  )
}

function finish() {
	[ -f file.enc ] && rm file.enc
	[ -f id_rsa.pem ] && rm id_rsa.pem
	[ -f id_rsa.pub.pem ] && rm id_rsa.pub.pem
	[ -f key.bin ] && rm key.bin
	[ -f key.bin.enc ] && rm key.bin.enc
}
trap finish EXIT

openssl_version=$(openssl version | awk '{print $2}')
openssl_major_version=$(echo $openssl_version | cut -d. -f1)
#openssl_minor_version=$(echo $openssl_version | cut -d. -f2)
use_pkeyutl=0

if [[ $openssl_major_version -ge 3 ]]; then
  use_pkeyutl=1
fi

case $1 in
	encrypt|-e)
		input_file=$(lreadlink $2)
		input_file_name=$(basename $2)
		input_file_path=$(dirname $input_file)
		output_file=$(basename $input_file_name).enc
		keyfile=${3:-~/.ssh/id_rsa}

		openssl rsa -in $keyfile -pubout -outform pem > id_rsa.pub.pem 2>/dev/null
		rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not get public key, exiting"; exit $rc; fi
		openssl rand -base64 32 > key.bin
		if [[ $use_pkeyutl -eq 1 ]]; then
			openssl pkeyutl -encrypt -inkey id_rsa.pub.pem -pubin -in key.bin -out key.bin.enc
		else
			openssl rsautl -encrypt -inkey id_rsa.pub.pem -pubin -in key.bin -out key.bin.enc
		fi
		rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not encrypt secret with public key, exiting"; exit $rc; fi
		echo "Encrypting data..."
		openssl enc -aes-256-cbc -salt -pbkdf2 -in "$input_file" -out file.enc -pass file:./key.bin
		rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not encrypt data with secret, exiting"; exit $rc; fi
		echo "Writing encrypted file $output_file"
		cat key.bin.enc file.enc > $output_file
		finish
		;;
	decrypt|-d)
		input_file=$2
        echo_only=0
        if [ "$3" == "--" ]; then
            echo_only=1
            keyfile=~/.ssh/id_rsa
        else
		    keyfile=${3:-~/.ssh/id_rsa}
        fi
		if [[ ! "$input_file" =~ ^.*\.(enc|ENC)$ ]]; then
			echo "ERROR: The input file '$input_file' does not have .enc extension, exiting"
			exit
		fi
		output_file=$(echo $2 | sed 's/\.enc//g')
		dd bs=1 count=256 if=$input_file of=key.bin.enc 2>/dev/null
		if [ $echo_only == 0 ]; then
            echo -n "Copying encrypted data..."
        fi
		dd bs=256 skip=1 if=$input_file of=file.enc 2>/dev/null
		if [ $echo_only == 0 ]; then
            echo "done";
        fi
		openssl rsa -in $keyfile -outform pem > id_rsa.pem 2> /dev/null
		rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not get private key to decrypt secret, exiting"; exit $rc; fi
		if [[ $use_pkeyutl -eq 1 ]]; then
			openssl pkeyutl -decrypt -inkey id_rsa.pem -in key.bin.enc -out key.bin 2>/dev/null
		else
			openssl rsautl -decrypt -inkey id_rsa.pem -in key.bin.enc -out key.bin 2>/dev/null
		fi
		rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not decrypt secret, exiting"; exit $rc; fi
        if [ $echo_only == 1 ]; then
            openssl enc -d -aes-256-cbc -pbkdf2 -in file.enc -pass file:./key.bin
        else
  		    echo "Writing unencrypted file: $output_file"
  		    openssl enc -d -aes-256-cbc -pbkdf2 -in file.enc -out $output_file -pass file:./key.bin
  		    rc=$?; if [[ $rc != 0 ]]; then echo "ERROR: Could not decrypt file data with secret, exiting"; exit $rc; fi
        fi
		finish
		;;
	*)
		echo "Usage: $0 [encrypt filename (public_keyfile) | decrypt filename (private_keyfile)]"
		exit 1
		;;
esac
