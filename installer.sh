#!/bin/bash

#Database Details
HOST='82.223.165.66';
# USER='nishatbd_vp';
PASS='nishat@#123;
DBNAME='nishatbd_vp';

#Installing Important Files
apt update -y
apt install iptables-persistent unzip gnutls-bin curl -y
apt install php sudo ufw -y
apt install php-cli net-tools curl cron php-fpm php-json php-pdo php-zip php-gd  php-mbstring php-curl php-xml php-bcmath php-json -y

#Adding Authentication
cat <<\EOM >/home/config.sh
#!/bin/bash
HOST='DBHOST'
USER='DBUSER'
PASS='DBPASS'
DB='DBNAME'
EOM
sed -i "s|DBHOST|$HOST|g" /home/config.sh
sed -i "s|DBUSER|$USER|g" /home/config.sh
sed -i "s|DBPASS|$PASS|g" /home/config.sh
sed -i "s|DBNAME|$DBNAME|g" /home/config.sh

#client-connect file
cat <<'LENZ05' >/home/connect.sh
#!/bin/bash

tm="$(date +%s)"
dt="$(date +'%Y-%m-%d %H:%M:%S')"
timestamp="$(date +'%FT%TZ')"

. /home/config.sh

##set status online to user connected
mysql -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE users SET is_active='1' AND device_connected='1' WHERE user_name='$common_name' "
LENZ05

#TCP client-disconnect file
cat <<'LENZ06' >/home/disconnect.sh
#!/bin/bash
tm="$(date +%s)"
dt="$(date +'%Y-%m-%d %H:%M:%S')"
timestamp="$(date +'%FT%TZ')"

. /home/config.sh

mysql -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE users SET is_active='0' WHERE user_name='$common_name' "
LENZ06

cat <<EOF >/home/authentication.sh
#!/bin/bash
SHELL=/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
wget -O /home/active.sh "$API_LINK/active.php?key=$API_KEY"
sleep 5
wget -O /home/inactive.sh "$API_LINK/inactive.php?key=$API_KEY"
sleep 5
wget -O /home/deleted.sh "$API_LINK/deleted.php?key=$API_KEY"
sleep 15
bash /home/active.sh
sleep 15
bash /home/inactive.sh
sleep 15
bash /home/deleted.sh
EOF

echo -e "* *\t* * *\troot\tsudo bash /home/authentication.sh" >> "/etc/cron.d/account"

#Installing Squid Proxy
apt install squid -y

cat <<EOF >/etc/squid/squid.conf
http_port 3128
http_port 8080
http_port 8181
acl vpnip dst $(curl ipecho.net/plain)
http_access allow vpnip
http_access deny all
visible_hostname MD
httpd_suppress_version_string off
cache_mgr MD
error_directory /usr/share/squid/errors/English 
EOF

#Installing OCserv
apt install ocserv -y

