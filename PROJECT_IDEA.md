cn# CloudScan - Open Source Security & Quality Scanning Platform

> **A self-hosted, enterprise-grade security and code quality scanning platform that democratizes access to comprehensive code analysis**

---

## 🌍 **The Problem We're Solving**

### **Current State of the Industry**

1. **Commercial Tools are Expensive**
   - SonarQube Enterprise: $150,000+/year
   - Snyk Enterprise: $50,000+/year
   - Checkmarx: $100,000+/year
   - Small teams and open-source projects can't afford these

2. **SaaS Solutions Have Privacy Concerns**
   - Code must be uploaded to third-party servers
   - Compliance issues (GDPR, HIPAA, SOC2)
   - Cannot be used for sensitive/proprietary code

3. **Fragmented Tooling**
   - Different tools for SAST, SCA, secrets detection, license compliance
   - No unified dashboard
   - Complex integration and maintenance

4. **Limited Self-Hosted Options**
   - Existing open-source tools lack enterprise features
   - Difficult to scale
   - Poor UX and limited integrations

### **Our Solution: CloudScan**

A **fully open-source, self-hosted** platform that provides:
- ✅ Multiple scan types in one platform (SAST, SCA, secrets, licenses)
- ✅ Beautiful web UI with real-time updates
- ✅ Horizontal scaling on Kubernetes
- ✅ Multi-tenant architecture for organizations
- ✅ Zero vendor lock-in - install on your infrastructure
- ✅ Enterprise features without enterprise pricing
- ✅ Easy installation via Helm chart
- ✅ Plugin architecture for custom scanners

---

## 🎯 **Target Users**

1. **Startups & SMBs** - Can't afford commercial tools
2. **Open Source Projects** - Need free, powerful scanning
3. **Enterprises** - Require on-premise deployment for compliance
4. **Government & Healthcare** - Data sovereignty requirements
5. **Educational Institutions** - Teaching secure coding practices
6. **Security Researchers** - Custom scanner integration

---

## 🏗️ **System Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                        User's Browser                           │
│                   https://cloudscan.mycompany.com               │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX Ingress Controller                     │
│              (TLS termination, routing, rate limiting)          │
└────┬──────────────────────┬─────────────────────┬───────────────┘
     │                      │                     │
     ▼                      ▼                     ▼
┌─────────────┐   ┌──────────────────┐   ┌─────────────────────┐
│  UI Service │   │  API Gateway     │   │  WebSocket Service  │
│  (React)    │   │  (Go - Echo)     │   │  (Go - Gorilla WS)  │
│             │   │  - REST/gRPC     │   │  - Live logs        │
│  Port: 3000 │   │  - Auth/RBAC     │   │  - Status updates   │
└─────────────┘   │  Port: 8080      │   │  Port: 9090         │
                  └────────┬─────────┘   └──────────┬──────────┘
                           │                        │
                           │                        │ Stream logs
                           ▼                        │ from K8s
                  ┌──────────────────────────────────────────────┐
                  │     Scan Orchestrator Service (Go)           │
                  │     - Job creation & lifecycle mgmt          │
                  │     - Kubernetes job dispatcher              │
                  │     - Multi-tenant isolation                 │
                  │     - gRPC APIs                              │
                  │     - Background workers (sweeper, etc)      │
                  │     Port: 9999 (gRPC), 8081 (HTTP)           │
                  └────┬──────────────────┬────────────────┬─────┘
                       │                  │                │
                       │                  │                │
                       ▼                  ▼                ▼
            ┌──────────────────┐   ┌─────────────────────┐
            │  Storage Service │   │  Kubernetes Cluster │
            │  (Go)            │   │  (Job Execution)    │
            │  - S3/GCS/Azure  │   │                     │
            │  - Presigned URLs│   └──────────┬──────────┘
            │  - Multi-cloud   │              │
            │  Port: 8082      │              │
            └────────┬─────────┘              ▼
                     │              ┌──────────────────────┐
                     │              │   Scanner Runners    │
                     │              │   (K8s Jobs/Pods)    │
                     │              │                      │
                     │              │  ┌────────────────┐  │
                     │              │  │  SAST Runner   │  │
                     │              │  │  (Semgrep)     │  │
                     │              │  └────────────────┘  │
                     │              │                      │
                     │              │  ┌────────────────┐  │
                     │              │  │  SCA Runner    │  │
                     │              │  │  (Trivy)       │  │
                     │              │  └────────────────┘  │
                     │              │                      │
                     │              │  ┌────────────────┐  │
                     │              │  │ Secrets Runner │  │
                     │              │  │ (TruffleHog)   │  │
                     │              │  └────────────────┘  │
                     │              │                      │
                     │              │  ┌────────────────┐  │
                     │              │  │License Runner  │  │
                     │              │  │ (ScanCode)     │  │
                     │              │  └────────────────┘  │
                     │              └──────────┬───────────┘
                     │                         │
                     ▼                         ▼
          ┌─────────────────────┐   ┌─────────────────────┐
          │   S3/MinIO/GCS      │   │   PostgreSQL        │
          │   (Object Store)    │   │   (Multi-tenant DB) │
          │   - Source code     │   │   - Scans metadata  │
          │   - Artifacts       │   │   - Findings        │
          │   - Results         │   │   - Users/Projects  │
          └─────────────────────┘   │   - Artifacts meta  │
                                    └─────────────────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │   Redis (Optional)  │
                                    │   - Caching         │
                                    │   - Job queue       │
                                    │   - Rate limiting   │
                                    └─────────────────────┘

