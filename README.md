# Azure Resume Challenge – Niels Bovré

This repository contains my implementation of the **Azure Resume Challenge**, demonstrating a complete end-to-end solution on Microsoft Azure with a focus on infrastructure, security, and CI/CD best practices.

**Live site:** https://resume.nielsbovre.com  
**API endpoint:** https://resume.nielsbovre.com/api/GetResumeCounter

---

## Architecture Overview

High-level request flow:

User → Azure Front Door →  
- Azure Storage Static Website (frontend)  
- Azure Functions (.NET 8 isolated) → Azure Cosmos DB (backend)

### Azure Components

- **Azure Front Door (Standard/Premium)**
  - Custom domain
  - Managed TLS certificate
  - Path-based routing (`/` and `/api/*`)
- **Azure Storage Static Website**
  - Hosts the resume frontend
- **Azure Functions (.NET 8 Isolated Worker)**
  - Serverless API for visit counter
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

- Azure Function App using .NET 8 isolated worker
- Anonymous HTTP trigger
- Handles resume page visit counter logic

### API Endpoint

GET /api/GetResumeCounter


### Backend CI/CD

On each push to the `main` branch:

1. Restore and build the solution
2. Publish the Function project
3. Deploy using zip deployment
4. Perform a basic smoke test after deployment

---

## Security Considerations

- No secrets stored in the repository
- GitHub Actions authenticates using Azure AD OIDC
- RBAC-based access control for Azure resources
- HTTPS enforced via Azure Front Door
- Managed TLS certificates

---

## Testing and Validation

- Browser-based validation
- Curl-based API testing
- Azure Front Door routing verification
- TLS certificate validation

---

## Lessons Learned

- Azure Front Door routing and custom domain validation
- Managed TLS certificates and DNS validation
- Control plane versus data plane RBAC in Azure
- GitHub Actions OIDC authentication
- Debugging distributed cloud infrastructure

---

## Future Improvements

- Infrastructure as Code using Bicep or Terraform
- Azure Front Door WAF configuration
- Enhanced monitoring and observability

---

## Author

**Niels Bovré**  
https://resume.nielsbovre.com
