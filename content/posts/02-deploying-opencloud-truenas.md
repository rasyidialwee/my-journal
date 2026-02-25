---
title: "How I Deployed OpenCloud on TrueNAS Scale: A Lightweight Alternative to Nextcloud"
date: 2026-01-17T11:30:00+08:00
draft: false
weight: 2
tags: ["opencloud", "truenas", "docker", "dockge", "cloudflare", "self-hosted", "tutorial", "postgresql"]
cover:
  image: "/images/02.png"
  alt: "Deploying OpenCloud on TrueNAS Scale with Docker and Cloudflare Tunnel"
---

I've been running my homelab on TrueNAS Scale for a while now, and I've always wanted a self-hosted file management solution. You know, something like Dropbox or Google Drive, but running on my own infrastructure. My first instinct was Nextcloud—it's the most popular option, right? But as I started researching, I realized it was heavier than I needed. Nextcloud can be resource-intensive, and I wanted something lighter.

That's when I discovered **OpenCloud**. It's a lightweight, open-source file management and collaboration platform that serves as an excellent alternative to Nextcloud. What caught my attention was that it uses less than 100MB of RAM while still offering robust file management features. Perfect for my homelab setup.

After spending some time deploying it on my TrueNAS Scale system using Dockge for container management, I thought I'd document the process. There were a few gotchas along the way—especially around initialization and Cloudflare Tunnel configuration—that I wish someone had told me about upfront. So here's my journey and what I learned.

## What I Used

I deployed OpenCloud with:
- **PostgreSQL** as the database backend (more reliable than SQLite for production use)
- **Dockge** for managing my Docker Compose stacks (much cleaner than Portainer for this use case)
- **Cloudflare Tunnel** for secure public access (no port forwarding needed, and SSL handled automatically)

## Prerequisites

Before we dive in, make sure you have:
- TrueNAS Scale installed and running
- Dockge already set up on your TrueNAS system
- A domain name configured with Cloudflare
- Cloudflare Tunnel set up and ready to use
- Basic familiarity with SSH and terminal commands

## Part 1: Creating Datasets

One thing I learned early on with TrueNAS is that data organization matters. When I first started using Dockge, I made the mistake of storing everything inside Dockge's stack directory. That made backups and migrations a nightmare. So now, I always create separate datasets for each application.

For OpenCloud, I created a dedicated dataset structure:

1. Navigate to **Datasets** in TrueNAS Scale
2. Select your main storage pool
3. Click **Add Dataset** and create the following structure:

**Main dataset:**
- Name: `opencloud`
- Dataset Preset: Generic

**Subdatasets** (with opencloud selected as parent):
- `app-data` - For OpenCloud configuration files
- `user-data` - For user files and documents
- `database` - For PostgreSQL data

Your final structure should look like:

```
/mnt/your-pool/opencloud/
├── app-data/
├── user-data/
└── database/
```

### Setting Permissions

This is where I made my first mistake. I didn't set the permissions correctly, and OpenCloud couldn't write to the directories. After some troubleshooting, I learned that containers run with specific user IDs, and those need to match your dataset permissions.

SSH into your TrueNAS server and run these commands:

```bash
# Set permissions for OpenCloud directories
sudo chown -R 1000:1000 /mnt/your-pool/opencloud/app-data
sudo chown -R 1000:1000 /mnt/your-pool/opencloud/user-data

# Set permissions for PostgreSQL
sudo chown -R 999:999 /mnt/your-pool/opencloud/database
sudo chmod -R 700 /mnt/your-pool/opencloud/database
```

**Why these specific UIDs?**
- UID 1000:1000 is the default user inside the OpenCloud container
- UID 999:999 is the postgres user in the PostgreSQL Alpine container

## Part 2: Initializing OpenCloud

Here's the part that tripped me up initially. OpenCloud requires proper initialization before the first run. This creates essential configuration files including JWT secrets and system credentials. I tried skipping this step and just running the container—big mistake. It kept throwing "missing or invalid config" errors.

### Running the Init Command

```bash
sudo docker run --rm \
  -v /mnt/your-pool/opencloud/app-data:/etc/opencloud \
  -v /mnt/your-pool/opencloud/user-data:/var/lib/opencloud \
  -e OC_URL=https://your-domain.com \
  -e INSECURE=true \
  opencloudeu/opencloud:2 init --insecure true
```