**Key Flow:**
1. UI → API Gateway → Storage Service: CreateArtifact() → presigned upload URL
2. UI → S3: Upload source code directly using presigned URL
3. UI → API Gateway → Orchestrator: CreateScan(artifact_id)
4. Orchestrator → Storage Service: GetArtifact(artifact_id) → presigned download URL
5. Orchestrator → K8s: Create Job with SOURCE_DOWNLOAD_URL env var
6. Runner → S3: Download source using presigned URL (direct, no service call)
7. Runner: Execute scanners in parallel (Semgrep, Trivy, TruffleHog, ScanCode)
8. Runner → Orchestrator: CreateFindings() and UpdateScan() via gRPC
9. WebSocket Service → K8s API: Stream pod logs to UI in real-time
```

---

## 📦 **Services Breakdown**

### **1. cloudscan-ui (Frontend)**
**Technology:** React + TypeScript + Vite + TailwindCSS

**Features:**
- User authentication (login/signup)
- Organization & project management
- Scan creation wizard with step-by-step forms
- Real-time scan progress with live logs (WebSocket)
- Findings dashboard with filtering/sorting
- Vulnerability details with remediation suggestions
- Artifact download interface
- User management and RBAC
- Dark/light theme
- Mobile responsive

**Pages:**
```
/login
/signup
/dashboard                    # Overview of all scans
/organizations                # Manage orgs
/projects                     # Manage projects
/projects/:id/scans           # Scan history
/scans/new                    # Create new scan wizard
/scans/:id                    # Scan details
  ├─ /overview                # Summary
  ├─ /findings                # List of issues
  ├─ /logs                    # Live logs
  ├─ /artifacts               # Download links
  └─ /comparison              # Compare with previous
