# Azure Resume Challenge — Niels Bovré

This repository contains my implementation of the **Azure Resume Challenge**.  
The goal of this project was not only to deploy a static resume, but to build a small, production-style Azure setup that touches networking, backend services, CI/CD, and security.

The result is a globally delivered static site with a serverless backend, automated deployments, and controlled failover between two independent backend implementations.

## Live endpoints

- **Website:** https://resume.nielsbovre.com  
- **API:** https://resume.nielsbovre.com/api/GetResumeCounter

## Architecture overview

### High-level request flow

```
User
  ↓
Azure Front Door
  ├─ Azure Storage Static Website (frontend)
  └─ Azure Functions (backend)
         ↓
     Azure Cosmos DB
```

## Azure components and design choices

### Azure Front Door (Standard/Premium)

- Custom domain with managed TLS certificate
- Path-based routing (`/*` and `/api/*`)
- Priority-based origin failover for backend APIs

**Why Front Door?**  
This setup could have worked without Front Door, but I explicitly wanted HTTPS without managing certificates, a single global endpoint, and the ability to introduce backend failover and WAF later.

---

### Azure Storage Static Website

- Hosts the resume frontend (HTML, CSS, JavaScript)
- Content is deployed to the `$web` container
- Delivered globally via Azure Front Door

---

### Azure Functions (Backend)

The backend is intentionally implemented twice:

- **Primary backend:** Python Azure Function  
- **Secondary backend (failover):** .NET 8 isolated Azure Function  

Both implementations:
- Expose the same HTTP API
- Share the same Cosmos DB container

Azure Front Door routes `/api/*` traffic to the Python backend by default and automatically fails over to the .NET backend if the primary becomes unhealthy.

---

### Azure Cosmos DB

- Stores the resume visit counter
- Backend functions increment and return the counter value

Cosmos DB is intentionally overkill for a simple counter, but it satisfies the challenge requirements and allowed exploration of throughput and consistency behavior.

## API design

### GET /api/GetResumeCounter

Example response (Python backend):

```json
{
  "count": 123,
  "source": "python"
}
```

During failover (legacy .NET backend):

```json
{
  "count": 123,
  "source": "legacy"
}
```

---

### GET /api/health

Used by Azure Front Door for health probing.

Returns:

```
ok
```

## CI/CD setup

### Frontend pipeline

On each push to `main`:

1. GitHub Actions authenticates to Azure using OIDC
2. Static files are uploaded to the Storage `$web` container
3. Changes are immediately available via Azure Front Door

---

### Backend pipeline

On each push to `main`:

1. Restore and build the Azure Function projects
2. Publish the Function apps
3. Deploy using ZIP deployment
4. Perform basic post-deployment validation

## Security considerations

- No secrets stored in the repository
- GitHub Actions authenticates using Azure AD / Entra ID OIDC
- RBAC-based access control for deployment identities
- HTTPS enforced via Azure Front Door
- Managed TLS certificates
- Explicit CORS configuration where required

## Testing and validation

- Browser-based frontend validation
- `curl`-based API testing
- Front Door routing verification for `/api/*`
- Failover testing by disabling the primary backend
- Health probe validation via `/api/health`
- TLS certificate validation on the custom domain

## Lessons learned

- Azure Front Door path-based routing and custom domain configuration
- Priority-based origin failover enables zero-downtime backend changes
- Managed TLS certificates simplify secure global delivery
- Control plane vs data plane RBAC differences
- GitHub Actions OIDC authentication patterns
- Debugging distributed Azure architectures

## Future improvements

- Infrastructure as Code (Bicep or Terraform)
- Azure Front Door WAF configuration
- Improved monitoring using Application Insights
- Managed identity for Cosmos DB access
- Rate limiting on `/api/*` endpoints

## Author

**Niels Bovré**  
https://resume.nielsbovre.com
