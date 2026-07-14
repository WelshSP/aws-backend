#!/bin/bash

# Prevent interactive prompts during apt installations
export DEBIAN_FRONTEND=noninteractive

# Update the base OS packages
apt-get update -y
apt-get upgrade -y

# Add the official Ondřej Surý PHP repository for PHP 8.4 support
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt-get update -y

# Install Nginx and the exact PHP 8.4 stack
apt-get install -y nginx \
  php8.4-fpm \
  php8.4-cli \
  php8.4-mysql \
  php8.4-xml \
  php8.4-mbstring \
  php8.4-curl \
  php8.4-zip \
  php8.4-bcmath

# Pre-create his favorite public webroot directory
mkdir -p /var/www/public_html
chown -R ubuntu:ubuntu /var/www/public_html
chmod -R 755 /var/www

# Ensure services are enabled and active
systemctl enable nginx php8.4-fpm
systemctl start nginx php8.4-fpm