cat <<EOM >/etc/ocserv/ocserv.pem
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC9qXMLnAeKcCR6
bJ3KeR0Y5Nl7yOcf8bo3loLWW9CNa6JrkzWi8d3Te62H4Phy8of/IzxF73Z/I9xJ
oZQ3pdxcVQ83Y4iwihhAwVRx1pxXE5p5NrlH7FFa8HHuVjKuCAzfCfHlTN+blVGO
Dv/jPLOYggkknZcicNDEs3mSZmNKC0Z0yzFQNkHmLORnrQ/MXaGHI4S+aIxI4qMq
hC7PXpe++8H4F1n8yeRj3f4DBgS7mHpi6jZTDi6yHENli91HIzOQkxpYhyNaUkio
j292oR6D2ssY8L3j71/8VMhG9jLKLPd31GO6EC41DIRgQrT6WPXbafv9qVpswEZp
MxLA2p47AgMBAAECggEALG2dPYL3YT6TzPnUnLFyV3qEV7LgMWN2s77WN1CasgYc
rgZ18g2mYPv/0myoxoR5xxKB8//8ShwkZjsrdT2tORPT1K3EP1aaB9FB7sjPJra4
4Nwo2uhIxny8s5ANnybTnQu/Vm+DkfaQfC6XUqvNhlQvwBwKY076GJnSSLEjYRyL
gjDrjwG13cNdhppU0sUOAxm6Kg/lLKWl8z/4IgMhPrb1WlZdpSENmCXgXkKF0L3a
fMxSxbemM9ulDU5lljg71fxutCU2iSigQzkfELu4mw6RL/fn022kFr78JzorqG8N
SuK8fx87mj7alL+me+s21Wcz9BQZb7ka0akCg1gFwQKBgQDt/ICjGn4fHHi3UMRo
KvNvNKzl71zotXNrkRm7ioKunwfwSGZ4B/JoLwFNO+ThdYh10LTT5fgbTBLttTnE
yHFbudjOpk8j5cJwMvPpfpGPiweR7yr21LZjugAXRM3nw+jHBLrLVFKbREfU3bGm
FS/lLTMYyJmOm6jbtVFZ/o0FpwKBgQDMBI6g4zBAJTKWT72kWAMQKx0nFVB80DgU
GWJBnC73Xj+GKKAS/Yjdkg2B4m3GxWatA8EQe5Y15DRonbheDd9MmI66aS6dbnB4
4PlEb/GFQQKCsUqmdB4Ly0jFLpvFlAdDF/xBybr+cEKrtvTsSMiz0mY5EGADP6PY
+w4TRFQdTQKBgQDCWFR4XbcnEuol0YhDBOg9JUgYkctOonc6HYllFKy5i1dBSu6b
EOpNWC148/Nqhr/EboZtELz3Fb3Tbw5Y+9NOs8swnrG8P/H0DDgRsvGNxlyNOUHd
xkGX2Rof5mk73kmm1N7yEs9OyojadZyQY3b0cV/r2k1EHyvbGAvyMSTauwKBgHJ0
0AukyWoDNFktjUgI9Fb6yRUnGQucyQlFoGEMnTC8GElMu1lMEZ+0k41dmZadIlhI
NeToYMIFL/3NFiT2BWN0ZwZfgf5iegjmthFV+Bp4+U6W5jlyBXU6a63r0wpKXLSg
XS4PXa/nDRBGyStSPf7cN+slq6fG6UYOurvGZqY1AoGBAObfwE4akNBMW6GAAcBF
RjLME4oJjn6wQeUpbNfiyBgjQSNJSyJWXa7DXZfUa07CgSg6qwH4ZsvzXZ15fV6n
rFLBgIC08l/o1yyG8Xtr6KU/2g2fM0sBPBEeaT9+d0yxNFAD5eGdnVA46hLQC9eE
ZR+FLoJ76rPR8a83o525hkbL
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDRTCCAi2gAwIBAgIUDO5UXGm2najBr5kqZ6AvZnEMDRIwDQYJKoZIhvcNAQEL
BQAwMjEQMA4GA1UEAwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNV
BAYTAlBIMB4XDTIxMDUwNzA3MTIzNloXDTMxMDUwNTA3MTIzNlowMjEQMA4GA1UE
AwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNVBAYTAlBIMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvalzC5wHinAkemydynkdGOTZe8jn
H/G6N5aC1lvQjWuia5M1ovHd03uth+D4cvKH/yM8Re92fyPcSaGUN6XcXFUPN2OI
sIoYQMFUcdacVxOaeTa5R+xRWvBx7lYyrggM3wnx5Uzfm5VRjg7/4zyzmIIJJJ2X
InDQxLN5kmZjSgtGdMsxUDZB5izkZ60PzF2hhyOEvmiMSOKjKoQuz16XvvvB+BdZ
/MnkY93+AwYEu5h6Yuo2Uw4ushxDZYvdRyMzkJMaWIcjWlJIqI9vdqEeg9rLGPC9
4+9f/FTIRvYyyiz3d9RjuhAuNQyEYEK0+lj122n7/alabMBGaTMSwNqeOwIDAQAB
o1MwUTAdBgNVHQ4EFgQU7fOQHG4W1P+pojorYRa6YuenySUwHwYDVR0jBBgwFoAU
7fOQHG4W1P+pojorYRa6YuenySUwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B
AQsFAAOCAQEABAd1QC6vYkWvnUV0/db/+Xfxwm5IXZGH0mrks1CPohqzXNxXArfi
AZ2ZeizepiXn6RWxCrek8R33DGIIrPR2gXTDpPmigOYHIMX52Zo7GD4nhtMVn/7c
8NbTp/gAc62vvqdOlTNROso7eWEYPnyZFBpAD9N3mQ9FO04jnuYn4MOBZkY4CKoJ
g1txK/CrRH7nkWXp7LmoqbeHGnnJU+1gQYisMC2n3QACibQJmpzOgWen3+yKKAdq
edL+IpPFHCS/AfrMGWBrEGeX6X0XhjP3DmKp11zPuz2cavC1npS2pxf2VmmUUU4v
D2hYB8W+2dNIPu8szwXgy4LP8GXmfo6SXw==
-----END CERTIFICATE-----
EOM

