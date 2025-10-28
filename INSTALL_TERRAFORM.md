# Install Terraform on Windows

## Option 1: Using Chocolatey (Recommended)

### Step 1: Install Chocolatey (if not already installed)
Open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Step 2: Install Terraform
```powershell
choco install terraform -y
```

### Step 3: Verify Installation
```powershell
terraform --version
```

---

## Option 2: Manual Installation

### Step 1: Download Terraform
Visit: https://www.terraform.io/downloads

Download the Windows AMD64 version (terraform_1.x.x_windows_amd64.zip)

### Step 2: Extract the ZIP
Extract `terraform.exe` to a folder like:
```
C:\Program Files\Terraform\
```

### Step 3: Add to PATH
1. Press `Win + X` → Select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "System variables", find "Path"
5. Click "Edit" → "New"
6. Add: `C:\Program Files\Terraform`
7. Click "OK" on all windows

### Step 4: Restart PowerShell
Close and reopen PowerShell

### Step 5: Verify Installation
```powershell
terraform --version
```

You should see:
```
Terraform v1.x.x
on windows_amd64
```

---

## Option 3: Using Winget (Windows Package Manager)

```powershell
winget install HashiCorp.Terraform
```

Then restart PowerShell and verify:
```powershell
terraform --version
```

---

## Quick Test

After installation, test Terraform:

```powershell
# Check version
terraform --version

# Check help
terraform --help
```

---

## Next Steps

Once Terraform is installed, proceed with:

```powershell
cd C:\Users\klejd\Desktop\devops-practice\terraform\environments\dev
terraform init
terraform plan
terraform apply
```

Let me know which installation method you prefer, or let me know once Terraform is installed!
