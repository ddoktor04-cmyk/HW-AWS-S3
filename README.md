# AWS Terraform — Static Website on S3 (hwbarabash1.pp.ua)

Infrastructure as Code (IaC) project: a **static website hosted on Amazon S3**
using the S3 Static Website Hosting feature, published at `hwbarabash1.pp.ua`
via a CNAME record.

## Architecture

```
        Internet
            |
            |  HTTP (no certificate - S3 website endpoints are HTTP only)
            v
 hwbarabash1.pp.ua ──CNAME──> hwbarabash1.pp.ua.s3-website.eu-north-1.amazonaws.com
                                    |
                                    v
                          +---------------------+
                          |   S3 bucket         |
                          |   hwbarabash1.pp.ua |
                          |   - index.html      |
                          |   - public read     |
                          |   - website config  |
                          +---------------------+
```

- **S3 bucket** stores the site objects (`index.html`)
- **Bucket policy** allows anonymous `s3:GetObject` (public read)
- **Website configuration** serves `index.html` for both the index and error documents
- **CNAME record** `hwbarabash1.pp.ua` → S3 website endpoint is added manually in
  the nic.ua panel, because Terraform cannot manage DNS outside AWS
- **Bucket name = domain name**: S3 picks the bucket from the `Host` header, so
  the CNAME only works when the bucket is named exactly `hwbarabash1.pp.ua`

> Note: S3 website endpoints support **HTTP only**. For HTTPS a certificate
> (CloudFront + ACM) would be required — out of scope for this lab.

## Project Structure

```
cmd521_terraform/
├── main.tf                    # AWS provider
├── s3.tf                      # Bucket, public access block, policy, website config, object upload
├── vars.tf                    # Variable declarations (aws_access_key, aws_secret_key, aws_region, bucket_name)
├── outputs.tf                 # website_endpoint, site_url, cname_name, cname_value
├── files/
│   └── index.html             # Website content ("Static web сайт на основі сервісу AWS S3")
├── terraform.tfvars           # Secrets (not in git)
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## Usage

### 1. Configure credentials

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: fill in aws_access_key, aws_secret_key
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Open the site

Direct S3 endpoint (available immediately after apply):

```
http://hwbarabash1.pp.ua.s3-website.eu-north-1.amazonaws.com/
```

### 4. Attach the domain hwbarabash1.pp.ua (manual, nic.ua panel)

Terraform cannot manage DNS outside AWS, so the domain is connected by hand in
the [nic.ua](https://nic.ua) panel.

#### Step 1 — Switch to the NIC.UA name servers

1. nic.ua → **Domains** (`Мои домены`) → `hwbarabash1.pp.ua` → **gear icon** →
   **NS servers** (`NS-серверы`)
2. Choose **«Серверы имен NIC.UA»** (NIC.UA name servers: `ns1.uadns.com`,
   `ns2.uadns.com`, `ns3.uadns.com`)
3. Press **Change NS** (`Изменить NS`)

While the domain sits on the *parked* name servers (`parked1/2.uadns.com`) it
serves the nic.ua parking page and **ignores the records below** — the NS change
must come first.

#### Step 2 — Clean up and add the DNS record

Go to **Name Servers (NS) → gear icon → DNS records → Change** and make the zone
contain **exactly one record** for `@`:

1. **Delete** the parked **A** record for `@` (`135.181.41.169`) — it serves the
   parking page and would clash with the CNAME.
2. **Delete** the **MX** record for `@` (`mail.hwbarabash1.pp.ua`) — no email on
   this domain. A CNAME must not coexist with `A`/`MX` at the same name.
3. **Delete any duplicate CNAME** for `@`. If the panel answers
   «Запис такого типу вже існує» (*"a record of this type already exists"*),
   a second `@` CNAME is already in the list — keep only one.
4. **Add** (or keep) a single record:

| Type  | Name | Value                                              | TTL  |
|-------|------|----------------------------------------------------|------|
| CNAME | `@`  | `hwbarabash1.pp.ua.s3-website.eu-north-1.amazonaws.com.` | 3600 |

> The trailing dot in the value is mandatory (absolute record), otherwise
> nic.ua appends `hwbarabash1.pp.ua` to it and the record breaks.

Optionally add the same CNAME under `www` (`www.hwbarabash1.pp.ua` is parked the
same way today). Terraform output `cname_value` always prints the current value.

#### Step 3 — Wait and verify (15 min – 2 h after the NS change)

```powershell
Resolve-DnsName hwbarabash1.pp.ua -Type NS      # expect ns1-3.uadns.com, NOT parked1/2
Resolve-DnsName hwbarabash1.pp.ua -Type CNAME   # expect hwbarabash1.pp.ua.s3-website.eu-north-1.amazonaws.com
curl http://hwbarabash1.pp.ua/                  # expect HTTP 200
```

### 5. Tear down

```bash
terraform destroy
```

## Outputs

| Output            | Description                                            |
|-------------------|--------------------------------------------------------|
| `bucket_id`       | Bucket name (`hwbarabash1.pp.ua`)                      |
| `bucket_arn`      | Bucket ARN                                             |
| `website_endpoint`| S3 website endpoint hostname                           |
| `site_url`        | Full HTTP URL of the site                              |
| `cname_name`      | DNS name to configure (`hwbarabash1.pp.ua`)            |
| `cname_value`     | CNAME target for the registrar panel                   |

## Limitations

- **No access by bare IP address**: S3 website endpoints route every request by
  the `Host` header (the bucket name is taken from it), and the endpoint IPs are
  not static (they change between lookups, e.g. `3.5.216.102` → `3.5.218.145`).
  Opening `http://<endpoint-ip>/` in a browser sends `Host: <ip>` and returns an
  AWS error page instead of the site. Serving the site by a literal IP would
  require an EC2 instance with an Elastic IP reverse-proxying to S3 — out of
  scope for this lab (S3-only, no server).
- **HTTP only**: website endpoints do not support TLS (see Security Notes).

## Security Notes

- `terraform.tfvars` contains AWS credentials and is ignored by git — never commit it
- The bucket is intentionally **public-read** (required for a static website)
- No HTTPS-only deny statement: S3 website endpoints are HTTP-only, such a policy would return 403
- Destroy the lab when not in use: `terraform destroy`
