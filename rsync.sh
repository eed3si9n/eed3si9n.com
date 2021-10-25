#!/bin/bash -e

rsync -avz --exclude=.DS_Store public/ bitnami@eed3si9n.com:/home/bitnami/apps/portal/htdocs/
