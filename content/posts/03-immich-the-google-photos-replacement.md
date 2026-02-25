---
title: "Setting Up Immich on TrueNAS Scale: My Photo Backup Solution"
date: 2026-02-06T11:30:00+08:00
draft: false
weight: 2
tags: ["immich", "truenas", "self-hosted", "photo-backup", "tutorial"]
cover:
  image: "/images/immich-01-apps-service.png"
  alt: "Setting up Immich on TrueNAS Scale for self-hosted photo backup"
---

I've been on a journey to find the perfect solution for backing up my photos and videos. It started with OneDrive—the price made sense at the time, and it was convenient. But as my photo library grew and I became more privacy-conscious, I wanted something I controlled. So I migrated to Nextcloud, thinking it would be the perfect self-hosted solution. It worked, but it felt heavy for what I needed.

Then I discovered [OpenCloud](/posts/02-deploying-opencloud-truenas/), which I've been using for general file management. It's lightweight and perfect for documents and files. But for photos? I needed something purpose-built. Something that could handle thousands of photos, automatically organize them, and provide a beautiful interface for browsing memories.

That's when I found **Immich**—a self-hosted photo and video backup solution that runs directly from your mobile phone. After two months of using it, I can confidently say it's been a game-changer. The automatic backup, face recognition, and smart search features make it feel like having your own personal Google Photos, but running entirely on your own infrastructure.

If you're running TrueNAS Scale and want to set up Immich, here's my complete walkthrough of the setup process.

## What is Immich?

Immich is an open-source, self-hosted photo and video backup solution. Think of it as your own personal Google Photos or iCloud Photos, but you control everything. It offers:

- **Automatic backup** from mobile devices
- **Face recognition** and object detection
- **Smart search** using machine learning
- **Album organization** and sharing
- **Video playback** and transcoding
- **Beautiful web interface** and mobile apps

What sets Immich apart is that it's designed specifically for photos and videos, not trying to be a general file storage solution. This focus makes it faster, more intuitive, and better at handling large photo libraries than general-purpose solutions.

## Prerequisites

Before we dive in, make sure you have:

- **TrueNAS Scale** installed and running
- **Apps service** enabled and running (for deploying containerized applications)
- **Basic familiarity** with TrueNAS Apps interface
- **Storage space** allocated for your photos (I recommend at least 100GB to start)

## Step 1: Discovering and Installing Immich

The first step is finding Immich in the TrueNAS Apps catalog. TrueNAS Scale makes this incredibly easy with its built-in app discovery.

![Apps Service Running interface](/images/immich-01-apps-service.png)

