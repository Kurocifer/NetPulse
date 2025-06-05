import { createClient } from '@supabase/supabase-js';

  const supabaseUrl = 'https://zudknzwpxdubgvskieeh.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1ZGtuendweGR1Ymd2c2tpZWVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIwOTksImV4cCI6MjA2MzkxODA5OX0.hOSBq7vAvwI8no7ybPkoqhtbRgrBLy5pHzYakzf9jhw';

  export const supabase = createClient(supabaseUrl, supabaseAnonKey);