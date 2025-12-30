# Azure Resume Challenge – Niels Bovré

This repository contains my implementation of the **Azure Resume Challenge**, demonstrating a complete end-to-end solution on Microsoft Azure with a focus on infrastructure, reliability, and CI/CD best practices.

## Live links

- **Live site:** https://resume.nielsbovre.com
- **API endpoint:** https://resume.nielsbovre.com/api/GetResumeCounter

---

## Architecture Overview

High-level request flow:

```text
User
  ↓
Azure Front Door
  ├─ Azure Storage Static Website (frontend)
  └─ Azure Functions (Python primary, .NET 8 isolated secondary)
         ↓
     Azure Cosmos DB
```

### Azure Components

- **Azure Front Door (Standard/Premium)**
  - Custom domain
  - Managed TLS certificate
  - Path-based routing (`/*` and `/api/*`)
  - Priority-based origin failover for backend APIs
- **Azure Storage Static Website**
  - Hosts the resume frontend
- **Azure Functions**
  - **Primary backend:** Python Function App
  - **Secondary backend (failover):** .NET 8 isolated Function App
  - Anonymous HTTP trigger for public API access
- **Azure Cosmos DB**
  - Stores and increments the resume visit count
- **GitHub Actions**
  - CI/CD pipelines for frontend and backend
- **Azure Active Directory (OIDC)**
  - Secure authentication for GitHub Actions deployments

---

## Frontend

- Static HTML, CSS, and JavaScript
- Hosted on Azure Storage using the static website feature
- Delivered globally through Azure Front Door

### Frontend CI/CD

On each push to the `main` branch:

1. GitHub Actions authenticates to Azure using OIDC
2. Static files are uploaded to the `$web` container
3. Changes are immediately available via Azure Front Door

---

## Backend

The backend is implemented using **Azure Functions** with a focus on reliability and extensibility.

- **Primary implementation:** Python Azure Function
- **Legacy implementation (failover):** .NET 8 isolated Azure Function
- Both backends share the same API contract and Cosmos DB container
- Azure Front Door routes `/api/*` traffic to the Python backend by default and automatically fails over to the legacy backend if the primary becomes unhealthy

### API Endpoint

```text
GET /api/GetResumeCounter
```

### Example Response

Primary (Python):

```json
{
  "count": 123,
  "source": "python"
}
```

During failover (Legacy .NET):

```json
{
  "count": 123,
  "source": "legacy"
}
```

### Health Probe

```text
GET /api/health
```

Returns:

```text
ok
```

---

## Backend CI/CD

On each push to the `main` branch:

1. Restore and build the Azure Function projects
2. Publish the Function apps
3. Deploy using ZIP deployment
4. Perform basic validation after deployment

---

## Security Considerations

- No secrets stored in the repository
- GitHub Actions authenticates using **Azure AD OIDC**
- RBAC-based access control for Azure resources
- HTTPS enforced via Azure Front Door
- Managed TLS certificates
- CORS headers configured for public API access where required

---

## Testing and Validation

- Browser-based validation of the frontend
- Curl-based API testing
- Azure Front Door routing verification for `/api/*`
- Failover validation by disabling the primary backend and confirming automatic routing to the secondary
- Health probe validation via `/api/health`
- TLS certificate validation on the custom domain

---

## Lessons Learned

- Azure Front Door path-based routing and custom domain configuration
- Priority-based origin failover enables zero-downtime backend migration
- Managed TLS certificates simplify secure global delivery
- Differences between control plane vs data plane RBAC
- GitHub Actions OIDC authentication patterns
- Debugging and validating distributed cloud architectures

---

## Future Improvements

- Infrastructure as Code using **Bicep** or **Terraform**
- Azure Front Door **WAF** configuration
- Enhanced monitoring and observability using **Application Insights**
- Managed identity for Cosmos DB access
- Rate limiting on `/api/*` endpoints

---

## Author

- **Niels Bovré**
- https://resume.nielsbovre.com