cat <<EOF >/etc/ssl/certs/ssl-cert-snakeoil.pem
-----BEGIN CERTIFICATE-----
MIIDDDCCAfSgAwIBAgIUToEUavrkoBRDzZtNrej5rcF/gSUwDQYJKoZIhvcNAQEL
BQAwJTEjMCEGA1UEAwwadWJ1bnR1LXMtMXZjcHUtMWdiLW55YzMtMDEwHhcNMjEw
NTA3MDY1NDM5WhcNMzEwNTA1MDY1NDM5WjAlMSMwIQYDVQQDDBp1YnVudHUtcy0x
dmNwdS0xZ2ItbnljMy0wMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ANplrGwhdR1T1GZZsfYs/fVruIoYte9k95djOevdjiSjWhDZYpg0H3fyERLwysB1
nUCkKXLccFutysghi9P2YpSO8q0iwfVV9vsZceJsLk73ubIPabKtY8ngXUTZslGP
nBhg/iCwuOdN/DPmgHM1C2mRlkKb59TXzrMQ1jnKCO4i8NHVQ2jgcI7ihsENBCAe
25vghfIcOk7Bf/msu2EXBwsEW7SRolrZB7nSEKydWMm6yMaxSpgkYPfBeV9ZRkQh
+1XEK/SFvvx5KWVSMv1iyuwg0DVu/eU5CsbBZsvxQSGNzgHza9lSOD3iiBZ/9bsj
4H8cO34qt+wnhUCqkd4ny40CAwEAAaM0MDIwCQYDVR0TBAIwADAlBgNVHREEHjAc
ghp1YnVudHUtcy0xdmNwdS0xZ2ItbnljMy0wMTANBgkqhkiG9w0BAQsFAAOCAQEA
Rz63lFYdYjlwi41YmY3Bxf8GvtGPCL4gP0Ijfr6kmPjbudGXOGfcfdlam7JI1d+1
sYlxREWNCSZESqlxHl9xjoznsPPb53XtR0INuu7AaEFkNStffkgYqUXDbGhySSaR
C7DA4fX5lgB+tT9sKwSkcj4e9XPrLBHnTpla5JPOqKtvgTm4NDKNTq5ILqv2O5ib
189E2oX8Xcq4WMKd9Ml2zcWHNHA2BGRLvlrsU0sGfclya3NpY2kqBsTsPiV5085Z
Vf71125856sUcnE/FLfZgnVR3YuroSXsUAglafHgt/2eBOE4fxYe8DoJPw4aHhRa
iAzsoET91NaULomDwhxJ4w==
-----END CERTIFICATE-----
EOF

cat <<EOF >/etc/ocserv/ocserv.conf
auth = "plain[passwd=/etc/ocserv/ocpasswd]"
tcp-port = 1194
udp-port = 1194
run-as-user = nobody
run-as-group = daemon
socket-file = /var/run/ocserv-socket
server-cert = /etc/ocserv/ocserv.pem
server-key = /etc/ocserv/ocserv.pem
ca-cert = /etc/ssl/certs/ssl-cert-snakeoil.pem
isolate-workers = false
keepalive = 360
dpd = 90
mobile-dpd = 1800
try-mtu-discovery = false
switch-to-tcp-timeout = 25
max-same-clients = 100
cert-user-oid = 0.9.2342.19200300.100.1.1
tls-priorities = "NORMAL:-CIPHER-ALL:+CHACHA20-POLY1305:+AES-128-GCM"
auth-timeout = 240
min-reauth-time = 3
max-ban-score = 0
ban-reset-time = 300
cookie-timeout = 300
deny-roaming = false
rekey-time = 172800
rekey-method = ssl
use-utmp = true
pid-file = /var/run/ocserv.pid
device = vpns_
predictable-ips = true
ipv4-network = 192.168.119.0/21
tunnel-all-dns = true
dns = 1.1.1.1
ping-leases = false
cisco-client-compat = true
dtls-legacy = true
#connect-script = /home/connect.sh
#disconnect-script = /home/disconnect.sh
EOF