1. Navigate to **Apps** in the TrueNAS Scale web interface
2. Ensure the **Apps Service** is running (you'll see a green checkmark if it is)
3. Click **Discover Apps** to browse the available applications

![Search results for Immich](/images/immich-02-discover-search.png)

4. In the search bar, type **"Immich"**
5. You'll see Immich appear in the search results under the **Media** category
6. Click on the Immich card to begin installation

**Note:** If you see an "Installed" badge on the Immich card, it means you've already installed it. You can click on it to manage or reconfigure your existing installation.

## Step 2: Basic Configuration

Once you click on Immich, you'll be taken to the configuration screen. This is where you'll set up the core settings for your Immich instance.

![Immich Configuration screen](/images/immich-03-configuration.png)

### Core Settings

**Timezone:**
- Select your timezone (I chose `Asia/Kuala_Lumpur`). This is important for proper date/time organization of your photos.

**Postgres Image:**
- I selected **Postgres 18** (marked with CAUTION). This is the database backend that Immich uses. Postgres 18 is stable and well-supported, but make sure you're comfortable with this version.

**Database Storage Type:**
- Choose **SSD** if your storage pool uses SSDs, or select the appropriate type for your setup. This helps Immich optimize database performance.

**Database Password & Redis Password:**
- Set strong, unique passwords for both. These are critical for security. I recommend using a password manager to generate and store these securely.
- The passwords are masked by default—use the eye icon to toggle visibility when entering them.

### Machine Learning Configuration

![Machine Learning settings](/images/immich-04-machine-learning.png)

Immich's machine learning features are what make it special. These enable face recognition, object detection, and smart search.

**Enable Machine Learning:**
- I recommend **enabling this** if you have the resources. It's what makes Immich feel like Google Photos.

**Machine Learning Image Type:**
- I kept the **Default Machine Learning Image**. Unless you have specific requirements, the default works well.

**Log Level:**
- Set to **Log** for normal operation. You can increase verbosity if you're troubleshooting.

**Hugging Face Endpoint:**
- Leave this empty unless you have a custom endpoint. The default works fine for most users.

## Step 3: User and Group Configuration

![User and Group Configuration](/images/immich-05-user-group.png)

This section configures the user and group IDs that Immich will use inside the container. This is important for file permissions.

**User ID & Group ID:**
- I set both to **568**. This should match a user/group on your TrueNAS system that has appropriate permissions to your storage datasets.
- If you're unsure, you can use the default values or check your existing user IDs in TrueNAS.

**Why this matters:** When Immich writes photos to your storage, it needs the correct permissions. Matching the container's UID/GID with your TrueNAS user ensures files are created with the right ownership.

## Step 4: Network Configuration

![Network Configuration](/images/immich-06-network.png)

Here's where you configure how Immich will be accessible on your network.

**WebUI Port:**
- This is the port where Immich's web interface will be accessible.

**Port Bind Mode:**
- I selected **"Publish port on the host for external access"**. This makes Immich accessible from other devices on your network.

**Port Number:**
- I used **30041** as the port. Choose any available port that doesn't conflict with other services.

**Host IPs:**
- I added **0.0.0.0** which means Immich will listen on all network interfaces. This makes it accessible from any device on your network.

**Accessing Immich:** After deployment, you'll access Immich at `http://your-truenas-ip:30041` (or whatever port you chose).

## Step 5: Storage Configuration

This is one of the most important steps. You need to configure where Immich will store your photos and its database.

![Storage Configuration](/images/immich-07-storage.png)

### Data Storage (Upload Location)

**Type:**
- Select **"Host Path (Path that already exists on the system)"**

**Host Path:**
- I created `/mnt/storage/immich/data` for storing all uploaded photos and videos.
- You can use the **"+ Create Dataset"** button if the path doesn't exist yet.

**Enable ACL:**
- I left this unchecked, but you may need it depending on your TrueNAS permissions setup.

### Machine Learning Cache

**Type:**
- I selected **"Temporary (Temporary directory created on the disk)"**. This is fine for ML cache since it can be regenerated.

### Postgres Data Storage

![Postgres Storage Configuration](/images/immich-08-postgres-storage.png)

**Type:**
- Select **"Host Path (Path that already exists on the system)"**

**Host Path:**
- I created `/mnt/storage/immich/pgdata` for PostgreSQL database files.
- Click **"+ Create Dataset"** if needed.

**Automatic Permissions:**
- I enabled this checkbox. It helps ensure the database has the correct permissions automatically.

### Creating the Datasets

Before configuring storage, you should create the datasets in TrueNAS:

1. Navigate to **Storage → Datasets** in TrueNAS
2. Create a parent dataset: `immich`
3. Create sub-datasets:
   - `immich/data` - For photos and videos
   - `immich/pgdata` - For PostgreSQL database

![Final dataset structure](/images/immich-10-datasets.png)

After setup, you can verify your datasets are created correctly. As you can see in my setup, the `data` dataset holds the bulk of storage (1.22 TiB), while `pgdata` is much smaller (3.94 GiB), which is expected.

## Step 6: Resources Configuration

![Resources Configuration](/images/immich-09-resources.png)

Immich can be resource-intensive, especially with machine learning enabled. Here's how I configured resources:

**CPUs:**
- I allocated **2 CPUs**. This provides enough processing power for photo processing and ML tasks without overwhelming my system.

**Memory:**
- I set **4096 MB (4 GB)** of RAM. This is sufficient for most use cases, but you may need more if you have a very large photo library or want faster ML processing.

**GPU Passthrough:**
- I left **"Passthrough available (non-NVIDIA) GPUs"** unchecked since I'm not using GPU acceleration. If you have a compatible GPU and want faster ML processing, you can enable this.

**Resource Tips:**
- Start with these values and monitor usage. You can always adjust later if needed.
- If Immich feels slow, consider increasing CPU or memory allocation.
- Machine learning tasks (face recognition, object detection) are the most resource-intensive.

## Deployment and First Access

Once you've configured all the settings:

1. Click **Update** (or **Deploy** if this is a new installation) at the bottom of the configuration screen
2. Wait 2-5 minutes for Immich to start up. You can monitor the progress in the Apps interface
3. Once the status shows "Running", navigate to `http://your-truenas-ip:30041` (or your configured port)

### Initial Setup in Immich

When you first access Immich:

1. You'll be prompted to create an admin account
2. Set up your admin username and password
3. Complete the initial setup wizard
4. Download the Immich mobile app (iOS or Android)
5. Connect your mobile device to start automatic backups

The mobile app is where Immich really shines—it automatically backs up your photos in the background, just like Google Photos, but to your own server.

## Troubleshooting: What I Learned

After two months of running Immich, here are some issues I encountered and how I solved them:

### Issue 1: Permission Errors When Uploading Photos

I got permission errors when trying to upload photos initially. The container couldn't write to the storage path.

**Solution:**
- Ensure the User ID and Group ID match a user with write permissions to your datasets
- Check dataset permissions in TrueNAS: `Storage → Datasets → Edit Permissions`
- You may need to SSH into TrueNAS and adjust permissions:
  ```bash
  sudo chown -R 568:568 /mnt/storage/immich/data
  ```

### Issue 2: Machine Learning Not Working

Face recognition and object detection weren't working even though ML was enabled.

**Solution:**
- Check that you allocated enough resources (CPU and memory)
- ML tasks run in the background and can take time to process large libraries
- Check the Immich logs in the Apps interface for ML-related errors
- Ensure you have enough storage space for the ML cache

### Issue 3: Slow Performance with Large Libraries

Initial indexing and ML processing was slow with my 1TB+ photo library.

**Solution:**
- Be patient—initial processing can take days for very large libraries
- Increase CPU and memory allocation if possible
- Consider disabling ML temporarily during initial import, then re-enable it
- Immich processes photos in the background, so you can continue using it while processing

### Issue 4: Port Conflicts

The default port was already in use by another service.

**Solution:**
- Choose a different port in Network Configuration
- Check what ports are in use: `System Settings → Services` in TrueNAS
- Common ports to avoid: 80, 443, 8080, 9000

## Best Practices After 2 Months

Here's what I've learned from running Immich for two months:

### Storage Management

- **Regular Snapshots:** Use TrueNAS snapshots for your Immich datasets. I take daily snapshots of both `data` and `pgdata` datasets. This saved me once when I accidentally deleted a large album.
- **Monitor Storage Growth:** Photos and videos accumulate quickly. Set up alerts in TrueNAS for storage thresholds.
- **Consider Compression:** Immich stores photos in their original format. If storage is a concern, you might want to enable compression in TrueNAS or use Immich's duplicate detection features.

### Backup Strategy

- **Dataset Replication:** I replicate my Immich datasets to another TrueNAS system for redundancy
- **External Backups:** Consider backing up critical photos to external storage periodically
- **Database Backups:** The `pgdata` dataset is small but critical—make sure it's included in your backup strategy

### Performance Tips

- **Resource Monitoring:** Keep an eye on CPU and memory usage, especially during initial ML processing
- **Network Speed:** For faster uploads from mobile devices, ensure good Wi-Fi connectivity
- **Storage Type:** Using SSDs for the database (`pgdata`) significantly improves search and browsing performance

### Mobile App Setup

- **Background Backup:** Enable background backup in the mobile app settings for automatic syncing
- **Battery Optimization:** Add Immich to your phone's battery optimization exceptions to ensure backups continue
- **Network Settings:** Configure the app to only backup on Wi-Fi if you have data limits

### Organization Tips

- **Use Albums:** Create albums for events, trips, or themes. Immich's smart search makes finding photos easy, but albums help with manual organization.
- **Face Recognition:** Train the face recognition by tagging people. The more you tag, the better it gets at recognizing faces automatically.
- **Search Features:** Use Immich's search to find photos by date, location, objects, or people. It's surprisingly accurate.

## Final Thoughts

After two months of using Immich, I'm extremely happy with the choice. It's replaced my need for cloud photo services entirely. The automatic backup from my phone works seamlessly, the face recognition is impressively accurate, and having full control over my photos gives me peace of mind.

**What I love:**
- Automatic background backup from mobile devices
- Face recognition that actually works well
- Beautiful, fast web interface
- Smart search that finds photos by content
- Complete control over my data

**What could be better:**
- Initial ML processing takes time for large libraries (but this is expected)
- Resource usage can be high with ML enabled (but worth it for the features)
- Some advanced features require technical knowledge to configure

**Comparison to Previous Solutions:**
- **vs. OneDrive:** Immich is purpose-built for photos, making it much better at organization and search
- **vs. Nextcloud:** Immich is faster, more intuitive, and better at handling large photo libraries
- **vs. OpenCloud:** They serve different purposes—OpenCloud for general files, Immich specifically for photos/videos

If you're looking for a self-hosted photo backup solution and you're already running TrueNAS Scale, Immich is absolutely worth setting up. The initial configuration might seem involved, but once it's running, it's been rock solid for me. The peace of mind of having my photos backed up to my own infrastructure, combined with features that rival commercial solutions, makes it a perfect fit for my homelab.

---

*Have you set up Immich or another self-hosted photo solution? I'd love to hear about your experience and any tips you've learned along the way!*
