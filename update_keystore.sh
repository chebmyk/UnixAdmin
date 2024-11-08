mkdir -p "$(TRUST_STORE_PATH)/certs" && cd "$_"

DOMAIN_PATTERN="*.org"

CERT_ZIP_FILE=$(find . -maxdepth 1 -type f -name "$DOMAIN_PATTERN.zip" | head -n 1)

if [[ -z "$CERT_ZIP_FILE" ]]; then
    echo "No ZIP file matching the pattern '$DOMAIN_PATTERN' found in the current directory."
    exit 1
fi

echo "Archive with certificates CERT_ZIP_FILE found"
DOMAIN_NAME=$(basename "$CERT_ZIP_FILE" .zip)
HOSTNAME=$(hostname)

unzip -o "$CERT_ZIP_FILE" 2>&1
# || { echo "Failed to extract $CERT_ZIP_FILE file."; exit 1; }

CERT_DIR="$DOMAIN_NAME"
if [[ ! -f "$CERT_DIR/$DOMAIN_NAME.crt" || ! -f "$CERT_DIR/intermediate.crt" || ! -f "$CERT_DIR/root.crt" ]]; then
    echo "Required certificates ($DOMAIN_NAME.crt, intermediate.crt, root.crt) not found in $CERT_DIR after extraction."
    exit 1
fi

CN_NAME=$(openssl x509 -in "$CERT_DIR/$DOMAIN_NAME.crt" -noout -subject | grep -o "CN\s*=\s*[^,]*" | sed 's/CN\s*=\s*//')
if [[ "$CN_NAME" == "$HOSTNAME" ]]; then
    echo "The domain certificate's Common Name (CN) matches the hostname."
else
    echo "The domain certificate's Common Name (CN=$CN_NAME)  does not match the hostname."
    echo "Checking  Alternative Name (SAN)....."
    SAN_NAMES=$(openssl x509 -in "$CERT_DIR/$DOMAIN_NAME.crt" -noout -ext subjectAltName | grep -o "DNS:[^,]*" | sed 's/DNS://g')
    if echo "$SAN_NAMES" | grep -q "$HOSTNAME"; then
        echo "The domain certificate's Subject Alternative Name (SAN) includes the hostname."
    else
        echo "Domain certificate is NOT valid for the specified hostname."
        exit 1
    fi
fi



START_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN_NAME.crt" -noout -startdate | sed 's/notBefore=//')
EXPIRATION_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN_NAME.crt" -noout -enddate | sed 's/notAfter=//')
EXPIRATION_TIMESTAMP=$(date -d "$EXPIRATION_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)

if [[ $CURRENT_TIMESTAMP -gt $EXPIRATION_TIMESTAMP ]]; then
    echo "Error: The $DOMAIN_NAME.crt certificate has expired $EXPIRATION_DATE"
    exit 1
fi


echo "*************************************"
echo "Certificate File: $CERT_DIR/$DOMAIN_NAME.crt"
echo "Common Name (CN): $CN_NAME"
echo "Subject Alternative Names (SAN):"
echo "$SAN_NAMES"
echo "Start Date: $START_DATE"
echo "End Date: $EXPIRATION_DATE"
echo "*************************************"


echo "Verifying Certificate Chain...."
cat "$CERT_DIR/intermediate.crt"  "$CERT_DIR/root.crt"  > CACert.crt
VERIFY_RESULT=$(openssl verify -CAfile CACert.crt  "$CERT_DIR/$DOMAIN_NAME.crt")
echo $VERIFY_RESULT

if !(grep -q "$CERT_DIR/$DOMAIN_NAME.crt: OK" <<< "$VERIFY_RESULT";) then
    echo "Certificate validation failed"
    exit 1
fi

echo "Generate new keystore including new certificate and CACert"

#+++++++++++++ Extract private key from current keystore
OUTPUT_MESSAGE=$(openssl pkcs12  -in $(TRUST_STORE_PATH)/keystore.p12  -nodes -nocerts -out private_key.pem  -passin pass:$(JAVA_KEY_STORE_PASSWORD) 2>&1 )

if [ $? -eq 0 ]
then
  echo $OUTPUT_MESSAGE
else
  echo "ERROR: $OUTPUT_MESSAGE"
  exit 1
fi

chmod 600 private_key.pem  

OUTPUT_MESSAGE=$(openssl pkcs12 -passout pass:$(JAVA_KEY_STORE_PASSWORD) -export -inkey private_key.pem -out keystore.p12 -in "$CERT_DIR/$DOMAIN_NAME.crt"   -certfile CACert.crt -name elma-web 2>&1 ) 

rm private_key.pem

if [ $? -eq 0 ]
then
  echo $OUTPUT_MESSAGE
else
  echo "ERROR: $OUTPUT_MESSAGE"
  exit 1
fi


