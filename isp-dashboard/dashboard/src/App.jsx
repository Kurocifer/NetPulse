import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Login from './components/Login.jsx';
import Navbar from './components/Navbar.jsx';
import Overview from './components/Overview.jsx';
import Regional from './components/Regional.jsx';
import Feedback from './components/Feedback.jsx';
import Alerts from './components/Alerts.jsx';
import ChangePassword from './components/ChangePassword.jsx';

const AppContent = () => {
  const location = useLocation();
  const hideNavbar = location.pathname === '/';

  return (
    <>
      {!hideNavbar && <Navbar />}
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/overview" element={<Overview />} />
        <Route path="/regional" element={<Regional />} />
        <Route path="/feedback" element={<Feedback />} />
        <Route path="/alerts" element={<Alerts />} />
        <Route path="/change-password" element={<ChangePassword />} />
      </Routes>
    </>
  );
};

const App = () => {
  return (
    <Router>
      <AppContent />
    </Router>
  );
};

export default App;