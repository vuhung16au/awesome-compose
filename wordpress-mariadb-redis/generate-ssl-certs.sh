#!/bin/bash
# Script to generate self-signed SSL certificates for local development

# Set color codes for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating self-signed SSL certificates for local development...${NC}"

# Create SSL directory if it doesn't exist
mkdir -p nginx/ssl

# Generate a 2048-bit RSA private key
openssl genrsa -out nginx/ssl/key.pem 2048

# Generate a self-signed certificate valid for 365 days
openssl req -new -x509 -key nginx/ssl/key.pem -out nginx/ssl/cert.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set correct permissions on the files
chmod 400 nginx/ssl/key.pem
chmod 444 nginx/ssl/cert.pem

echo -e "${GREEN}SSL certificates generated successfully!${NC}"
echo -e "Certificate file: ${YELLOW}nginx/ssl/cert.pem${NC}"
echo -e "Private key file: ${YELLOW}nginx/ssl/key.pem${NC}"
echo -e "\n${YELLOW}NOTE: These are self-signed certificates for local development only.${NC}"
echo -e "${YELLOW}For production, use certificates from a trusted certificate authority.${NC}"

# Important warning
echo -e "\n${YELLOW}Remember to enable HTTPS in the NGINX configuration by uncommenting the relevant sections in:${NC}"
echo -e "  ${YELLOW}nginx/default.conf${NC}"
