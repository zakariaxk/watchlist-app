import React, { useEffect, useState } from 'react';
import { useLocation, Link } from 'react-router-dom';
import axios from 'axios';
import '../styles/verify-email.css';

const VerifyEmail = () => {
  const [message, setMessage] = useState('Verifying your email...');
  const location = useLocation();

    useEffect(() => {
      const verifyEmail = async () => {
        const token = new URLSearchParams(location.search).get('token');
        if (!token) {
          setMessage('Invalid verification link.');
          return;
        }

        try {
          await axios.get(`/auth/verify-email?token=${token}`);
          setMessage('Email verified successfully!');
        } catch (error) {
          setMessage('Email verification failed. The link may be invalid or expired.');
        }
      };

      verifyEmail();
    }, [location]);

  return (
    <div className="verify-email-page">
      <h1>Verify Email</h1>
      <p>{message}</p>
      <Link to="/login">Log In</Link>
    </div>
  );
};

export default VerifyEmail;