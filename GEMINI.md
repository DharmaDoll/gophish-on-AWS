# Gemini Added Memories

## General Instructions for this Project

- **Language:** When responding to the user, prioritize Japanese for explanations and communication.
- **File Saving Convention:** If the user says `出力を保存` (save output), save the preceding content to a temporary file (e.g., `./tmp/gemini_output_N.txt` where N is a unique number to avoid overwriting).
- **Adherence to Project Conventions:** Always analyze existing code, tests, and configuration to adhere to project conventions when making changes.
- **Security Best Practices:**
    - When creating `Dockerfile` or `docker-compose.yml`, always consider security best practices.
    - When generating Terraform code, be mindful of static analysis tools like `tfsec` and `terrascan` (as demonstrated with Checkov).
- **CI/CD:** If asked about CI/CD pipelines, provide concrete examples of GitHub Actions workflows.
- **Cost Optimization:** Actively propose cost optimization suggestions (e.g., leveraging AWS Spot Instances, optimizing resource types).
- **Testing:** This project currently relies on Terraform's static validation and manual post-deployment checks for quality assurance. If asked about testing, explain this approach and suggest tools like Terratest or InSpec for more rigorous infrastructure testing, if applicable.
