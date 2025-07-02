import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { CSVLink } from 'react-csv';
import { supabase } from '../supabase/supabaseClient';
import { trimIspName } from '../utils/ispUtils';

const Navbar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const isp = trimIspName(sessionStorage.getItem('isp'));
  const [csvData, setCsvData] = useState([]);
  const [csvType, setCsvType] = useState('networkMetrics');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const csvLinkRef = useRef(null);

  const handleLogout = () => {
    sessionStorage.removeItem('isp');
    navigate('/');
  };

  const fetchCsvData = async (type) => {
    let data = [];
    let error = null;

    if (type === 'networkMetrics') {
      const { data: metricsData, error: metricsError } = await supabase
        .from('NetworkMetrics')
        .select('UserID, Latitude, Longitude, Latency, PacketLoss, Throughput, SignalStrength, created_at, ISP')
        .eq('ISP', isp);
      data = metricsData || [];
      error = metricsError;
    } else if (type === 'userFeedback') {
      const { data: feedbackData, error: feedbackError } = await supabase
        .from('FeedBack')
        .select('UserID, Rating, Comment, created_at, ISP')
        .eq('ISP', isp);
      // Fetch phone numbers for feedback
      const feedbackWithPhone = await Promise.all(
        feedbackData.map(async (feedback) => {
          const { data: userData, error: userError } = await supabase
            .from('Users')
            .select('PhoneNumber')
            .eq('UserID', feedback.UserID)
            .single();

          if (userError) {
            console.error(`Error fetching phone number for user ${feedback.UserID}:`, userError);
            return { ...feedback, PhoneNumber: 'N/A' };
          }

          return { ...feedback, PhoneNumber: userData?.PhoneNumber || 'N/A' };
        })
      );
      data = feedbackWithPhone || [];
      error = feedbackError;
    }

    if (error) {
      console.error('Error fetching CSV data:', error);
      return;
    }

    setCsvData(data);
  };

  useEffect(() => {
    if (isp) {
      fetchCsvData(csvType);
    }
  }, [isp, csvType]);

  const handleDownloadClick = (type) => {
    setCsvType(type);
    setIsDropdownOpen(false);
    // Trigger download after data is updated
    setTimeout(() => {
      if (csvLinkRef.current) {
        csvLinkRef.current.link.click();
      }
    }, 100);
  };

  const getLinkClass = (path) => {
    return location.pathname === path ? 'navbar-link active' : 'navbar-link';
  };

  return (
    <nav className="navbar">
      <div className="navbar-brand">{sessionStorage.getItem('isp')} - NetPulse ISP Dashboard</div>
      <div className="navbar-links">
        <Link to="/overview" className={getLinkClass('/overview')}>Overview</Link>
        <Link to="/regional" className={getLinkClass('/regional')}>Regional</Link>
        <Link to="/feedback" className={getLinkClass('/feedback')}>Feedback</Link>
        {/* <Link to="/alerts" className={getLinkClass('/alerts')}>Alerts</Link> */}
        <Link to="/change-password" className={getLinkClass('/change-password')}>Change Password</Link>
        <div className="navbar-download">
          <button
            className="navbar-button"
            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
          >
            Download as CSV
          </button>
          {isDropdownOpen && (
            <div className="navbar-dropdown">
              <button
                className="navbar-dropdown-item"
                onClick={() => handleDownloadClick('networkMetrics')}
              >
                Network Metrics
              </button>
              <button
                className="navbar-dropdown-item"
                onClick={() => handleDownloadClick('userFeedback')}
              >
                User Feedback
              </button>
            </div>
          )}
          <CSVLink
            data={csvData}
            filename={`${csvType === 'networkMetrics' ? 'network-metrics' : 'user-feedback'}.csv`}
            className="hidden"
            ref={csvLinkRef}
          />
        </div>
        <button onClick={handleLogout} className="logout-button">Logout</button>
      </div>
    </nav>
  );
};

export default Navbar;