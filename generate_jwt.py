#!/usr/bin/env python3
import jwt
import datetime
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import os

# Configuration
SNOWFLAKE_ACCOUNT = os.environ.get("SNOWFLAKE_ACCOUNT", "YOUR-PROD-ACCOUNT")  # e.g., "abc12345.us-east-1"
SNOWFLAKE_USER = "dbt_lineage_svc"  # Customize this service account name for your environment
PRIVATE_KEY_PATH = os.path.expanduser("~/.ssh/snowflake_lineage_key.p8")

# Read private key
with open(PRIVATE_KEY_PATH, 'rb') as f:
    private_key_data = f.read()

private_key = serialization.load_pem_private_key(
    private_key_data,
    password=None,
    backend=default_backend()
)

# Generate JWT token
qualified_username = f"{SNOWFLAKE_ACCOUNT}.{SNOWFLAKE_USER}".upper()
now = datetime.datetime.now(datetime.timezone.utc)
expire = now + datetime.timedelta(hours=1)
iat = int(now.timestamp())
exp = int(expire.timestamp())

payload = {
    "iss": qualified_username,
    "sub": qualified_username,
    "iat": iat,
    "exp": exp
}

token = jwt.encode(payload, private_key, algorithm='RS256')
print(f"JWT Token:\n{token}")
print(f"\nValid until: {expire}")