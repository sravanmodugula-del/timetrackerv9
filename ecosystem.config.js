
// IISNode configuration for TimeTracker
// This file is used by IISNode to configure the Node.js application
module.exports = {
  // IISNode specific settings
  node_env: process.env.NODE_ENV || 'production',
  
  // Application entry point
  server: './dist/index.js',
  
  // Logging configuration for IISNode
  loggingEnabled: true,
  logDirectory: 'C:\\TimeTracker\\Logs',
  
  // Performance settings
  nodeProcessCountPerApplication: 2,
  maxConcurrentRequestsPerProcess: 1024,
  maxNamedPipeConnectionRetry: 100,
  namedPipeConnectionRetryDelay: 250,
  
  // Debug settings (disable in production)
  debuggingEnabled: false,
  debugHeaderEnabled: false,
  
  // Error handling
  gracefulShutdownTimeout: 60000,
  
  // Environment variables
  environmentVariables: {
    NODE_ENV: 'production',
    PORT: 3000,
    SQL_SERVER: 'HUB-SQL1TST-LIS',
    SQL_USER: 'timetracker',
    SQL_PASSWORD: 'iTT!$Lo7gm"i\'JAg~5Y\\',
    SQL_DATABASE: 'timetracker',
    DATABASE_URL: 'sqlserver://HUB-SQL1TST-LIS:1433;database=timetracker;user=timetracker;password=iTT!$Lo7gm"i\'JAg~5Y\\;encrypt=true;trustServerCertificate=true',
    TZ: 'America/Los_Angeles'
  }
};
