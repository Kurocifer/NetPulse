# NetPulse

NetPulse is a mobile app for monitoring network quality and collecting user feedback, integrated with Supabase for backend services, and includes an ISP dashboard for data insights.

## Project Scope
- **Mobile App**:
  - Authentication: Register (email, password, phone number, confirmation code), login, logout (with confirmation dialog).
  - Features: Monitor network metrics (signal strength, latency, packet loss), submit feedback (rating, comment, frequency), track data usage, customize settings (notifications, background data, location, language, theme, data deletion), receive push notifications.
  - Offline Support: Cache data locally using Hive and sync with Supabase.
  - Security: Use `encrypt` for data encryption, `flutter_secure_storage` for credentials, and Supabase row-level security.
- **Backend**:
  - Supabase for authentication, data storage (PostgreSQL), and real-time notifications (WebSocket).
  - Database Schema: `Users`, `NetworkMetrics`, `Feedback`, `ISPs`.
- **ISP Dashboard**:
  - React-based single-page app.
  - Features: ISP login, display metrics and feedback (filtered by ISPID), show phone numbers for insights, CSV export.
- **Version Control**: GitHub repositories for mobile app and ISP dashboard.

## Tech Stack
- **Mobile App**: Flutter (Dart), BLoC architecture, Fluent UI, plugins (`get`, `hive`, `supabase_flutter`, `network_info_plus`, `dart_ping`, `flutter_rating_bar`, `location`, `flutter_bloc`, `equatable`, `workmanager`, `encrypt`, `flutter_secure_storage`, `data_usage`).
- **Backend**: Supabase (PostgreSQL, Auth, WebSocket).
- **Local Storage**: Hive.
- **ISP Dashboard**: React (CDN-based), Tailwind CSS.
- **Tools**: GitHub, VS Code, Nowa, GitHub Actions, FlutterFlow.

## Development Phases
1. Project Planning and Setup
2. Mobile App Initial Structure
3. Supabase and Database Setup
4. Authentication Flow Setup
5. Core App Functionality Structure
6. Functionality Integration
7. Advanced Features
8. ISP Dashboard Development