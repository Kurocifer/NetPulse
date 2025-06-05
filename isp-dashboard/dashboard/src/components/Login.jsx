import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const Login = () => {
  const [isp, setIsp] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(null);

    try {
      const response = await fetch('http://localhost:3001/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isp, password }),
      });

      const result = await response.json();

      if (!response.ok) {
        setError(result.error || 'Invalid ISP or password');
        return;
      }

      sessionStorage.setItem('isp', isp);
      navigate('/overview');
    } catch (err) {
      setError('Error logging in');
    }
  };

  return (
    <div className="container">
      <h1 className="heading">ISP Login</h1>
      <form onSubmit={handleLogin} className="form">
        <div className="form-group">
          <label className="form-label">ISP Name</label>
          <select
            value={isp}
            onChange={(e) => setIsp(e.target.value)}
            className="form-select"
            required
          >
            <option value="" disabled>Select ISP</option>
            <option value="CAMTEL CAM">CAMTEL CAM</option>
            <option value="ORANGE CAM">ORANGE CAM</option>
            <option value="MTN CAM">MTN CAM</option>
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="form-input"
            required
          />
        </div>
        {error && <p className="error">{error}</p>}
        <button type="submit" className="button">
          Login
        </button>
      </form>
    </div>
  );
};

export default Login;