cat <<EOF >/etc/systemd/system/ocserv.service
[Unit]
Description=Firenet OpenConnect SSL VPN server
Documentation=man:ocserv(8)
After=network-online.target

[Service]
PrivateTmp=true
PIDFile=/var/run/ocserv.pid
ExecStart=/usr/sbin/ocserv --foreground --pid-file /var/run/ocserv.pid --config /etc/ocserv/ocserv.conf
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
service ocserv restart

#Installing Stunnel
apt install stunnel -y

cat <<EOF >/etc/stunnel/stunnel.pem
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBxzrBgs1+qUif
qe6609N2nsy6hZJpy/UWbjRAyU6VIAadJw5Zh13ZkantBJ3LIq6ebGdIM30xR/FV
JRkQ0NO+Bt3om/INZmVf9ibBgHk3oJAz2kMgnz7JUic+yjuiScVS1+gNayZzVX8d
aDpPULrOARICckTpI2PUHgExCkwcnoO6OUoVv5vR3o/IIDjf3Z0sP1+QkiTp5CFa
XXUbjGr3rdK0TqmRyVwTNeJIlwM+a3Kkw39KuQtIMjv0TE1+asJHRV58JFE/eLgB
k5+p5b5siCsYRryGhutbxFF7bvbs6YDd81vt2JIubELoiF40YMGN9B/bGPNABUL8
qDs064GHAgMBAAECggEAHZXjfKQR5+LEucviLRgmUxgPvfKi1hBTzSbqR3H004Pe
PqQ15qlqRMuenBd2WAtlib6XTki+NoX7bLqLRyv7CCpYOymEHVOi6rHUXPrWhw22
tpP+Z76ogWhPoaCS1kZZIDrirRnM9xL4o27EaFO1EbrMGx+DMe07Uql6GRivYjb0
3PIBoyJv8Ih2C50X+FrkqTNWZEP0I9hanujvWTFVmzCb+rNziWVbINpfIhaneR7/
FPgeBWgr4eESmoybGnmZa+utE0FJUpfmk+tar86nQ7ZWj/EKqQsgdCuDhzscZ4B2
izzpihg4qDXzHva2Y5WBC19m9KVdioMjngXiOwhzEQKBgQD+XZrfjeAfKwYgufyV
OibCBGV2FGKxN0smFhdIKLI07+nU1SdWSmuynT0WyrCxwncHlHzsGUmIzGyoMXne
gMGot8vI5KWeWytJ1xmzcLzlthBjwk9mXKbVSqm1WZaamKCLcKK+sfcMyIzmuGdw
f7YH24msJXrW+cN+NjnAzX4tYwKBgQDDBfeJxBjsLQ1hFYeVYpv3WPlKDT3R9OZ9
t1BnH/dba/MWtNnma4UMhO0T1Vp72641cGRhn0qIUMPgUeldxTPsv5jf3aOGoikR
9qS8ZsSuSLhLzlOUVQQ5fnQc2uh9AsAHSvFrXodXb9XB46KBeZ7Jb0UxPUJb7qM+
K44LCUIWjQKBgQCqRz9GKFPAiaywe9D6lNMdTpQdV8g5mipUdLVhON0TUwfV0ltj
CK7QAzLB7y4Z0XSdPmniI4t2aGLUtUpACTGbIG7rLSUxvRZdeAFcfjv2Csst/QXq
IFwOrMyu+io3k7Tlo6FOxxP7GsY4LXoRdW0GFZE0DGMPRmP4OZSv3OB6wQKBgDrY
jxPLzvVctr/HnkyuH3+oIjh8/F1g9zeR27nyRFIapZQBaAqGAPSBG4QziYT8CXno
evGV/ghZznDeZns76OoT+g36s8AJKDlaYeTTYZ9xI+MD0+ZbLNYoWOLoDuTBsq3A
qE4MjOwOO8KwbDWDPC1t3MP5xw80V5+Hxul/lqh1AoGAGrwwvjn+EWqfBrFk8YO3
6Rf6I+tk4O3z75EoPcginkR22NnWOWYR2Az4jRVApoAVIr091JQu9JiF86jm1ApP
CMPyQLVbKja1tqB2sHVp++pLTmXN/45nq/m+yd9cNjBWrzY/o/VabyfsMhjrZLRU
ncnVcf4SOplfOaS6Ahh4jN8=
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDRTCCAi2gAwIBAgIUJrpAROiuhbT7l1TNwHoYM7Zty3UwDQYJKoZIhvcNAQEL
BQAwMjEQMA4GA1UEAwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNV
BAYTAlBIMB4XDTIxMDUwNzA3MTI0MFoXDTMxMDUwNTA3MTI0MFowMjEQMA4GA1UE
AwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNVBAYTAlBIMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwcc6wYLNfqlIn6nuutPTdp7MuoWS
acv1Fm40QMlOlSAGnScOWYdd2ZGp7QSdyyKunmxnSDN9MUfxVSUZENDTvgbd6Jvy
DWZlX/YmwYB5N6CQM9pDIJ8+yVInPso7oknFUtfoDWsmc1V/HWg6T1C6zgESAnJE
6SNj1B4BMQpMHJ6DujlKFb+b0d6PyCA4392dLD9fkJIk6eQhWl11G4xq963StE6p
kclcEzXiSJcDPmtypMN/SrkLSDI79ExNfmrCR0VefCRRP3i4AZOfqeW+bIgrGEa8
hobrW8RRe2727OmA3fNb7diSLmxC6IheNGDBjfQf2xjzQAVC/Kg7NOuBhwIDAQAB
o1MwUTAdBgNVHQ4EFgQUz30409cdfmDE3bi5bg9Y++1DZGYwHwYDVR0jBBgwFoAU
z30409cdfmDE3bi5bg9Y++1DZGYwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B
AQsFAAOCAQEAO3iWzW52H5t52qBhxFgdlnxyX9P3zKkvzg7d80Ld4DClr3/q8RUK
gSPIsd21BU7DU3Fd3tuSoHEhRllbTxAOh7lLfD8UdfK1n+68kwgJ0yzn7zEFzdil
YjVaIo0qv/cacj/MVie6EmEzj4TocTsbgFrd0k2xMi3J8V70GqfdooHyXQvI1XyF
Y69xxUW0udEwFnDnmjON31YZNRpE6IsVW6xyPb1HIlxX5CgmmNFVde2wbf76i/Cz
tkwlpFuvBNyrLSord9q5lVEhFXxEqfKre4QPO6IM4yor4mARQ+yTUuLsErhw31jL
a3e5vU06MY6g2U5s5ouCwRvcJVAKoMBecQ==
-----END CERTIFICATE-----
EOF

