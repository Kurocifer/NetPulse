import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase/supabaseClient';
import { Line } from 'react-chartjs-2';
import { Chart as ChartJS, LineElement, PointElement, LinearScale, Title, Tooltip, Legend, TimeScale } from 'chart.js';
import 'chartjs-adapter-date-fns';
import { trimIspName } from '../utils/ispUtils';

ChartJS.register(LineElement, PointElement, LinearScale, Title, Tooltip, Legend, TimeScale);

const Overview = () => {
  const [metrics, setMetrics] = useState([]);
  const isp = sessionStorage.getItem('isp');

  useEffect(() => {
    const fetchMetrics = async () => {
      const trimmedIsp = trimIspName(isp);
      console.log('Trimmed ISP:', trimmedIsp);

      // Fetch metrics data
      const { data: metricsData, error: metricsError } = await supabase
        .from('NetworkMetrics')
        .select('UserID, Latitude, Longitude, Latency, PacketLoss, Throughput, SignalStrength, created_at')
        .eq('ISP', trimmedIsp);

      if (metricsError) {
        console.error('Error fetching metrics:', metricsError);
        return;
      }

      if (!metricsData || metricsData.length === 0) {
        setMetrics([]);
        return;
      }

      // Fetch phone numbers for each UserID
      const metricsWithPhone = await Promise.all(
        metricsData.map(async (metric) => {
          const { data: userData, error: userError } = await supabase
            .from('Users')
            .select('PhoneNumber')
            .eq('UserID', metric.UserID)
            .single();

          if (userError) {
            console.error(`Error fetching phone number for user ${metric.UserID}:`, userError);
            return { ...metric, PhoneNumber: 'N/A' };
          }

          return { ...metric, PhoneNumber: userData?.PhoneNumber || 'N/A' };
        })
      );

      setMetrics(metricsWithPhone);
    };

    if (isp) {
      fetchMetrics();
    } else {
      window.location.href = '/';
    }
  }, [isp]);

  const latencyData = {
    labels: metrics.map(m => new Date(m.created_at)),
    datasets: [
      {
        label: 'Latency (ms)',
        data: metrics.map(m => parseFloat(m.Latency?.replace(' ms', '') || '0')),
        borderColor: '#1E40AF',
        fill: false,
      },
    ],
  };

  const throughputData = {
    labels: metrics.map(m => new Date(m.created_at)),
    datasets: [
      {
        label: 'Throughput (kbps)',
        data: metrics.map(m => m.Throughput || 0),
        borderColor: '#10B981',
        fill: false,
      },
    ],
  };

  const chartOptions = {
    scales: {
      x: {
        type: 'time',
        time: {
          unit: 'day',
        },
        title: {
          display: true,
          text: 'Date',
        },
      },
      y: {
        title: {
          display: true,
          text: 'Value',
        },
      },
    },
  };

  return (
    <div className="container">
      <h1 className="heading">Overview</h1>
      <div className="chart-container">
        <h2 className="heading">Latency Over Time</h2>
        <Line data={latencyData} options={chartOptions} />
      </div>
      <div className="chart-container">
        <h2 className="heading">Throughput Over Time</h2>
        <Line data={throughputData} options={chartOptions} />
      </div>
      <table className="table">
        <thead>
          <tr>
            <th>Phone Number</th>
            <th>Latency (ms)</th>
            <th>Packet Loss (%)</th>
            <th>Throughput (kbps)</th>
            <th>Signal Strength</th>
            <th>Timestamp</th>
          </tr>
        </thead>
        <tbody>
          {metrics.map((metric, index) => (
            <tr key={index}>
              <td>{metric.PhoneNumber}</td>
              <td>{metric.Latency || 'N/A'}</td>
              <td>{metric.PacketLoss || 'N/A'}</td>
              <td>{metric.Throughput || 'N/A'}</td>
              <td>{metric.SignalStrength || 'N/A'}</td>
              <td>{metric.created_at ? new Date(metric.created_at).toLocaleString('en-GB', { 
                day: '2-digit', 
                month: '2-digit', 
                year: 'numeric', 
                hour: '2-digit', 
                minute: '2-digit', 
                second: '2-digit', 
                timeZone: 'Africa/Lagos' 
              }) : 'N/A'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Overview;