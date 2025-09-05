#!/bin/bash

##
## This script initializes the Odoo application environment.
##

set -Eeuo pipefail

echo "Downloading OCA addons..."
curl -sSfL https://github.com/OCA/web/archive/refs/heads/17.0.tar.gz | tar -xz -C /mnt/extra-addons --strip-components=1

echo "Initializing database '$DATABASE'..."
odoo -c /etc/odoo/odoo.conf --logfile=/dev/stdout --no-http --stop-after-init -d $DATABASE --init base

if [ -n "${RIBBON_NAME}${RIBBON_COLOR}" ]; then
  echo "Installing Web Environment Ribbon module..."
  odoo -c /etc/odoo/odoo.conf --logfile=/dev/stdout --no-http --stop-after-init -d $DATABASE --init web_environment_ribbon
fi

echo "Installing Point of Sale module..."
odoo -c /etc/odoo/odoo.conf --logfile=/dev/stdout --no-http --stop-after-init -d $DATABASE --init point_of_sale

echo "Setting admin password and ribbon color..."
odoo shell -c /etc/odoo/odoo.conf -d $DATABASE <<EOF
import os
if os.getenv("ADMIN_PASSWORD") is not None:
  env['res.users'].search([('login', '=', 'admin')]).password = os.environ["ADMIN_PASSWORD"]
if os.getenv("RIBBON_COLOR") is not None:
  env['ir.config_parameter'].sudo().set_param('ribbon.background.color', os.environ["RIBBON_COLOR"])
if os.getenv("RIBBON_NAME") is not None:
  env['ir.config_parameter'].sudo().set_param('ribbon.name', os.environ["RIBBON_NAME"])
env.cr.commit()
exit()
EOF

echo "Odoo initialization completed."
