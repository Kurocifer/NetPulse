import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase/supabaseClient';
import { trimIspName } from '../utils/ispUtils';

const Regional = () => {
  const [regions, setRegions] = useState([]);
  const isp = sessionStorage.getItem('isp');

  useEffect(() => {
    const fetchRegionalData = async () => {
      const trimmedIsp = trimIspName(isp);
      console.log('Trimmed ISP:', trimmedIsp);

      // Fetch metrics data
      const { data: metricsData, error: metricsError } = await supabase
        .from('NetworkMetrics')
        .select('UserID, Latitude, Longitude, Latency, PacketLoss, Throughput, SignalStrength, created_at')
        .eq('ISP', trimmedIsp);

      if (metricsError) {
        console.error('Error fetching regional data:', metricsError);
        setRegions([]);
        return;
      }

      if (!metricsData || metricsData.length === 0) {
        setRegions([]);
        return;
      }

      // Group metrics by region and collect UserIDs
      const groupedMetrics = metricsData.reduce((acc, curr) => {
        const lat = curr.Latitude ? Math.round(curr.Latitude * 100) / 100 : null;
        const lon = curr.Longitude ? Math.round(curr.Longitude * 100) / 100 : null;
        const key = lat && lon ? `${lat},${lon}` : 'unknown';
        if (!acc[key]) {
          acc[key] = { metrics: [], userIDs: new Set() };
        }
        acc[key].metrics.push(curr);
        acc[key].userIDs.add(curr.UserID ?? '');
        return acc;
      }, {});

      // Fetch phone numbers and location names for each region
      const regionData = await Promise.all(
        Object.keys(groupedMetrics).map(async (key) => {
          const { metrics, userIDs } = groupedMetrics[key];

          // Fetch phone numbers for all UserIDs in this region
          const phoneNumbers = [];
          for (const userID of Array.from(userIDs)) {
            if (!userID) continue; // Skip empty UserIDs
            const { data: userData, error: userError } = await supabase
              .from('Users')
              .select('PhoneNumber')
              .eq('UserID', userID)
              .single();

            if (userError) {
              console.error(`Error fetching phone number for user ${userID}:`, userError);
              phoneNumbers.push('N/A');
            } else {
              phoneNumbers.push(userData?.PhoneNumber || 'N/A');
            }
          }

          // Reverse geocode the location
          let locationLabel = 'Unknown Location';
          if (key !== 'unknown') {
            const [lat, lon] = key.split(',').map(Number);
            try {
              const response = await fetch(
                `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10&addressdetails=1`,
                {
                  headers: {
                    'User-Agent': 'NetPulse/1.0 (contact: your-email@example.com)',
                  },
                }
              );
              const data = await response.json();
              if (data && data.address) {
                const { city, town, village, state, country } = data.address;
                const parts = [];
                if (city || town || village) parts.push(city || town || village);
                if (state) parts.push(state);
                if (country) parts.push(country);
                locationLabel = parts.length > 0 ? parts.join(', ') : `Region (${lat}, ${lon})`;
              }
            } catch (error) {
              console.error(`Error reverse geocoding (${lat}, ${lon}):`, error);
            }
          }

          // Calculate averages
          const avgLatency = metrics.reduce((sum, m) => sum + (parseFloat(m.Latency?.replace(' ms', '') || '0') || 0), 0) / (metrics.length || 1);
          const avgPacketLoss = metrics.reduce((sum, m) => sum + (parseFloat(m.PacketLoss?.replace('%', '') || '0') || 0), 0) / (metrics.length || 1);
          const avgThroughput = metrics.reduce((sum, m) => sum + (m.Throughput || 0), 0) / (metrics.length || 1);
          const avgSignalStrength = metrics.reduce((sum, m) => sum + (m.SignalStrength === 'Good' ? 80 : m.SignalStrength === 'Fair' ? 50 : (m.SignalStrength ?? 'Poor') === 'Poor' ? 20 : 0), 0) / (metrics.length || 1);

          // Get the most recent timestamp
          const latestTimestamp = metrics.reduce((latest, curr) => {
            const currDate = new Date(curr.created_at);
            return !latest || currDate > new Date(latest) ? curr.created_at : latest;
          }, null);

          return {
            key,
            label: locationLabel,
            avgLatency,
            avgPacketLoss,
            avgThroughput,
            avgSignalStrength,
            phoneNumbers: phoneNumbers.filter(phone => phone !== 'N/A'),
            latestTimestamp,
          };
        })
      );

      setRegions(regionData);
    };

    if (isp) {
      fetchRegionalData();
    } else {
      window.location.href = '/';
    }
  }, [isp]);

  return (
    <div className="container">
      <h1 className="heading">Regional Performance</h1>
      {regions.length === 0 ? (
        <div className="no-data">No data available</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Region</th>
              <th>Avg Latency (ms)</th>
              <th>Avg Packet Loss (%)</th>
              <th>Avg Throughput (kbps)</th>
              <th>Avg Signal Strength (%)</th>
              <th>Affected Users' Phone Numbers</th>
              <th>Latest Submission Time</th>
            </tr>
          </thead>
          <tbody>
            {regions.map(region => (
              <tr key={region.key}>
                <td>{region.label}</td>
                <td>{region.avgLatency.toFixed(2)}</td>
                <td>{region.avgPacketLoss.toFixed(2)}</td>
                <td>{region.avgThroughput.toFixed(2)}</td>
                <td>{region.avgSignalStrength.toFixed(2)}</td>
                <td>{region.phoneNumbers.length > 0 ? region.phoneNumbers.join(', ') : 'N/A'}</td>
                <td>{region.latestTimestamp ? new Date(region.latestTimestamp).toLocaleString('en-GB', { 
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
      )}
    </div>
  );
};

export default Regional;