/settings                     # User settings
/admin                        # Admin panel
```

### **2. cloudscan-api-gateway (API Gateway)**
**Technology:** Go + Echo Framework

**Responsibilities:**
- Route HTTP requests to appropriate services
- JWT authentication & authorization
- Rate limiting
- Request validation
- API versioning
- OpenAPI/Swagger documentation

**Endpoints:**
```
POST   /api/v1/auth/login
POST   /api/v1/auth/signup
GET    /api/v1/organizations
POST   /api/v1/organizations
GET    /api/v1/projects
POST   /api/v1/projects
POST   /api/v1/scans
GET    /api/v1/scans/:id
GET    /api/v1/scans/:id/findings
GET    /api/v1/scans/:id/artifacts
GET    /api/v1/scans/:id/logs
DELETE /api/v1/scans/:id
```

### **3. cloudscan-orchestrator (Core Service)**
**Technology:** Go + gRPC + Kubernetes client-go

**Responsibilities:**
- Scan lifecycle management (create, monitor, cancel)
- Kubernetes job dispatching for scanner runners
- Multi-tenant data isolation
- Job queue management
- Background workers:
  - **Sweeper:** Monitor K8s jobs and update scan status
  - **Cleaner:** Cleanup old scans/artifacts based on retention
  - **Notifier:** Send webhooks/emails on completion
- Health checks and readiness probes

**Database Schema:**
```sql
-- Organizations (multi-tenancy)
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Projects
CREATE TABLE projects (
    id UUID PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL,
    repository_url TEXT,
    default_scan_config JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Scans (partitioned by created_at for performance)
CREATE TABLE scans (
    id UUID PRIMARY KEY,
    organization_id UUID NOT NULL,
    project_id UUID REFERENCES projects(id),
    status TEXT NOT NULL, -- queued, running, completed, failed
    scan_types TEXT[] NOT NULL, -- ['sast', 'sca', 'secrets']
    source_info JSONB NOT NULL, -- {repo, branch, commit}
    runner_metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
) PARTITION BY RANGE (created_at);

CREATE TABLE scans_2025_10 PARTITION OF scans
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- Findings (security vulnerabilities, code issues)
CREATE TABLE findings (
    id UUID PRIMARY KEY,
    scan_id UUID REFERENCES scans(id),
    organization_id UUID NOT NULL,
    type TEXT NOT NULL, -- sast, sca, secret, license
    severity TEXT NOT NULL, -- critical, high, medium, low, info
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT,
    line_number INT,
    cwe_id TEXT,
    cve_id TEXT,
    cvss_score FLOAT,
    remediation TEXT,
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_findings_scan ON findings(scan_id);
CREATE INDEX idx_findings_severity ON findings(severity);
CREATE INDEX idx_findings_type ON findings(type);

-- Artifacts
CREATE TABLE artifacts (
    id UUID PRIMARY KEY,
    scan_id UUID REFERENCES scans(id),
    name TEXT NOT NULL,
    storage_key TEXT NOT NULL,
    size_bytes BIGINT,
    content_type TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User Organization Membership
CREATE TABLE user_organizations (
    user_id UUID REFERENCES users(id),
    organization_id UUID REFERENCES organizations(id),
    role TEXT NOT NULL, -- admin, member, viewer
    PRIMARY KEY (user_id, organization_id)
);
```

### **4. cloudscan-storage (Storage Service)**
**Technology:** Go + S3/GCS/Azure SDK

**Responsibilities:**
- Abstract storage backend (S3, GCS, Azure Blob, MinIO)
- Generate presigned URLs for upload/download
- Support multipart uploads for large files
- Artifact metadata management
- Automatic cleanup of expired artifacts

### **5. cloudscan-websocket (Real-time Service)**
**Technology:** Go + Gorilla WebSocket

**Responsibilities:**
- Stream live scan logs to UI
- Broadcast scan status updates
- Handle multiple concurrent connections
- Authentication via JWT tokens
- Connection pooling and cleanup

### **6. cloudscan-scanner-runners (Scanner Executors)**
**Technology:** Go + Various scanner CLIs

**Types of Runners:**

#### **A. SAST Runner** (Static Application Security Testing)
Runs static analysis tools:

**⭐ Recommended Primary Tool: Semgrep**
- **License:** LGPL 2.1 (open-source)
- **Why:** Fast, supports 30+ languages, extensive rule library, low false positives
- **Coverage:** SQL injection, XSS, command injection, insecure crypto, hardcoded secrets, etc.
- **Community:** 10k+ GitHub stars, actively maintained by Semgrep (r2c)
- **Performance:** ~2-5 minutes for 1000-file repo
- **CLI:** `semgrep --config=auto --sarif-output results.sarif`

**Alternative/Complementary Tools:**
- **CodeQL** (GitHub's code analysis)
  - License: MIT for CLI, proprietary for queries
  - Best for: Deep semantic analysis, complex data flow
  - Slower but very thorough (10-30 min for large repos)

- **Bandit** (Python security)
  - License: Apache 2.0
  - Best for: Python-specific security issues (CWE checks)
  - Fast, minimal configuration

- **Brakeman** (Ruby/Rails security)
  - License: MIT
  - Best for: Ruby on Rails applications
  - Detects Rails-specific vulnerabilities (mass assignment, CSRF, etc.)

- **gosec** (Go security)
  - License: Apache 2.0
  - Best for: Go applications
  - Analyzes Go AST for security issues

- **ESLint** with security plugins
  - License: MIT
  - Best for: JavaScript/TypeScript
  - Use with `eslint-plugin-security`

**💡 Our Recommendation:**
- **Start with Semgrep** as the universal SAST engine (covers 90% of use cases)
- Add language-specific tools for deeper analysis:
  - **Bandit** for Python projects
  - **gosec** for Go projects
  - **Brakeman** for Rails projects
- **MVP Stack:** Semgrep only
- **Advanced Stack:** Semgrep + 2-3 language-specific scanners

---

#### **B. SCA Runner** (Software Composition Analysis)
Runs dependency vulnerability analysis:

**⭐ Recommended Primary Tool: Trivy**
- **License:** Apache 2.0 (fully open-source)
- **Why:** Fast, comprehensive database (170k+ vulnerabilities), supports 15+ package managers
- **Coverage:** CVE detection, license scanning, config scanning, SBOM generation
- **Community:** 23k+ GitHub stars, backed by Aqua Security
- **Performance:** ~30-60 seconds for typical projects
- **Features:**
  - Offline scanning capability
  - Low memory footprint (~100MB image)
  - Supports: npm, pip, maven, go.mod, Cargo.toml, composer, Gemfile, etc.
  - Can scan filesystems, containers, and Git repos
  - SBOM formats: CycloneDX, SPDX
- **CLI:** `trivy fs --format sarif --output results.sarif .`

**Alternative/Complementary Tools:**
- **OWASP Dependency-Check**
  - License: Apache 2.0
  - Best for: Java/Maven projects, .NET
  - Comprehensive NVD database
  - Slower (5-10 minutes), higher memory usage

- **Grype** (by Anchore)
  - License: Apache 2.0
  - Best for: Container images, similar to Trivy
  - Alternative with comparable features

- **OSS Index** (Sonatype)
  - License: Free API (rate-limited)
  - Best for: Quick online lookups
  - Requires internet connection

- **Snyk CLI** (open-source mode)
  - License: Apache 2.0 (CLI), requires account for full features
  - Best for: Developer-friendly output, fix suggestions
  - Cloud-based, good IDE integration

**💡 Our Recommendation:**
- **Use Trivy exclusively** (simplest, most comprehensive, fastest)
- Optional: Add OWASP Dependency-Check for JVM/Maven-heavy orgs
- **MVP Stack:** Trivy only
- **Why Trivy wins:**
  - Single binary, zero dependencies
  - Supports all major ecosystems out of the box
  - Actively updated (weekly CVE database updates)
  - Can work offline (downloads DB once)

---

#### **C. Secrets Scanner**
Detects secrets/credentials in code:

**⭐ Recommended Primary Tool: TruffleHog**
- **License:** AGPL 3.0 (open-source)
- **Why:** Most comprehensive (700+ credential patterns), entropy-based detection
- **Coverage:** API keys, passwords, OAuth tokens, private keys, cloud credentials (AWS/GCP/Azure)
- **Community:** 15k+ GitHub stars, backed by Truffle Security
- **Performance:** ~1-2 minutes for typical repos
- **Features:**
  - 700+ regex patterns for known secret formats
  - Shannon entropy analysis for high-randomness strings (catches unknown/custom secrets)
  - Git history scanning (finds secrets in old commits, not just current files)
  - Secret verification (can test if AWS keys are still active) - optional
  - JSON output for easy parsing
- **CLI:** `trufflehog filesystem . --json --no-verification > results.json`

**Alternative/Complementary Tools:**
- **GitLeaks**
  - License: MIT
  - Best for: Fast Git repository scanning
  - ~100 built-in rules
  - Faster than TruffleHog but smaller pattern database

- **detect-secrets** (by Yelp)
  - License: Apache 2.0
  - Best for: Pre-commit hooks, baseline management
  - Low false positives, allowlist support
  - Good for ongoing secret prevention

- **git-secrets** (by AWS)
  - License: Apache 2.0
  - Best for: AWS-specific credentials only
  - Simpler, focused scope

**💡 Our Recommendation:**
- **Use TruffleHog** as primary scanner (most comprehensive)
- Run with `--no-verification` flag to avoid external API calls
- Optional: Add GitLeaks for faster scans on very large repos (100k+ files)
- **MVP Stack:** TruffleHog only
- **Why TruffleHog wins:**
  - 7x more patterns than competitors (700 vs ~100)
  - Entropy detection catches secrets without known patterns
  - Can scan Git history to find leaked secrets in old commits
  - Active development (weekly pattern updates)

---

#### **D. License Scanner**
Checks open-source license compliance:

**⭐ Recommended Primary Tool: ScanCode Toolkit**
- **License:** Apache 2.0 (fully open-source)
- **Why:** Most comprehensive (3000+ license database), detects licenses in source files
- **Coverage:** License detection, copyright detection, package manifests, SPDX output
- **Community:** 4k+ GitHub stars, backed by AboutCode community
- **Performance:** ~3-5 minutes for 1000-file repo
- **Features:**
  - Detects licenses in actual source code headers (not just package.json)
  - Copyright holder detection
  - License conflict identification
  - SPDX and CycloneDX SBOM generation
  - High accuracy license text matching (handles variants)
- **CLI:** `scancode --license --copyright --json-pp results.json .`

**Alternative/Complementary Tools:**
- **LicenseFinder**
  - License: MIT
  - Best for: Package manager integration (fast manifest-based scanning)
  - Decision/approval workflow for legal teams
  - Faster but less comprehensive (only checks manifests)

- **FOSSA CLI** (open-source mode)
  - License: MPL 2.0
  - Best for: Modern language ecosystems
  - Fast, good developer UX
  - Optional cloud service for centralized tracking

- **FOSSology**
  - License: GPL 2.0
  - Best for: Enterprise compliance teams
  - Full web UI, database backend, workflow management
  - Heavyweight solution (requires separate deployment)

**💡 Our Recommendation:**
- **Use ScanCode Toolkit** for comprehensive source-level license detection
- Optional: Add LicenseFinder for faster manifest-only scans
- **MVP Stack:** ScanCode Toolkit only
- **Why ScanCode wins:**
  - Detects licenses in source file headers (not just package.json/pom.xml)
  - Handles multi-license scenarios
  - No external dependencies or API calls
  - Generates legal-grade SBOM documents
  - Most accurate license text matching

---

### **🎯 Final Recommended Tool Stack for CloudScan**

**Minimal Production-Ready Stack (MVP):**

| Scan Type | Tool | Performance | Image Size | Why This One? |
|-----------|------|-------------|------------|---------------|
| **SAST** | Semgrep | 2-5 min | ~400MB | Multi-language, extensive rules, low false positives |
| **SCA** | Trivy | 30-60 sec | ~100MB | Fast, 15+ package managers, offline-capable |
| **Secrets** | TruffleHog | 1-2 min | ~50MB | 700+ patterns, entropy detection |
| **License** | ScanCode | 3-5 min | ~200MB | Most comprehensive, source-level detection |

**Total Docker Image:** ~750MB (reasonable size)
**Total Scan Time:** ~7-13 minutes for average project (can run in parallel)

---

### **📦 Docker Image Strategy**

**Option 1: Unified Scanner Image (Recommended for MVP)**
```dockerfile
FROM ubuntu:22.04

# Install all scanners
RUN apt-get update && apt-get install -y python3 pip
RUN pip install semgrep trufflehog scancode-toolkit
RUN wget https://github.com/aquasecurity/trivy/releases/download/v0.50.0/trivy_0.50.0_Linux-64bit.tar.gz \
    && tar -xzf trivy_0.50.0_Linux-64bit.tar.gz \
    && mv trivy /usr/local/bin/

# Copy runner binary
COPY runner /usr/local/bin/runner

CMD ["/usr/local/bin/runner"]
```

**Option 2: Separate Images per Scanner (Advanced/Phase 2)**
- `cloudscan/sast-runner:latest` (Semgrep only)
- `cloudscan/sca-runner:latest` (Trivy only)
- `cloudscan/secrets-runner:latest` (TruffleHog only)
- `cloudscan/license-runner:latest` (ScanCode only)

**Pros of Unified Image:**
- Simpler deployment (one image to manage)
- Can run multiple scan types in single pod
- Faster for small/medium repos

**Pros of Separate Images:**
- Smaller individual images
- Better for large-scale (parallel pods per scan type)
- Easier to update individual scanners

**💡 Recommendation:** Start with unified image, split later if needed

---

### **⚡ Performance Optimization Tips**

**Parallel Execution:**
```go
// Run all 4 scanners in parallel using goroutines
var wg sync.WaitGroup
wg.Add(4)

go func() { defer wg.Done(); runSemgrep() }()
go func() { defer wg.Done(); runTrivy() }()
go func() { defer wg.Done(); runTruffleHog() }()
go func() { defer wg.Done(); runScanCode() }()

wg.Wait()
```

**With parallel execution:** ~5 minutes total (vs 13 minutes sequential)

**Caching:**
- Cache Trivy vulnerability database (updates weekly)
- Cache Semgrep rule database
- Reuse git clones for multiple scan types

**Resource Requests (Kubernetes):**
```yaml
resources:
  requests:
    cpu: "2"
    memory: "4Gi"
  limits:
    cpu: "4"
    memory: "8Gi"
```

---

### **🔄 Advanced/Future Scanner Additions**

**Phase 2 - Language-Specific SAST:**
- **Bandit** (Python) - Add when scanning Python projects
- **gosec** (Go) - Add when scanning Go projects
- **Brakeman** (Ruby/Rails) - Add when scanning Rails apps
- **ESLint + security plugins** (JavaScript/TypeScript)

**Phase 3 - Specialized Scanners:**
- **Container Image Scanning:** Trivy/Grype (already have Trivy!)
- **IaC Scanning:** Checkov, tfsec (Terraform/CloudFormation security)
- **API Security:** 42Crunch, Spectral (OpenAPI/Swagger analysis)
- **Malware Scanning:** ClamAV (detect malicious code)

**Phase 4 - AI/ML-Based:**
- **DeepCode/Snyk Code** (ML-powered SAST)
- **GitHub Copilot for Security** (AI-assisted remediation)

---

### **📊 Comparison: CloudScan vs Commercial Tools**

| Feature | CloudScan (Our Stack) | SonarQube Enterprise | Snyk Enterprise | Checkmarx |
|---------|----------------------|---------------------|----------------|-----------|
| **SAST** | Semgrep (10k rules) | 5k+ rules | Limited | 50k+ rules |
| **SCA** | Trivy (170k CVEs) | Limited | 900k+ vulns | Good |
| **Secrets** | TruffleHog (700 patterns) | Basic | Good | Basic |
| **License** | ScanCode (3k licenses) | Good | Excellent | Good |
| **Speed** | 5-7 min (parallel) | 10-20 min | 3-5 min | 20-60 min |
| **Cost** | **FREE** | $150k+/year | $50k+/year | $100k+/year |
| **Deployment** | Self-hosted K8s | Self-hosted/SaaS | SaaS | On-prem |
| **Customization** | Full control | Limited | None | Moderate |

**CloudScan covers 80% of commercial tool capabilities at 0% of the cost!**

**Runner Flow:**
```go
1. Receive job via K8s Job spec (env vars from orchestrator)
2. Read SOURCE_DOWNLOAD_URL from environment variable
3. Download source code directly from S3 using presigned URL
4. Extract source code to /workspace
5. Run appropriate scanner(s) in parallel (Semgrep, Trivy, etc.)
6. Parse scanner output to standard format (SARIF)
7. Call orchestrator.CreateFindings() via gRPC to save findings
8. Call orchestrator.UpdateScan() to mark completed/failed
9. Exit (K8s cleans up pod)

Note: Runner only communicates with Orchestrator (gRPC) and S3 (presigned URLs).
It does NOT call storage-service directly.
```

---

## 🔄 **Complete User Workflow**

### **Phase 1: Initial Setup (One-time)**

#### **Step 1: Admin Installs CloudScan via Helm**
```bash
# Admin on their Kubernetes cluster
helm repo add cloudscan https://charts.cloudscan.dev
helm repo update

# Install with custom values
helm install cloudscan cloudscan/cloudscan \
  --namespace cloudscan \
  --create-namespace \
  --set postgresql.enabled=true \
  --set storage.type=s3 \
  --set storage.s3.bucket=my-scans-bucket \
  --set storage.s3.region=us-west-2 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=cloudscan.mycompany.com \
  --set ingress.tls.enabled=true
```

**Helm installs:**
- PostgreSQL (or connects to external)
- Redis (optional)
- All CloudScan services (orchestrator, storage, websocket, ui, gateway)
- NGINX Ingress
- Service accounts and RBAC for K8s job creation

#### **Step 2: Access Web UI**
User navigates to: `https://cloudscan.mycompany.com`

---

### **Phase 2: User Registration & Setup**

#### **Step 1: User Signup**
**UI Screen:** `/signup`

**User provides:**
```
Full Name: John Doe
Email: john@acme.com
Password: ••••••••••
Company: Acme Corporation
```

**Backend:**
```go
POST /api/v1/auth/signup
{
  "name": "John Doe",
  "email": "john@acme.com",
  "password": "SecurePass123!",
  "organization_name": "Acme Corporation"
}

Response:
{
  "user_id": "usr-550e8400",
  "organization_id": "org-7c9e6679",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**What happens:**
1. Password hashed with bcrypt
2. User created in `users` table
3. Organization created in `organizations` table
4. User linked to org in `user_organizations` as "admin"
5. JWT token generated and returned
6. Email verification sent (optional)

#### **Step 2: User Login**
**UI Screen:** `/login`

**User provides:**
```
Email: john@acme.com
Password: ••••••••••
```

**Backend:**
```go
POST /api/v1/auth/login
{
  "email": "john@acme.com",
  "password": "SecurePass123!"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "usr-550e8400",
    "name": "John Doe",
    "email": "john@acme.com"
  },
  "organization": {
    "id": "org-7c9e6679",
    "name": "Acme Corporation",
    "role": "admin"
  }
}
```

**UI stores JWT in:**
- localStorage (or httpOnly cookie for better security)
- Includes in all subsequent API calls as `Authorization: Bearer <token>`

---

### **Phase 3: Project Creation**

#### **Step 1: Create Project**
**UI Screen:** `/projects/new`

**User fills out form:**
```
Project Name: Payment Service
Description: Core payment processing microservice
Repository URL: https://github.com/acme/payment-service
Default Branch: main
Scan Configuration:
  ☑ SAST (Static Application Security Testing)
  ☑ SCA (Software Composition Analysis)
  ☑ Secret Detection
  ☑ License Compliance
Resource Limits:
  CPU: 4 cores
  Memory: 8Gi
  Timeout: 30 minutes
```

**On Submit, UI calls:**
```javascript
POST /api/v1/projects
{
  "name": "Payment Service",
  "description": "Core payment processing microservice",
  "repository_url": "https://github.com/acme/payment-service",
  "default_branch": "main",
  "scan_config": {
    "scan_types": ["sast", "sca", "secrets", "license"],
    "resource_limits": {
      "cpu": "4",
      "memory": "8Gi",
      "timeout_minutes": 30
    }
  }
}

Response:
{
  "project_id": "proj-9f8e7d6c",
  "name": "Payment Service",
  "organization_id": "org-7c9e6679",
  "created_at": "2025-10-08T10:00:00Z",
  "webhook_url": "https://cloudscan.mycompany.com/webhooks/proj-9f8e7d6c"
}
```

**UI shows:**
```
✓ Project created successfully!

Webhook URL (for CI/CD):
https://cloudscan.mycompany.com/webhooks/proj-9f8e7d6c

Secret: whsec_abc123def456...
```

---

### **Phase 4: Creating a Scan**

#### **Step 1: Start New Scan**
**UI Screen:** `/scans/new`

**User fills multi-step wizard:**

**Wizard Step 1/4: Select Project**
```
Select Project: Payment Service ▼
```

**Wizard Step 2/4: Source Configuration**
```
Source Type: Git Repository ⚪

Repository: https://github.com/acme/payment-service
Branch: main ▼
Or enter commit SHA: [optional: abc123def]

Credentials (if private repo):
  ⚪ Use project default
  ⚪ Custom credentials
     Username: ___________
     Token/Password: ___________
```

**Wizard Step 3/4: Scan Types**
```
Select scan types to run:

☑ SAST - Static Application Security Testing
   Find security vulnerabilities in source code
   Tools: Semgrep, CodeQL
   Est. time: 5-10 minutes

☑ SCA - Software Composition Analysis
   Find vulnerabilities in dependencies
   Tools: OWASP Dependency-Check, Trivy
   Est. time: 3-5 minutes

☑ Secret Detection
   Find leaked credentials and API keys
   Tools: TruffleHog, GitLeaks
   Est. time: 1-2 minutes

☑ License Compliance
   Check open-source license compatibility
   Tools: LicenseFinder
   Est. time: 2-3 minutes

Total estimated time: 11-20 minutes
```

**Wizard Step 4/4: Notifications & Options**
```
Notifications:
  ☑ Email on completion: john@acme.com
  ☐ Slack webhook: _______________
  ☐ Custom webhook: _______________

Advanced Options:
  Priority: Normal ▼ (Low, Normal, High)
  Fail on: Critical ▼ (Critical, High, Medium, Low, Never)
  Compare with: [Previous scan ▼]
```

**User clicks "Start Scan"**

**Step 1: UI fetches/clones source code locally**
```javascript
// UI clones git repository in browser using git libraries
// or user uploads source code as ZIP
const sourceArchive = await prepareSourceCode({
  repository: "https://github.com/acme/payment-service",
  branch: "main",
  commit: "abc123def"
});
```

**Step 2: UI uploads source to Storage Service**
```javascript
// Create artifact and get presigned upload URL
POST /storage/v1/artifacts
{
  "scan_id": "",  // Empty for now, will be set later
  "organization_id": "org-7c9e6679",
  "type": "source",
  "filename": "payment-service-main-abc123.zip",
  "content_type": "application/zip",
  "size_bytes": 12458352
}

Response:
{
  "artifact_id": "art-1a2b3c4d-5678-90ef-ghij-klmnopqrstuv",
  "upload_url": "https://s3.amazonaws.com/cloudscan-storage/art-1a2b.../...",
  "expires_at": "2025-10-08T11:15:30Z"
}

// Upload source archive directly to S3 using presigned URL
PUT https://s3.amazonaws.com/cloudscan-storage/art-1a2b.../...
Content-Type: application/zip
Body: <binary source archive>
```

**Step 3: UI creates scan with artifact_id**
```javascript
POST /api/v1/scans
{
  "project_id": "proj-9f8e7d6c",
  "source_artifact_id": "art-1a2b3c4d-5678-90ef-ghij-klmnopqrstuv",
  "git_url": "https://github.com/acme/payment-service",
  "git_branch": "main",
  "git_commit": "abc123def",
  "scan_types": ["sast", "sca", "secrets", "license"],
  "priority": "normal",
  "fail_threshold": "critical",
  "notifications": {
    "email": ["john@acme.com"]
  }
}

Response:
{
  "scan_id": "scan-890a1234-5678-9012-3456-7890abcdef12",
  "status": "queued",
  "queue_position": 2,
  "estimated_start_time": "2025-10-08T10:15:30Z",
  "dashboard_url": "/scans/scan-890a1234-5678-9012-3456-7890abcdef12"
}
```

**Behind the scenes:**
1. Orchestrator receives CreateScan request with artifact_id
2. Orchestrator calls Storage.GetArtifact(artifact_id) → gets presigned download URL
3. Orchestrator creates K8s Job with SOURCE_DOWNLOAD_URL env var
4. Runner downloads source from S3 using presigned URL
5. Runner executes scanners and sends results back to Orchestrator

**UI redirects to:** `/scans/scan-890a1234-5678-9012-3456-7890abcdef12`

---

### **Phase 5: Watching Scan Progress (Real-time)**

#### **Scan Dashboard UI**

**Top Section - Status Card:**
```
┌─────────────────────────────────────────────────────────────┐
│ Scan #1234                                         ⚙️ RUNNING │
│ Payment Service - main branch                               │
│                                                              │
│ Started: 2 minutes ago                                      │
│ Progress: ████████████░░░░░░░░ 60% (3/5 steps completed)   │
│                                                              │
│ Current Step: Running SAST analysis (Semgrep)               │
│ Estimated time remaining: 3 minutes                         │
│                                                              │
│ Actions: [Cancel Scan] [Download Config] [Share]           │
└─────────────────────────────────────────────────────────────┘
```

**Middle Section - Step Progress:**
```
┌─────────────────────────────────────────────────────────────┐
│ Scan Steps                                                   │
├─────────────────────────────────────────────────────────────┤
│ ✓ 1. Fetch Source Code          (completed in 15s)         │
│ ✓ 2. Secret Detection            (completed in 45s)         │
│   └─ Found 2 potential secrets                              │
│ ✓ 3. License Compliance          (completed in 1m 20s)     │
│   └─ Analyzed 142 dependencies                              │
│ ⚙️ 4. SAST Analysis               (running for 2m 10s)      │
│   └─ Semgrep: Scanning 347 files...                        │
│ ⏸ 5. SCA Analysis                 (pending)                  │
└─────────────────────────────────────────────────────────────┘
```

**Bottom Section - Live Logs (WebSocket stream):**
```
┌─────────────────────────────────────────────────────────────┐
│ Live Logs                                    [⬇️ Download]   │
├─────────────────────────────────────────────────────────────┤
│ [10:15:32] Starting scan for Payment Service                │
│ [10:15:33] Cloning repository from GitHub...                │
│ [10:15:35] ✓ Cloned 1,247 files (branch: main, commit: abc) │
│ [10:15:36] Running secret detection with TruffleHog...      │
│ [10:15:45] ⚠️  Found potential AWS access key in config.yml │
│ [10:15:46] ⚠️  Found potential JWT secret in .env.example   │
│ [10:15:47] ✓ Secret scan complete (2 findings)              │
│ [10:15:48] Running license compliance check...              │
│ [10:16:05] Analyzing package.json dependencies...           │
│ [10:16:18] Analyzing requirements.txt dependencies...       │
│ [10:17:08] ✓ License scan complete (142 deps analyzed)     │
│ [10:17:09] Running SAST with Semgrep...                     │
│ [10:17:12] Scanning JavaScript files... (187 files)         │
│ [10:17:45] Scanning Python files... (94 files)              │
│ [10:18:22] Scanning YAML files... (23 files)                │
│ [10:19:15] ⚠️  SQL injection vulnerability in auth.js:45    │
│ [10:19:16] ⚠️  XSS vulnerability in payment.js:102          │
│ [10:19:20] ✓ SAST scan complete (23 findings)              │
│ [10:19:21] Running SCA with OWASP Dependency-Check...       │
│ [10:19:35] Checking dependencies against NVD database...    │
│ [10:20:10] 🔴 Found CVE-2024-1234 in express@4.17.1         │
│ [10:20:11] 🔴 Found CVE-2024-5678 in lodash@4.17.19         │
│ [10:21:02] ✓ SCA scan complete (12 vulnerabilities)        │
│ [10:21:03] Uploading scan results...                        │
│ [10:21:08] ✓ All results uploaded successfully             │
│ [10:21:09] ✅ Scan completed in 5m 37s                      │
│                                                              │
│ ▌ Real-time updates...                                      │
└─────────────────────────────────────────────────────────────┘
```

**WebSocket Connection (behind the scenes):**
```javascript
// UI establishes WebSocket connection
const ws = new WebSocket(
  `wss://cloudscan.mycompany.com/ws/scans/scan-890a1234?token=${jwt}`
);

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);

  if (data.type === 'log') {
    appendLog(data.message); // Add to log viewer
  } else if (data.type === 'status') {
    updateStatus(data.status); // Update progress bar
  } else if (data.type === 'step_complete') {
    markStepComplete(data.step); // Update step list
  }
};
```

---

### **Phase 6: Scan Completion & Results**

#### **Status Changes to "Completed"**

**UI automatically updates to show:**

**Results Summary Card:**
```
┌─────────────────────────────────────────────────────────────┐
│ Scan #1234                                    ✅ COMPLETED   │
│ Payment Service - main branch (commit: abc123d)             │
│                                                              │
│ Completed: Just now (took 5m 37s)                          │
│                                                              │
│ ╔═══════════════════════════════════════════════════════╗   │
│ ║  Total Findings: 39                                   ║   │
│ ║                                                       ║   │
│ ║  🔴 Critical:  2                                      ║   │
│ ║  🟠 High:      8                                      ║   │
│ ║  🟡 Medium:    15                                     ║   │
│ ║  🔵 Low:       12                                     ║   │
│ ║  ⚪ Info:      2                                      ║   │
│ ╚═══════════════════════════════════════════════════════╝   │
│                                                              │
│ Scan Result: ❌ FAILED (2 critical issues found)            │
│                                                              │
│ Actions: [View Findings] [Download Report] [Compare]       │
└─────────────────────────────────────────────────────────────┘
```

**Findings by Type:**
```
┌─────────────────────────────────────────────────────────────┐
│ Findings Breakdown                                           │
├─────────────────────────────────────────────────────────────┤
│ SAST (Static Analysis):        23 findings                  │
│ ├─ 🔴 Critical: 1  🟠 High: 5  🟡 Medium: 10  🔵 Low: 7     │
│                                                              │
│ SCA (Dependencies):            12 vulnerabilities            │
│ ├─ 🔴 Critical: 1  🟠 High: 2  🟡 Medium: 5  🔵 Low: 4      │
│                                                              │
│ Secrets:                       2 potential leaks             │
│ ├─ 🟠 High: 2                                               │
│                                                              │
│ License Compliance:            2 issues                      │
│ ├─ 🟡 Medium: 2                                             │
└─────────────────────────────────────────────────────────────┘
```

**User clicks "View Findings"**

---

### **Phase 7: Findings Dashboard**

**UI Screen:** `/scans/scan-890a1234/findings`

**Filters:**
```
Severity: [All ▼] [Critical] [High] [Medium] [Low] [Info]
Type: [All ▼] [SAST] [SCA] [Secrets] [License]
Status: [All ▼] [New] [Fixed] [Ignored]
Search: [🔍 Search by keyword, file, or CVE...]
```

**Findings Table:**
```
┌────┬──────────┬────────┬────────────────────────────────────────────┬─────────────────┐
│ ID │ Severity │ Type   │ Title                                      │ Location        │
├────┼──────────┼────────┼────────────────────────────────────────────┼─────────────────┤
│ 1  │ 🔴 CRIT  │ SCA    │ CVE-2024-1234 in express@4.17.1           │ package.json:12 │
│    │          │        │ Remote Code Execution vulnerability        │                 │
│    │          │        │ CVSS: 9.8 | CWE-94                        │                 │
├────┼──────────┼────────┼────────────────────────────────────────────┼─────────────────┤
│ 2  │ 🔴 CRIT  │ SAST   │ SQL Injection vulnerability                │ auth.js:45      │
│    │          │        │ User input directly in SQL query           │                 │
│    │          │        │ CWE-89                                     │                 │
├────┼──────────┼────────┼────────────────────────────────────────────┼─────────────────┤
│ 3  │ 🟠 HIGH  │ Secret │ AWS Access Key detected                    │ config.yml:23   │
│    │          │        │ Potential leaked credentials               │                 │
├────┼──────────┼────────┼────────────────────────────────────────────┼─────────────────┤
│ 4  │ 🟠 HIGH  │ SAST   │ Cross-Site Scripting (XSS)                │ payment.js:102  │
│    │          │        │ Unescaped user input in HTML              │                 │
│    │          │        │ CWE-79                                     │                 │
└────┴──────────┴────────┴────────────────────────────────────────────┴─────────────────┘

