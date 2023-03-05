#!/bin/bash

# Create TLS cert

openssl req -new -newkey rsa:4096 -x509 -sha256 -days 730 -nodes -out certs/cert.crt -keyout certs/cert.key
