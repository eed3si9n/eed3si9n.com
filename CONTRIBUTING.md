
```
$ scp -i ~/.ssh/portal.pem images/atreus* bitnami@eed3si9n.com:/home/bitnami/apps/portal/htdocs/images/
```

## SSL

https://karlboghossian.com/2020/04/26/using-lets-encrypt-ssl-certificate-with-auto-renew-on-wordpress-site-hosted-on-aws-lightsail/

$ ssh -i ~/.ssh/portal.pem bitnami@eed3si9n.com

sudo /opt/bitnami/ctlscript.sh stop
sudo /opt/bitnami/letsencrypt/lego --tls --email="eed3si9n@gmail.com" --domains="eed3si9n.com" --domains="www.eed3si9n.com"  --domains="scalaxb.org" --domains="www.scalaxb.org" --path="/opt/bitnami/letsencrypt" run

sudo mv /opt/bitnami/apache2/conf/server.crt /opt/bitnami/apache2/conf/server.crt.old
sudo mv /opt/bitnami/apache2/conf/server.key /opt/bitnami/apache2/conf/server.key.old
sudo mv /opt/bitnami/apache2/conf/server.csr /opt/bitnami/apache2/conf/server.csr.old
sudo ln -sf /opt/bitnami/letsencrypt/certificates/eed3si9n.com.key /opt/bitnami/apache2/conf/server.key
sudo ln -sf /opt/bitnami/letsencrypt/certificates/eed3si9n.com.crt /opt/bitnami/apache2/conf/server.crt
sudo chown root:root /opt/bitnami/apache2/conf/server*
sudo chmod 600 /opt/bitnami/apache2/conf/server*

sudo /opt/bitnami/ctlscript.sh start

#### renew script

```
#!/bin/bash

sudo /opt/bitnami/ctlscript.sh stop apache

sudo /opt/bitnami/letsencrypt/lego --tls --email="eed3si9n@gmail.com" --domains="eed3si9n.com" --domains="www.eed3si9n.com"  --domains="scalaxb.org" --domains="www.scalaxb.org" --path="/opt/bitnami/letsencrypt" renew --days 90
sudo chmod 600 /opt/bitnami/letsencrypt/certificates/eed3si9n.com.*

sudo /opt/bitnami/ctlscript.sh start apache
```

crontab

```
# 5:12am 12th on each month
12 5 12 * * /opt/bitnami/letsencrypt/scripts/renew-certificate.sh 2> /dev/null
```

#### Apache
```
sudo stack/ctlscript.sh restart apache
```

`~/stack/apache2/conf/bitnami/bitnami.conf`:

Change

```
<VirtualHost _default_:80>
  DocumentRoot "/opt/bitnami/apps/portal/htdocs"
  <Directory />
    Options FollowSymLinks MultiViews
    AddLanguage en en
    AddLanguage es es
    AddLanguage pt-BR pt-br
    AddLanguage zh zh
    AddLanguage ko ko
    AddLanguage he he
    AddLanguage de de
    AddLanguage ro ro
    AddLanguage ru ru
    LanguagePriority en
    ForceLanguagePriority Prefer Fallback

    AllowOverride All
    <IfVersion < 2.3 >
      Order allow,deny
      Allow from all
    </IfVersion>
    <IfVersion >= 2.3 >
      Require all granted
    </IfVersion>
  </Directory>

  # Error Documents
  ErrorDocument 503 /503.html

  # Bitnami applications installed with a prefix URL (default)
  Include "/opt/bitnami/apache2/conf/bitnami/bitnami-apps-prefix.conf"
</VirtualHost>
```

to:

```
<VirtualHost *:80>
   Redirect / https://eed3si9n.com/
</VirtualHost>
```

#### database

mysql -u root -p
SHOW DATABASES;
SHOW TABLES;

https://docs.bitnami.com/aws/apps/redmine/administration/backup-restore-mysql-mariadb/

#### Drupal

```
/apps/portal/htdocs
```

```
cp -R drupal-x.y/* /apps/portal/htdocs
```
