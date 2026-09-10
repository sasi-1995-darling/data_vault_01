# Setting Up External Lineage for Production dbt Cloud Job

This guide shows how to enable Snowflake External Lineage **only for your production dbt Cloud job** (scheduled daily at 7am EST).

## Quick Summary

- **Dev/Local**: Use regular `dbt` commands (no lineage)
- **QA**: Use regular `dbt` commands (no lineage)
- **Production**: Use `dbt-ol` commands (with lineage tracking)

## Prerequisites

1. dbt Cloud account with Production job configured
2. Snowflake account with External Lineage preview feature enabled
3. Snowflake API key with production access

## Step 1: Get Snowflake JWT Token for External Lineage

Snowflake External Lineage requires a **JWT token** for authentication. The `apiKey` in the configuration is this JWT token.

The JWT token will look like: `eyJ0eXAiOiJKV1QiLsecuritytoken...`

### Prerequisites

1. **Confirm External Lineage is enabled** for your Snowflake account (preview feature - contact Snowflake support)
2. Have `ACCOUNTADMIN` role or permissions to create/modify users
3. Know your Snowflake account identifier (e.g., `MYORG-PROD_ACCOUNT`)

### Step-by-Step: Generate JWT Token

#### Step 1.1: Create a Service Account in Snowflake

Create a dedicated service account that will authenticate with the External Lineage API.

🔗 **Reference**: [Snowflake CREATE USER Documentation](https://docs.snowflake.com/en/sql-reference/sql/create-user)

```sql
-- Log into Snowflake as ACCOUNTADMIN and run:

-- Create a dedicated service account for lineage
-- Note: SERVICE type users authenticate via key pair only (no password)
CREATE USER IF NOT EXISTS dbt_lineage_svc
  TYPE = SERVICE
  DEFAULT_ROLE = PUBLIC
  COMMENT = 'Service account for dbt External Lineage integration';

-- Grant necessary permissions (adjust as needed for your environment)
-- IMPORTANT: Use a custom role with minimal privileges instead of SYSADMIN
-- CREATE ROLE IF NOT EXISTS LINEAGE_WRITER;
-- GRANT ROLE LINEAGE_WRITER TO USER dbt_lineage_svc;
GRANT USAGE ON DATABASE YOUR_DATABASE TO USER dbt_lineage_svc;
GRANT USAGE ON WAREHOUSE YOUR_WAREHOUSE TO USER dbt_lineage_svc;

-- Note: External lineage may require additional grants - consult Snowflake docs
-- Grant only the minimum permissions needed for lineage data submission
```

**Adjust placeholders:**
- `YOUR_DATABASE` - Replace with your production database name
- `YOUR_WAREHOUSE` - Replace with your production warehouse name

#### Step 1.2: Generate Key Pair (Run Locally on Your Machine)

Open a terminal and run these commands:

```bash
# Navigate to a secure directory
cd ~/.ssh

# Generate private key (encrypted format)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_lineage_key.p8 -nocrypt

# Generate public key from the private key
openssl rsa -in snowflake_lineage_key.p8 -pubout -out snowflake_lineage_key.pub

# Display the public key (you'll need this for the next step)
cat snowflake_lineage_key.pub
```

**Important**: Keep `snowflake_lineage_key.p8` secure - this is your private key!

#### Step 1.3: Assign Public Key to Snowflake User

Copy the public key content (between `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`, **excluding** those lines).

```sql
-- In Snowflake, run as ACCOUNTADMIN:

ALTER USER dbt_lineage_svc SET RSA_PUBLIC_KEY='
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
... (paste your public key content here, remove BEGIN/END lines)
...
';

-- Verify it was set
DESC USER dbt_lineage_svc;
```

#### Step 1.4: Generate JWT Token

You have two options:

**Option A: Use Python Script (Recommended)**

Create a file `generate_jwt.py`:

```python
#!/usr/bin/env python3
import jwt
import datetime
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Configuration
SNOWFLAKE_ACCOUNT = "YOUR-PROD-ACCOUNT"  # Replace with your account
SNOWFLAKE_USER = "dbt_lineage_svc"  # Customize this service account name
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
expire = now + datetime.timedelta(hours=1)  # Token valid for 1 hour
iat = int(now.timestamp())
exp = int(expire.timestamp())

payload = {
    "iss": qualified_username,
    "sub": qualified_username,
    "iat": iat,
    "exp": exp
}

# Create JWT token
token = jwt.encode(payload, private_key, algorithm='RS256')
print(f"JWT Token:\n{token}")
print(f"\nValid until: {expire}")
```

Run the script:
```bash
pip3 install pyjwt cryptography
python3 generate_jwt.py
```

**Option B: Use OpenLineage to Generate Token Automatically**

OpenLineage can generate the JWT token automatically if you provide the private key path. Update your config:

```yaml
transport:
  type: http
  url: https://YOUR-PROD-ACCOUNT.snowflakecomputing.com
  endpoint: /api/v2/lineage/external-lineage
  auth:
    type: snowflake_jwt
    privateKeyPath: /path/to/snowflake_lineage_key.p8
    account: YOUR-PROD-ACCOUNT
    user: dbt_lineage_svc
  compression: gzip
```

**Note**: Check OpenLineage documentation to confirm this auth type is supported.

#### Step 1.5: Test Your JWT Token

Test that the token works by making a test API call:

```bash
# Replace with your values
JWT_TOKEN="eyJ0eXAiOiJKV1QiLsecuritytoken..."
ACCOUNT="myorg-prod_account"

curl -X POST \
  "https://${ACCOUNT}.snowflakecomputing.com/api/v2/lineage/external-lineage" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"test": "connection"}'
```

If successful, you should get a response (may be an error about payload format, but confirms auth works).

### Important Notes

- **JWT tokens expire** - typically after 1 hour. For production, you may need to:
  - Use the private key method (Option B) so tokens regenerate automatically
  - Or set up a token refresh mechanism
  
- **Keep private key secure** - Store in a secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)

