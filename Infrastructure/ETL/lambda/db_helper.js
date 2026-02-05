const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const client = new SecretsManagerClient();
let cachedDbUrl;

async function getDatabaseUrl() {
  if (cachedDbUrl) return cachedDbUrl;

  const secretArn = process.env.DB_SECRET_ARN;
  if (!secretArn) {
    throw new Error("DB_SECRET_ARN environment variable is not set");
  }

  try {
    const command = new GetSecretValueCommand({ SecretId: secretArn });
    const response = await client.send(command);
    cachedDbUrl = response.SecretString;
    return cachedDbUrl;
  } catch (error) {
    console.error("Error retrieving database URL from Secrets Manager:", error);
    throw error;
  }
}

module.exports = { getDatabaseUrl };