cat <<EOF >/etc/stunnel/stunnel.conf
pid = /tmp/stunnel.pid
debug = 0
output = /tmp/stunnel.log
cert = /etc/stunnel/stunnel.pem

[ocserv]
connect = 1194
accept = 443 
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

sudo iptables -t nat -A POSTROUTING -j MASQUERADE
sudo iptables -A POSTROUTING -t nat -s 192.168.112.0/21 -o eth0 -j MASQUERADE
sudo iptables -A POSTROUTING -t nat -s 192.168.112.0/21 -o ens3 -j MASQUERADE
sudo iptables -A POSTROUTING -t nat -s 192.168.112.0/21 -o eth0 -j SNAT --to-source "$(curl ipecho.net/plain)"
sudo iptables -A POSTROUTING -t nat -s 192.168.112.0/21 -o ens3 -j SNAT --to-source "$(curl ipecho.net/plain)"
sudo iptables -A INPUT -p udp -m udp --dport 1194 -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 3306 -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
sudo iptables -A FORWARD -d 192.168.112.0/21 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.112.0/21 -j ACCEPT
iptables-save > /etc/iptables_rules.v4
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

cd /root || exit

#Restarting Services

systemctl enable squid
systemctl enable stunnel4
systemctl enable ocserv
systemctl enable apache2
systemctl restart squid
systemctl restart stunnel4
systemctl restart ocserv
systemctl restart apache2

rm -f /root/installer.sh


echo 'root:@@@F1r3n3t' | sudo chpasswd
reboot