Showing 4 of 39 findings | [Load More]
```

**User clicks on Finding #2 (SQL Injection)**

---

### **Phase 8: Finding Details**

**Modal/Drawer opens showing:**

```
┌─────────────────────────────────────────────────────────────┐
│ Finding Details                                      [✕]     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ 🔴 CRITICAL - SQL Injection Vulnerability                   │
│                                                              │
│ Location: src/auth.js:45                                    │
│ Detected by: Semgrep (SAST)                                 │
│ CWE-89: Improper Neutralization of Special Elements         │
│         used in an SQL Command ('SQL Injection')            │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Description:                                                 │
│ User-controlled input is directly concatenated into an SQL  │
│ query without proper sanitization or parameterization.      │
│ This allows attackers to inject malicious SQL commands.     │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Vulnerable Code:                                             │
│                                                              │
│  43 │ function loginUser(username, password) {              │
│  44 │   const query = "SELECT * FROM users WHERE " +        │
│> 45 │     "username = '" + username + "' AND " +            │
│  46 │     "password = '" + password + "'";                  │
│  47 │   return db.execute(query);                           │
│  48 │ }                                                      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Remediation:                                                 │
│                                                              │
│ Use parameterized queries or prepared statements:           │
│                                                              │
│  function loginUser(username, password) {                   │
│    const query = "SELECT * FROM users WHERE " +             │
│      "username = ? AND password = ?";                       │
│    return db.execute(query, [username, password]);          │
│  }                                                           │
│                                                              │
│ Or use an ORM:                                              │
│                                                              │
│  const user = await User.findOne({                          │
│    where: { username, password }                            │
│  });                                                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ References:                                                  │
│ • OWASP: https://owasp.org/www-community/attacks/SQL_Inj... │
│ • CWE-89: https://cwe.mitre.org/data/definitions/89.html   │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Actions:                                                     │
│ [Create Jira Ticket] [Mark as False Positive] [Ignore]     │
└─────────────────────────────────────────────────────────────┘
```

---

### **Phase 9: Artifacts & Downloads**

**UI Screen:** `/scans/scan-890a1234/artifacts`

**User sees list of downloadable artifacts:**

```
┌─────────────────────────────────────────────────────────────┐
│ Scan Artifacts                                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 📄 scan-report.pdf                            2.3 MB │   │
│ │ Comprehensive PDF report with all findings            │   │
│ │ [Download]                                            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 📊 findings.json                              456 KB │   │
│ │ Machine-readable JSON with all vulnerabilities        │   │
│ │ [Download]                                            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 📋 findings.sarif                             523 KB │   │
│ │ SARIF format (Static Analysis Results)                │   │
│ │ [Download]                                            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 📝 scan-logs.txt                              1.1 MB │   │
│ │ Complete execution logs                               │   │
│ │ [Download]                                            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 📈 coverage-report.html                       3.4 MB │   │
│ │ Code coverage report (if tests were run)              │   │
│ │ [Download]                                            │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**User clicks "Download" on scan-report.pdf**