- **For dbt Cloud** - You'll need to store either:
  - The JWT token (needs refresh mechanism)
  - The private key path (preferred - auto-generates tokens)

### Need Help?

Contact your Snowflake account team for:
- Enabling External Lineage preview feature
- Confirming required permissions for the service account
- Troubleshooting authentication issues

🔗 **Reference**: [Snowflake External Lineage Authentication](https://docs.snowflake.com/en/user-guide/external-lineage#label-external-lineage-auth)

### Update Configuration File

Edit [`openlineage.yml`](../openlineage.yml):

```yaml
transport:
  type: http
  url: https://YOUR-PROD-ACCOUNT.snowflakecomputing.com  # ← Update this
  endpoint: /api/v2/lineage/external-lineage
  auth:
    type: api_key
    apiKey: YOUR_JWT_TOKEN_HERE  # ← Update with JWT token from Snowflake
  compression: gzip

namespace: production
```

**Important**: The `apiKey` should be a valid JWT token that authenticates with your Snowflake account. Work with your Snowflake account team to obtain this.

## Step 2: Configure dbt Cloud Production Job

### Access Your Production Job

1. Log into [dbt Cloud](https://cloud.getdbt.com/)
2. Navigate to **Deploy** → **Jobs**
3. Find your **Production** job (the one scheduled for 7am EST daily)
   - Note the Job ID for your Production job from the dbt Cloud UI

### Update Job Commands

**Current commands** (example):
```bash
dbt seed --target prod
dbt run --target prod
dbt test --target prod
```

**Updated commands** (with lineage):
```bash
dbt seed --target prod
dbt-ol run --target prod
dbt-ol test --target prod
```

**Key changes:**
- Replace `dbt run` with `dbt-ol run`
- Replace `dbt test` with `dbt-ol test`
- Replace `dbt build` with `dbt-ol build`
- Keep `dbt seed` as-is (seeds don't need lineage tracking)

### Add Environment Variables

In your Production job settings, add these environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `OPENLINEAGE_CONFIG` | `/usr/app/dbt/openlineage.yml` | Path to config file in dbt Cloud |

**Alternative: Use inline environment variables instead of config file:**

| Variable | Value |
|----------|-------|
| `OPENLINEAGE_URL` | `https://YOUR-PROD-ACCOUNT.snowflakecomputing.com` |
| `OPENLINEAGE_ENDPOINT` | `/api/v2/lineage/external-lineage` |
| `OPENLINEAGE_API_KEY` | `YOUR_PRODUCTION_API_KEY` |
| `OPENLINEAGE_NAMESPACE` | `production` |
| `OPENLINEAGE_TRANSPORT_TYPE` | `http` |
| `OPENLINEAGE_COMPRESSION` | `gzip` |

> **Recommendation**: Use environment variables method for dbt Cloud as it's easier to manage secrets.

## Step 3: Ensure Package is Installed

### Check dbt Cloud Package Installation

The `openlineage-dbt` package needs to be available in your dbt Cloud environment.

**Option A: Add to `packages.yml`** (if your dbt Cloud supports Python packages)

Check if your dbt Cloud environment includes the package, or contact dbt Cloud support to add it.

**Option B: Use dbt Cloud Custom Environment**

If your plan supports it, create a custom Docker image with the package:

```dockerfile
FROM fishtownanalytics/dbt:latest
RUN pip install openlineage-dbt
```

## Step 4: Test the Setup

### Trigger a Test Run

1. In dbt Cloud, manually trigger your Production job
2. Monitor the run logs
3. Look for this output:

```
Completed successfully
Done. PASS=X WARN=0 ERROR=0 SKIP=0 TOTAL=X
Emitted X openlineage events.
```

### Verify in Snowflake

1. Log into Snowsight
2. Navigate to the table/view that was built
3. Click the **Lineage** tab
4. You should see enriched metadata including:
   - dbt model names
   - Job execution details
   - Timestamps with "production" namespace

## Step 5: Keep Other Environments Unchanged

**Important**: Only change your Production job. Other jobs should continue using regular `dbt` commands:

### QA Job
```bash
dbt run --target qa  # ← No change, keep using dbt
dbt test --target qa
```

### Dev/PR Jobs
```bash
dbt run --target dev  # ← No change, keep using dbt
dbt test --target dev
```

This keeps your development cycle fast while capturing lineage only in production where it matters most.

## Troubleshooting

### "Command not found: dbt-ol"

**Solution**: Ensure `openlineage-dbt` is installed in your dbt Cloud environment. Contact dbt Cloud support if needed.

### No lineage events emitted

**Checklist:**
- [ ] `openlineage-dbt` package is installed
- [ ] Environment variables are set correctly
- [ ] Snowflake API key is valid
- [ ] External Lineage is enabled in Snowflake account
- [ ] Commands use `dbt-ol` instead of `dbt`

### Authentication errors

**Solution**: 
- Verify API key has correct permissions
- Check Snowflake account identifier is correct
- Ensure endpoint URL matches your region

### Want to test locally first?

Use the [`openlineage.yml`](../openlineage.yml) config (non-prod) to test:

```bash
source .venv/bin/activate
dbt-ol run --select your_model
```

## Rollback Plan

If you need to disable lineage tracking:

1. Go to dbt Cloud Production job
2. Change commands back from `dbt-ol` to `dbt`
3. Remove environment variables
4. Save and deploy

Your production job will work exactly as before.

## Monitoring

After setup, monitor your production runs:

1. **dbt Cloud logs**: Check for "Emitted X openlineage events" message
2. **Snowflake lineage**: Verify data appears in Snowsight
3. **Run time**: Monitor if `dbt-ol` adds significant overhead (usually minimal)

## Schedule Information

Your current production schedule:
- **Frequency**: Daily
- **Time**: 7:00 AM EST
- **Target**: prod
- **Job ID**: (find your job ID in dbt Cloud)

The lineage data will be captured automatically with each scheduled run.

## Additional Resources

- [Main OpenLineage Documentation](./snowflake_external_lineage.md)
- [dbt Cloud Documentation](https://docs.getdbt.com/docs/dbt-cloud/cloud-overview)
- [Snowflake External Lineage Docs](https://docs.snowflake.com/en/user-guide/data-lineage-external)

## Questions?

- **dbt Cloud package support**: Contact dbt Cloud support
- **Snowflake External Lineage**: Contact your Snowflake account team
- **OpenLineage issues**: Check [OpenLineage GitHub](https://github.com/OpenLineage/OpenLineage)
