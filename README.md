# Mead Order App — ACA + Azure MySQL

This project deploys the **Mead Order App** fully in **Azure Container Apps** with a managed **Azure Database for MySQL Flexible Server**.  
The automation is handled with **GitHub Actions** using `deploy.yml`.  

---

## 🔧 Features
- Build and push container images to **Docker Hub**
- Deploy to **Azure Container Apps** via **Azure CLI**
- Provision and connect to **Azure MySQL Flexible Server**
- OIDC-based GitHub → Azure authentication (no secrets for service principals)
- Optional cleanup to remove all resources

---

## 📂 Repository Structure
```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD pipeline for ACA + MySQL
├── Dockerfile              # Web app (PHP + Nginx + Supervisord)
├── nginx/
│   └── default.conf
├── supervisord.conf
├── src/
│   ├── index.html          # Order form
│   └── order.php           # Form submission logic
└── README.md
```

---

## Required Secrets
Set the following repository **secrets** in GitHub:

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `DB_ADMIN_USER`
- `DB_ADMIN_PASSWORD`

---

## Run the Workflow
Trigger the workflow manually:

1. Go to **Actions** → **Deploy ACA MySQL (CLI)**  
2. Select **Run workflow**  
3. Provide inputs:
   - `rg` → Resource Group (e.g. `mead-rg`)  
   - `location` → Azure region (e.g. `northeurope`)  
   - `imageRef` → Docker image tag (e.g. `avenr/aca-nginx-php:mead-sql`)  
   - `cleanup` → `true/false` (whether to delete RG after deploy)  

Example (CLI):
```bash
gh workflow run deploy.yml --ref main \
  -f rg=mead-rg \
  -f location=northeurope \
  -f imageRef=avenr/aca-nginx-php:mead-sql \
  -f cleanup=false
```

---

## 📝 Notes
- MySQL Flexible Server username format: **only the username** (no `@servername`).  
- TLS is enforced by default. The container trusts system CAs.  
- Default container app uses:  
  - CPU: **0.5 vCPU**  
  - Memory: **1 GiB**  
  - Ingress: external on port **80** (mapped to container port **8080** internally).  

---

## Next Steps
- Extend app with a **page to view submitted orders** (PHP + DB query).  
- Add **Bicep template** (`main.bicep`) for full IaC automation.  
- Optional: Configure GitHub to **build Docker images automatically** (instead of manual build/push).  
