import React, { useState, useEffect } from 'react';
import './styles.css';

function App() {
  const [health, setHealth] = useState({ status: 'loading...' });
  const [metrics, setMetrics] = useState({
    redis_connected: false,
    mongodb_connected: false
  });
  const [services, setServices] = useState(null);
  const [error, setError] = useState(null);

  // Get the current hostname and construct the base URL
  const hostname = window.location.hostname;
  const API_BASE_URL = hostname.includes('github.dev') 
    ? `https://${hostname.replace('github.dev', 'preview.app.github.dev')}/api`
    : 'http://localhost/api';

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Health check
        const healthResponse = await fetch(`${API_BASE_URL}/health`, {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        });
        if (!healthResponse.ok) throw new Error('Health check failed');
        const healthData = await healthResponse.json();
        setHealth(healthData);

        // Metrics
        const metricsResponse = await fetch(`${API_BASE_URL}/metrics`, {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        });
        if (!metricsResponse.ok) throw new Error('Metrics check failed');
        const metricsData = await metricsResponse.json();
        setMetrics(metricsData);

        // Services
        const servicesResponse = await fetch(`${API_BASE_URL}/services`, {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        });
        if (!servicesResponse.ok) throw new Error('Services check failed');
        const servicesData = await servicesResponse.json();
        
        // Update service URLs for GitHub Codespace
        if (hostname.includes('github.dev')) {
          const updatedServices = {};
          Object.entries(servicesData.services).forEach(([name, url]) => {
            const port = url.split(':').pop();
            updatedServices[name] = `https://${hostname.replace('github.dev', `preview.app.github.dev`)}`;
          });
          servicesData.services = updatedServices;
        }
        
        setServices(servicesData);
        setError(null);
      } catch (error) {
        console.error('Error fetching data:', error);
        setError(error.message);
      }
    };

    // Initial fetch
    fetchData();

    // Set up polling every 5 seconds
    const interval = setInterval(fetchData, 5000);

    // Cleanup interval on component unmount
    return () => clearInterval(interval);
  }, [API_BASE_URL, hostname]);

  // Rest of your component remains the same...
  return (
    <div className="container">
      <header className="header">
        <h1>Multi-Container Application Dashboard</h1>
      </header>

      <main className="main">
        {error && (
          <div className="card error-card">
            <h2>Error</h2>
            <div className="error-box">
              {error}
            </div>
          </div>
        )}

        <div className="card">
          <h2>System Health</h2>
          <div className="status-box">
            <p>
              System Status: 
              <span className={`status ${health.status === 'healthy' ? 'healthy' : 'unhealthy'}`}>
                <span className="status-indicator"></span>
                {health.status}
              </span>
            </p>
            {health.timestamp && (
              <p className="timestamp">
                Last Updated: {new Date(health.timestamp * 1000).toLocaleTimeString()}
              </p>
            )}
          </div>
        </div>

        <div className="card">
          <h2>System Metrics</h2>
          <div className="metrics-box">
            <p>
              Redis Connection
              <span className={metrics.redis_connected ? 'healthy' : 'unhealthy'}>
                <span className="status-indicator"></span>
                {metrics.redis_connected ? 'Connected' : 'Disconnected'}
              </span>
            </p>
            <p>
              MongoDB Connection
              <span className={metrics.mongodb_connected ? 'healthy' : 'unhealthy'}>
                <span className="status-indicator"></span>
                {metrics.mongodb_connected ? 'Connected' : 'Disconnected'}
              </span>
            </p>
            {metrics.timestamp && (
              <p className="timestamp">
                Last Updated: {new Date(metrics.timestamp * 1000).toLocaleTimeString()}
              </p>
            )}
          </div>
        </div>

        {services && (
          <div className="card">
            <h2>Available Services</h2>
            <div className="services-box">
              {Object.entries(services.services).map(([name, url]) => (
                <p key={name}>
                  <span className="service-name">{name.charAt(0).toUpperCase() + name.slice(1)}</span>
                  <a href={url} target="_blank" rel="noopener noreferrer">
                    {url} ↗
                  </a>
                </p>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;