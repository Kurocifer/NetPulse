import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase/supabaseClient';
import { trimIspName } from '../utils/ispUtils';

const Feedback = () => {
  const [feedbacks, setFeedbacks] = useState([]);
  const isp = sessionStorage.getItem('isp');

  useEffect(() => {
    const fetchFeedback = async () => {
      const trimmedIsp = trimIspName(isp);
      console.log('Trimmed ISP:', trimmedIsp);

      // Fetch feedback data
      const { data: feedbackData, error: feedbackError } = await supabase
        .from('FeedBack')
        .select('UserID, Rating, Comment, created_at')
        .eq('ISP', trimmedIsp);

      if (feedbackError) {
        console.error('Error fetching feedback:', feedbackError);
        setFeedbacks([]);
        return;
      }

      if (!feedbackData || feedbackData.length === 0) {
        setFeedbacks([]);
        return;
      }

      // Fetch phone numbers for each UserID
      const feedbacksWithPhone = await Promise.all(
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

          return {
            ...feedback,
            PhoneNumber: userData?.PhoneNumber || 'N/A',
          };
        })
      );

      setFeedbacks(feedbacksWithPhone);
    };

    if (isp) {
      fetchFeedback();
    } else {
      window.location.href = '/';
    }
  }, [isp]);

  return (
    <div className="container">
      <h1 className="heading">User Feedback</h1>
      {feedbacks.length === 0 ? (
        <div className="no-data">No data available</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Phone Number</th>
              <th>Rating / 5</th>
              <th>Comment</th>
              <th>Submission Time</th>
            </tr>
          </thead>
          <tbody>
            {feedbacks.map((feedback, index) => (
              <tr key={index}>
                <td>{feedback.PhoneNumber}</td>
                <td>{feedback.Rating || 'N/A'}</td>
                <td>{feedback.Comment || 'N/A'}</td>
                <td>{feedback.created_at ? new Date(feedback.created_at).toLocaleString('en-GB', { 
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

export default Feedback;