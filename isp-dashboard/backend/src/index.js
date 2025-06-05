const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcrypt');

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Login endpoint
app.post('/login', async (req, res) => {
  try {
    const { isp, password } = req.body;
    console.log(isp, password)

    if (!isp || !password) {
      return res.status(400).json({ error: 'ISP name and password are required' });
    }

    const { data, error } = await supabase
      .from('ISPsAuth')
      .select('isp_name, password')
      .eq('isp_name', isp)
      .single();

    if (error || !data) {
      console.log("here")
      console.log(error)
      console.log(data)
      return res.status(401).json({ error: 'Invalid ISP or password' });
    }

    const isMatch = await bcrypt.compare(password, data.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid ISP or password' });
    }

    return res.status(200).json({ message: 'Login successful', isp: data.isp_name });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Something went wrong!' });
  }
});

// Change password endpoint
app.post('/change-password', async (req, res) => {
  try {
    const { isp, currentPassword, newPassword } = req.body;

    if (!isp || !currentPassword || !newPassword) {
      return res.status(400).json({ error: 'ISP name, current password, and new password are required' });
    }

    // Fetch current password
    const { data, error: fetchError } = await supabase
      .from('ISPsAuth')
      .select('password, has_changed_password')
      .eq('isp_name', isp)
      .single();

    if (fetchError || !data) {
      return res.status(400).json({ error: 'Error fetching ISP data' });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, data.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    // Hash new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password in Supabase
    const { error: updateError } = await supabase
      .from('ISPsAuth')
      .update({ password: hashedPassword, has_changed_password: true })
      .eq('isp_name', isp);

    if (updateError) {
      return res.status(500).json({ error: 'Error updating password' });
    }

    return res.status(200).json({ message: 'Password changed successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Something went wrong!' });
  }
});

app.listen(port, () => {
  console.log(`Backend server running on http://localhost:${port}`);
});