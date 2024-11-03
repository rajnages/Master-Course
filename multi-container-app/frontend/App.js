import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [health, setHealth] = useState({});

  useEffect(() => {
    const fetchHealth = async () => {
      try {
        const response = await axios.get('/api/health');
        setHealth(response.data);
      } catch (error) {
        console.error('Error fetching health status:', error);
      }
    };

    fetchHealth();
  }, []);

  return (
    <div>
      <h1>Multi-Container App</h1>
      <div>
        <h2>System Health</h2>
        <pre>{JSON.stringify(health, null, 2)}</pre>
      </div>
    </div>
  );
}

export default App;