## Generate private key
```
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 1825 -nodes -keyout private.key
```

## Generate certificate request based on config file
```
openssl req -new -key private_key.pem -out {domain_name}.csr  -config csr_request.config
```

Config file example
 (csr_request.config)



## Generate certificate request
```
openssl req -new -sha256 -key private_key.pem -out domain.csr
```
```
openssl req -new -subj "/C=US/ST=DC/L=Washington/O=Company/OU=Department/CN=$(hostname)" -sha256 -key private_key.pem -out  "$(hostname).csr"
```
## Test SSL Connection
```
openssl s_client -connect  localhost:8843
```
## Check certificate
```
openssl x509 -in certificate.pem -text
```
## Check certificate expiration date
```
openssl x509 -in certificate.pem -noout -enddate
```
## Check certificate bundle
```
openssl crl2pkcs7 -nocrl -certfile path/to/bundle.pem | openssl pkcs7 -print_certs -text -noout
```
## Create keystore
```
openssl pkcs12 -export -in {domain_name}.cer -inkey private_key.pem -out keystore.p12 -certfile CACert.crt -name application_alias
```
## Extracts the private key from a PKCS12 keystore file and saves it to a PEM file
```
openssl pkcs12 -in keystore.p12 -nodes -nocerts -out private_key.pem
```
## Validate Certificate chain
```
openssl verify  -CAfile CACert.crt {{domain}}.cer
```

## Verify that an RSA private key matches the RSA public key in a certificate 
```
openssl rsa -modulus -noout -in private.key | openssl md5
```
```
openssl x509 -modulus -noout -in {{domain}}.crt | openssl md5
```
* md5 hash of private key modulus should be the same as certificate modulus

## Create certificate chain certificate
```
cat {{domain}}.crt intermediate.crt root.crt > {{full_chain_domain_cert}}.pem
```
### Convert from CRT to DER: 
```
openssl x509 -in {{domain}}.crt -outform DER -out {{domain}}.der
```
### Convert from CRT to P7B: 
```
openssl crl2pkcs7 -nocrl -certfile {{domain}}.crt -out {{domain}}.p7b
```

### Create a PKCS#12 PFX file along with the private key

A Personal Information Exchange (.pfx) Files, is password protected file certificate commonly used for code signing your application. 
It derives from the PKCS 12 archive file format certificate, and it stores multiple cryptographic objects within a single file:

X.509 public key certificates
X.509 private keys
X.509 CRLs
generic data

```
openssl pkcs12 -export -out {{domain}}.pfx -inkey private.key -in {{domain}}.crt -in intermediate.crt -in root.crt
```
