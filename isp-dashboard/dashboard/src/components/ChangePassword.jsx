import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const ChangePassword = () => {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const isp = sessionStorage.getItem('isp');
  const navigate = useNavigate();

  const handleChangePassword = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!isp) {
      setError('No ISP logged in');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('New passwords do not match');
      return;
    }

    try {
      const response = await fetch('http://localhost:3001/change-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isp, currentPassword, newPassword }),
      });

      const result = await response.json();

      if (!response.ok) {
        setError(result.error || 'Error changing password');
        return;
      }

      setSuccess('Password changed successfully');
      setTimeout(() => navigate('/overview'), 2000);
    } catch (err) {
      setError('Error changing password');
    }
  };

  if (!isp) {
    window.location.href = '/';
    return null;
  }

  return (
    <div className="container">
      <h1 className="heading">Change Password</h1>
      <form onSubmit={handleChangePassword} className="form">
        <div className="form-group">
          <label className="form-label">Current Password</label>
          <input
            type="password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            className="form-input"
            required
          />
        </div>
        <div className="form-group">
          <label className="form-label">New Password</label>
          <input
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="form-input"
            required
          />
        </div>
        <div className="form-group">
          <label className="form-label">Confirm New Password</label>
          <input
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            className="form-input"
            required
          />
        </div>
        {error && <p className="error">{error}</p>}
        {success && <p className="success">{success}</p>}
        <button type="submit" className="button">
          Change Password
        </button>
      </form>
    </div>
  );
};

export default ChangePassword;