#!/bin/bash -e

rsync -e "ssh -i $HOME/.ssh/portal.pem" -avz --exclude=.DS_Store public/ bitnami@eed3si9n.com:/home/bitnami/apps/portal/htdocs/