**Important:** Save the admin password that's generated! You'll see output like:

```
=========================================
 generated OpenCloud Config
=========================================
 configpath : /etc/opencloud/opencloud.yaml
 user       : admin
 password   : [RANDOMLY_GENERATED_PASSWORD]
```

I made the mistake of not saving this password the first time. Had to re-run the init command, which wasn't a big deal, but it's annoying when you're eager to get things running.

**Key points about initialization:**
- The OC_URL must match how you'll access OpenCloud (your public domain)
- INSECURE=true tells OpenCloud to accept self-signed certificates
- This only needs to be run once—the config persists in your dataset

## Part 3: Creating the Docker Compose Stack

Now for the fun part—creating the actual application stack in Dockge. I love how Dockge makes managing Docker Compose stacks so much easier than doing it manually.

### Creating the Stack

1. Open Dockge at `http://your-truenas-ip:5001`
2. Click **+ Compose**
3. Stack Name: `opencloud`
4. Paste the following configuration:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: opencloud-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: opencloud
      POSTGRES_USER: opencloud
      POSTGRES_PASSWORD: YourSecurePassword123
    volumes:
      - /mnt/your-pool/opencloud/database:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U opencloud"]
      interval: 10s
      timeout: 5s
      retries: 5

  opencloud:
    image: opencloudeu/opencloud:2
    container_name: opencloud
    restart: unless-stopped
    ports:
      - "9200:9200"
    volumes:
      - /mnt/your-pool/opencloud/app-data:/etc/opencloud
      - /mnt/your-pool/opencloud/user-data:/var/lib/opencloud
    environment:
      - OC_URL=https://your-domain.com
      - INSECURE=true
      - PROXY_HTTP_ADDR=0.0.0.0:9200
      - DATABASE_DRIVER=postgres
      - DATABASE_DSN=postgres://opencloud:YourSecurePassword123@postgres:5432/opencloud?sslmode=disable
    depends_on:
      postgres:
        condition: service_healthy

networks:
  default:
    name: opencloud-network
```

**Important configuration notes:**
- Replace `your-pool` with your actual pool name
- Replace `YourSecurePassword123` with a secure password (must match in both places)
- Replace `your-domain.com` with your actual domain
- The OC_URL MUST match the domain you'll use to access OpenCloud—this caused me issues later when I had a mismatch

### Deploying the Stack

1. Click **Deploy** in Dockge
2. Wait 30-60 seconds for both containers to start
3. Check the logs—you should see:
   - PostgreSQL: "database system is ready to accept connections"
   - OpenCloud: Various services starting without errors

## Part 4: Configuring Cloudflare Tunnel

Since I'm already using Cloudflare Tunnel for my blog and other services, exposing OpenCloud was straightforward. But there was one critical setting I missed initially that caused 502 errors.

### Creating the Public Hostname

1. Go to Cloudflare Zero Trust Dashboard
2. Navigate to **Networks → Tunnels**
3. Select your tunnel (or create a new one)
4. Click **Add a public hostname**

**Configuration:**
- Subdomain: `your-subdomain` (e.g., cloud)
- Domain: `your-domain.com`
- Service Type: HTTPS
- URL: `https://192.168.x.x:9200` (your TrueNAS IP)

### The Critical Setting

Click the gear icon next to the service URL and configure:

**TLS Settings:**
- No TLS Verify: ✅ **ENABLE** (critical!)

  This allows Cloudflare to connect despite OpenCloud's self-signed certificate. I spent way too long troubleshooting 502 errors before I found this setting. OpenCloud uses self-signed certificates internally, and Cloudflare Tunnel needs to be told to accept them.

**HTTP Settings:**
- HTTP/2 connection: ✅ Enable (for better performance)
- WebSockets: ✅ Enable (if available)
- HTTP Host Header: `your-subdomain.your-domain.com`
- Origin Server Name: `192.168.x.x`

### Testing

1. Click **Save** in Cloudflare
2. Wait 30 seconds for the tunnel to update
3. Try accessing `https://your-subdomain.your-domain.com`

You should now see the OpenCloud login page with a valid SSL certificate from Cloudflare!

## Part 5: First Login and Verification

### Logging In

