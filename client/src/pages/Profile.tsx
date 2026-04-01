import { useState, useEffect, useContext } from 'react';
import { AuthContext } from '../context/AuthContext';
import { getProfile, updateProfile, UserProfile } from '../api/mediaApi';

const Profile = () => {
  const context = useContext(AuthContext);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [visibility, setVisibility] = useState('public');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  if (!context) return <div>Loading...</div>;

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await getProfile();
        setProfile(res.data);
        setVisibility(res.data.profileVisibility);
      } catch {
        setMessage('Failed to load profile');
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  const handleSave = async () => {
    setSaving(true);
    setMessage('');
    try {
      const res = await updateProfile({ profileVisibility: visibility });
      setProfile(res.data.user);
      setMessage('Profile updated!');
    } catch {
      setMessage('Failed to update profile');
    } finally {
      setSaving(false);
      setTimeout(() => setMessage(''), 3000);
    }
  };

  if (loading) return <div className="loading">Loading profile...</div>;

  return (
    <div style={{ maxWidth: 500, margin: '40px auto', padding: '0 20px' }}>
      <h1>Profile Settings</h1>
      {profile && (
        <div style={{ background: 'white', borderRadius: 8, padding: 30, boxShadow: '0 2px 8px rgba(0,0,0,0.1)', marginTop: 20 }}>
          <p><strong>Username:</strong> {profile.username}</p>
          <p><strong>Email:</strong> {profile.email}</p>
          <div style={{ marginTop: 24 }}>
            <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>
              Profile Visibility
            </label>
            <select
              value={visibility}
              onChange={(e) => setVisibility(e.target.value)}
              style={{ padding: '10px 14px', borderRadius: 4, border: '1px solid #ddd', fontSize: 15, width: '100%' }}
            >
              <option value="public">Public</option>
              <option value="private">Private</option>
            </select>
          </div>
          <button
            onClick={handleSave}
            disabled={saving}
            style={{
              marginTop: 20,
              background: '#007bff',
              color: 'white',
              padding: '10px 28px',
              borderRadius: 4,
              fontSize: 15,
              cursor: saving ? 'not-allowed' : 'pointer',
              opacity: saving ? 0.7 : 1,
            }}
          >
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
          {message && (
            <p style={{ marginTop: 12, color: message.includes('Failed') ? '#dc3545' : '#28a745' }}>
              {message}
            </p>
          )}
        </div>
      )}
    </div>
  );
};

export default Profile;
