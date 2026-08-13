# AI Provider Configuration

AI Creation supports OpenAI-compatible chat providers with explicit local/cloud scope.

Provider descriptors store endpoint, model, scope, timeout, and an optional **environment-variable name** for credentials. Credential values are not valid provider-descriptor fields and must not be persisted in project/provider metadata.

Local providers must use loopback/localhost endpoints. Cloud providers require HTTPS.

The default privacy policy is local-only with cloud consent disabled. Enabling a cloud provider does not silently grant cloud consent; the privacy controls remain authoritative.

If a provider requires authentication, set the credential in the environment variable named by that provider's `credential_env` field before launching PlayWorld Studio. Do not put a secret directly into a provider descriptor or project file.

AI provider unavailability, invalid configuration, missing credentials, or privacy-policy rejection must surface as failure rather than simulated success. Preview-before-Execute remains the mutation boundary for AI-authored changes.