1. Navigate to `https://your-subdomain.your-domain.com`
2. Log in with:
   - Username: `admin`
   - Password: [The password from Step 3]

### Testing Everything Works

To verify everything is working:

**Create a test user:**
1. Go to **Admin Settings → Users**
2. Create a new user
3. Edit the user details

**Upload a test file:**
1. Navigate to **Files**
2. Upload a document
3. Verify it appears in `/mnt/your-pool/opencloud/user-data`

**One quirk I noticed:**
If you see "failed" notifications but changes actually work, that's normal. Just refresh the page to see updated data. This is a known quirk when using reverse proxies like Cloudflare Tunnel. The operations succeed, but the response headers don't match what the frontend expects.

## Troubleshooting: What I Learned the Hard Way

### Issue 1: "Missing or invalid config" Error

I got this error when I tried to skip the initialization step. OpenCloud can't find or read its configuration.

**Solution:**
- Ensure OC_URL in docker-compose matches your access URL exactly
- Verify the init command was run successfully
- Check that `opencloud.yaml` exists in `/mnt/your-pool/opencloud/app-data/`

### Issue 2: 502 Bad Gateway via Cloudflare Tunnel

This was the most frustrating one. I kept getting 502 errors, and it took me a while to realize it was the TLS verification setting.

**Solution:**
- Verify "No TLS Verify" is enabled in Cloudflare Tunnel settings
- Check that the service URL is correct: `https://192.168.x.x:9200`
- Ensure OpenCloud container is running in Dockge

### Issue 3: "Invalid credentials" in LDAP/IDP Logs

I saw this when I changed database passwords but didn't update the configuration properly.

**Solution:**
1. Stop the stack
2. Clear all data: `sudo rm -rf /mnt/your-pool/opencloud/{app-data,user-data,database}/*`
3. Re-run the init command
4. Redeploy the stack

### Issue 4: Token Expired / Invalid Issuer Errors

This happened when I changed my domain or OC_URL after initial setup. The OC_URL doesn't match how you're accessing OpenCloud.

**Solution:**
- Ensure OC_URL in docker-compose matches your Cloudflare domain
- Restart the stack
- Log out and log back in to get a new token

### Issue 5: Operations Succeed but Show Error Notifications

As I mentioned earlier, this is cosmetic. The operations actually work.

**Solution:**
- This is cosmetic—the operations actually work
- Refresh the page to see changes
- Setting the HTTP Host Header in Cloudflare may help

## Best Practices I Follow

### Data Management

- **Snapshots:** I use TrueNAS snapshot tasks for my OpenCloud datasets. It's saved me a few times when I made configuration mistakes.
- **Backups:** I back up the three datasets separately for flexibility. If I need to migrate, I can move them independently.
- **Replication:** I'm considering replicating to another TrueNAS system for redundancy, but haven't set that up yet.

### Security

- Change the default admin password after first login (obviously)
- Enable 2FA in OpenCloud settings
- Use Cloudflare Access policies for additional authentication layers if needed
- Keep your database password secure and complex

### Performance

- Monitor container resource usage in Dockge—OpenCloud really is lightweight
- Consider increasing PostgreSQL shared_buffers for better performance if you have the RAM
- Enable HTTP/2 and compression in Cloudflare for faster loading

### Maintenance

- Regularly update container images in Dockge
- Monitor OpenCloud logs for unusual activity
- Test your backups periodically

## Final Thoughts

After running OpenCloud for a while now, I'm really happy with the choice. It's lightweight, fast, and does everything I need without the overhead of Nextcloud. The setup process had its challenges, but once everything was configured correctly, it's been rock solid.

The key lessons I learned:
- Initialize OpenCloud with the correct OC_URL before first run
- Use absolute paths in docker-compose to keep data outside Dockge
- Enable "No TLS Verify" in Cloudflare Tunnel for self-signed certificates
- Ensure OC_URL matches your access method to avoid token issues

If you're looking for a lightweight self-hosted file management solution and you're already running TrueNAS Scale, OpenCloud is definitely worth considering. It might not have all the bells and whistles of Nextcloud, but for my use case, it's perfect.

---

*If you encounter problems not covered here, check the OpenCloud GitHub repository or the TrueNAS community forums for additional help. And if you've deployed OpenCloud yourself, I'd love to hear about your experience!*
