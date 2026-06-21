#!/bin/bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make the downloaded file executable  
chmod +x ./kubectl

# Create a local bin folder for your user if it doesn't exist
mkdir -p ~/.local/bin

# Move kubectl into that folder
mv ./kubectl ~/.local/bin/kubectl