import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase/supabaseClient';
import { toWAT, formatToWATDateString } from '../utils/dataUtils';
import { trimIspName } from '../utils/ispUtils';

const Alerts = () => {
  const [alerts, setAlerts] = useState([]);
  const isp = sessionStorage.getItem('isp');

  useEffect(() => {
    const fetchAlerts = async () => {
      const trimmedIsp = trimIspName(isp);
      console.log('Trimmed ISP:', trimmedIsp);

      // Fetch metrics data
      const { data: metrics, error: metricsError } = await supabase
        .from('NetworkMetrics')
        .select('UserID, Latitude, Longitude, Latency, PacketLoss, Throughput, SignalStrength, created_at')
        .eq('ISP', trimmedIsp);

      if (metricsError) {
        console.error('Error fetching metrics for alerts:', metricsError);
        return;
      }

      if (!metrics || metrics.length === 0) {
        setAlerts([]);
        return;
      }

      // Fetch phone numbers for each UserID and generate alerts
      const alertsWithPhone = await Promise.all(
        metrics.map(async (metric) => {
          // Fetch phone number for the user
          const { data: userData, error: userError } = await supabase
            .from('Users')
            .select('PhoneNumber')
            .eq('UserID', metric.UserID)
            .single();

          if (userError) {
            console.error(`Error fetching phone number for user ${metric.UserID}:`, userError);
          }

          const phoneNumber = userData?.PhoneNumber || 'N/A';

          // Generate alert based on metrics
          const latency = parseFloat(metric.Latency?.replace(' ms', '') || '0');
          const packetLoss = parseFloat(metric.PacketLoss?.replace('%', '') || '0');
          const throughput = metric.Throughput || 0;
          const signalStrength = metric.SignalStrength;

          let severity = 'low';
          let message = '';

          if (latency > 100 || packetLoss > 5 || throughput < 500 || signalStrength === 'Poor') {
            severity = 'high';
            message = 'Critical: High latency, packet loss, low throughput, or poor signal strength detected.';
          } else if (latency > 50 || packetLoss > 2 || throughput < 1000 || signalStrength === 'Fair') {
            severity = 'medium';
            message = 'Warning: Moderate issues with latency, packet loss, throughput, or signal strength.';
          } else {
            severity = 'low';
            message = 'Normal: All metrics within acceptable range.';
          }

          return {
            severity,
            message,
            phoneNumber,
            created_at: metric.created_at,
          };
        })
      );

      setAlerts(alertsWithPhone);
    };

    if (isp) {
      fetchAlerts();
    } else {
      window.location.href = '/';
    }
  }, [isp]);

  return (
    <div className="container">
      <h1 className="heading">Network Alerts</h1>
      {alerts.map((alert, index) => (
        <div key={index} className={`alert alert-${alert.severity}`}>
          <strong>{alert.severity.toUpperCase()}:</strong> {alert.message} (User Phone: {alert.phoneNumber}) - {formatToWATDateString(alert.created_at)}
        </div>
      ))}
    </div>
  );
};

export default Alerts;