**UI calls:**
```javascript
GET /api/v1/scans/scan-890a1234/artifacts/art-1a2b3c4d/download

Response:
{
  "artifact_id": "art-1a2b3c4d",
  "download_url": "https://s3.amazonaws.com/cloudscan-storage/...",
  "expires_at": "2025-10-08T11:21:09Z"
}
```

**UI redirects browser to presigned URL, file downloads automatically**

---

### **Phase 10: Email Notification**

**User receives email:**

```
From: CloudScan <noreply@cloudscan.mycompany.com>
To: john@acme.com
Subject: ❌ Scan #1234 Failed - Payment Service

Hi John,

Your scan has completed with critical issues found.

Scan Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project:        Payment Service
Branch:         main
Commit:         abc123def (feat: add authentication)
Status:         ❌ FAILED
Duration:       5 minutes 37 seconds
Completed:      Oct 8, 2025 at 10:21 AM

Findings Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 Critical:     2 findings
🟠 High:         8 findings
🟡 Medium:      15 findings
🔵 Low:         12 findings
⚪ Info:         2 findings

Total:          39 findings

Top Issues:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 🔴 CVE-2024-1234 in express@4.17.1 (package.json:12)
   Remote Code Execution - CVSS 9.8

2. 🔴 SQL Injection in auth.js:45
   User input in SQL query - CWE-89

3. 🟠 AWS Access Key detected in config.yml:23
   Potential credential leak

View full report:
https://cloudscan.mycompany.com/scans/scan-890a1234

Download artifacts:
https://cloudscan.mycompany.com/scans/scan-890a1234/artifacts

Need help? Contact support@cloudscan.dev

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CloudScan - Open Source Security Platform
```

