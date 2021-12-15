#!/bin/bash -e

rsync -e '/usr/bin/ssh' -avz --exclude=.DS_Store public/ bitnami@eed3si9n.com:/home/bitnami/apps/portal/htdocs/
