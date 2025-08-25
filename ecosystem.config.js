
module.exports = {
  apps: [{
    name: 'timetracker',
    script: 'server/index.js',
    instances: 1,
    exec_mode: 'fork',
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000,
      SQL_SERVER: 'HUB-SQL1TST-LIS',
      SQL_USER: 'timetracker',
      SQL_PASSWORD: 'iTT!$Lo7gm"i\'JAg~5Y\\',
      SQL_DATABASE: 'timetracker',
      DATABASE_URL: 'sqlserver://HUB-SQL1TST-LIS:1433;database=timetracker;user=timetracker;password=iTT!$Lo7gm"i\'JAg~5Y\\;encrypt=true;trustServerCertificate=true'
    },
    error_file: 'C:\\TimeTracker\\logs\\err.log',
    out_file: 'C:\\TimeTracker\\logs\\out.log',
    log_file: 'C:\\TimeTracker\\logs\\combined.log',
    time: true,
    max_memory_restart: '1G',
    restart_delay: 4000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