---

### **Phase 11: Dashboard Analytics**

**UI Screen:** `/dashboard`

**User sees organization-wide view:**

```
┌─────────────────────────────────────────────────────────────┐
│ Acme Corporation - Security Dashboard                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ Overview (Last 30 Days)                                     │
│ ┌──────────────┬──────────────┬──────────────┬───────────┐ │
│ │ Total Scans  │ Avg Duration │ Success Rate │ Findings  │ │
│ │     127      │    6m 42s    │     78.7%    │   1,234   │ │
│ └──────────────┴──────────────┴──────────────┴───────────┘ │
│                                                              │
│ Scan Trend                                                  │
│  15 ┤         ╭─╮                                           │
│  12 ┤      ╭──╯ ╰╮     ╭╮                                   │
│   9 ┤    ╭─╯     ╰─╮ ╭─╯╰╮                                 │
│   6 ┼────╯         ╰─╯   ╰──                               │
│   3 ┤                                                        │
│     └────────────────────────────────────────               │
│       Week 1  Week 2  Week 3  Week 4                        │
│                                                              │
│ Critical Findings Trend                                     │
│  ██████████████████░░░░░░ ↓ 23% reduction                   │
│                                                              │
│ Recent Scans                                                │
│ ┌────────┬─────────────┬────────┬────────┬─────────────┐  │
│ │ #      │ Project     │ Branch │ Status │ Findings    │  │
│ ├────────┼─────────────┼────────┼────────┼─────────────┤  │
│ │ #1234  │ Payment Svc │ main   │ ❌ FAIL│ 2C 8H 15M   │  │
│ │ #1233  │ Web App     │ dev    │ ✅ PASS│ 0C 2H 5M    │  │
│ │ #1232  │ API Gateway │ main   │ ⚙️ RUN │ -           │  │
│ │ #1231  │ Mobile App  │ feat/x │ ✅ PASS│ 0C 1H 3M    │  │
│ └────────┴─────────────┴────────┴────────┴─────────────┘  │
│                                                              │
│ Projects Overview                                           │
│ ┌────────────────┬───────────┬──────────────────────────┐  │
│ │ Payment Svc    │ 23 scans  │ 🔴🔴🟠🟠🟠🟡🟡🟡🟡🟡      │  │
│ │ Web App        │ 45 scans  │ 🟠🟠🟡🟡🟡🟡🔵🔵🔵🔵      │  │
│ │ API Gateway    │ 31 scans  │ 🟡🟡🟡🔵🔵🔵🔵⚪⚪⚪      │  │
│ └────────────────┴───────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎁 **Value Proposition**

### **For Small Teams & Startups:**
- **Free to use** (Apache 2.0 license)
- **No per-user fees** or scan limits
- **Complete feature set** without enterprise upsells
- **Deploy in 5 minutes** via Helm

### **For Enterprises:**
- **Data sovereignty** - everything on your infrastructure
- **Compliance ready** - GDPR, HIPAA, SOC2 compatible
- **Scalable** - handle 1000s of scans/day
- **Customizable** - add your own scanners
- **No vendor lock-in** - export data anytime

### **For Open Source Projects:**
- **Free forever**
- **Public scan results** option for transparency
- **Badge generation** for README files
- **GitHub integration** for PR checks

---

## 📊 **Success Metrics**

**6 Months Post-Launch:**
- 10,000+ Helm installs
- 1,000+ GitHub stars
- 100+ contributors
- Featured in CNCF landscape

**12 Months:**
- 50,000+ installs
- 5,000+ active organizations
- Major enterprise adoptions (Fortune 500)
- Conference talks at KubeCon, Black Hat

---

## 🚀 **Go-to-Market Strategy**

1. **Launch on Product Hunt** - "Free alternative to $100k security scanners"
2. **Submit to CNCF Sandbox** - Gain credibility
3. **Blog series** - "Building a security platform on Kubernetes"
4. **Conference talks** - KubeCon, OWASP AppSec
5. **Integration partnerships** - GitHub, GitLab, Jenkins
6. **Community building** - Discord, monthly office hours
7. **Documentation & tutorials** - Extensive guides

---

## 💰 **Optional Business Model (SaaS + Support)**

While the software is free and open-source, optional revenue streams:

1. **Managed Cloud Hosting** ($29/mo - $299/mo)
   - CloudScan.dev hosted version
   - No infrastructure management

2. **Enterprise Support** ($5,000/year)
   - Priority bug fixes
   - Custom scanner development
   - Architecture consulting

3. **Training & Certification** ($500/person)
   - CloudScan administrator training
   - Security scanning best practices

---

## 📝 **Next Steps**

1. ✅ Review this plan
2. Create GitHub organization: `github.com/cloudscan`
3. Initialize repositories for each service
4. Set up CI/CD pipelines
5. Start with `cloudscan-orchestrator` (core service)
6. Build `cloudscan-ui` (frontend)
7. Create Helm chart
8. Write documentation
9. Launch alpha to selected users
10. Iterate based on feedback
