# NetPulse

A comprehensive solution to monitor and enhance network Quality of Experience (QoE) for Internet Service Providers (ISPs) in Cameroon by providing to network users, a simple way to report view the state of their network and report issues to their internet service providers. This project includes two main components:

- **QoE Mobile App**: A Flutter-based mobile app for users to submit real-time network performance data and feedback.
- **ISP Dashboard**: A React-based web interface for administrators to visualize network metrics and user feedback.

The system uses [Supabase](https://supabase.com) for secure authentication, real-time data syncing, and robust database management.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [Screenshots](#screenshots)

## Features

### QoE Mobile App
- User registration/login with email and password.
- Real-time submission of network metrics (throughput, signal strength, latency).
- Feedback submission with ratings and comments.
- GPS-based location data collection.
- Intuitive and user-friendly interface

### ISP Dashboard
- Real-time visualization of network metrics (latency, packet loss, throughput, signal strength).
- Regional performance analysis with human-readable location mapping.
- User feedback management with ratings and comments.
- CSV export for metrics and feedback data.
- Secure authentication with role-based access.


### Shared Backend
- Supabase-powered backend with PostgreSQL database.
- Row Level Security (RLS) for data privacy and ISP-specific access.
- Real-time updates via Supabase subscriptions.


## Prerequisites
- **Node.js** (v18.x or later) for the ISP Dashboard.
- **Flutter SDK** (v3.x or later) for the QoE Mobile App.
- **Git** for version control.
- **npm** or **yarn** for dashboard dependencies.
- **Mobile Development Dependencies** for mobile app development (emulators or physical devices).
- A **Supabase account** with a project created.

## Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/kurocifer/NetPulse.git
   cd NetPulse
   ```

2. **Set Up the Backend (Supabase)**

3. **Set Up NetPulse Mobile App**
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```
   Ensure an emulator or physical device is configured.

4. **Set Up the ISP Dashboard**
   - backend
      ```bash
      cd backend
      npm install
      npm run dev
      ```
   
   - dashboard
      ```bash
      cd dashboard
      npm install
      npm run dev
      ```


## Usage

### NetPulse App
- Launch on a device or emulator.
- Register or log in with user credentials.
- Allow Phone access for ISP detection and location (optional) access to submit network metrics.
- Submit feedback with ratings and comments.
- View real-time metric updates.

### ISP Dashboard
- Access at `http://localhost:3000`.
- Log in with admin credentials.
- Navigate tabs: Overview, Regional, Feedback, Alerts, Change Password.
- Downlaod metrics or feedback using the "Download as CSV" button.


## Configuration
- Create a `.env` file in both `dashboard/` and `mobile/`:
  ```
  SUPABASE_URL=your-supabase-url
  SUPABASE_ANON_KEY=your-supabase-anon-key
  ```

## Contributing
If any issue found please infor us by submitting an issue or if you have any ehancement then help with a pull request :)

## Screenshots
