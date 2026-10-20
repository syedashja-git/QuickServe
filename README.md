# QuickServe — Hackathon Task C

React + JavaScript + React Router + Supabase. Responsive service discovery, customer/provider accounts, bookings, status workflow and reviews.

## Status — please read
Source implementation provided. Supabase must be configured before authentication or booking works. Without configuration the app displays SIX clearly labelled sample service profiles; these cannot receive bookings. Real provider accounts publish their own listings. Missing categories retain sample cards so all six service categories are visible. No fabricated ratings or demo passwords.

Live Supabase integration, GitHub repository, hosted deployment and demo accounts are NOT provisioned by this ZIP. Complete the setup and acceptance checklist below before submitting.

## Windows / VS Code setup (Roman Urdu)
1. ZIP extract karein. `quickserve` folder VS Code mein Open Folder karein. Yeh standalone project hai; apna pehla project overwrite karna zaroori nahi.
2. Node.js 22.12+ (or supported newer LTS) aur internet chahiye. Terminal kholein:
   ```powershell
   npm.cmd install
   ```
3. Supabase par naya project banayein: https://supabase.com/dashboard
4. Supabase SQL Editor mein `supabase/schema.sql` ki poori file paste karke Run karein. Fresh project par ONCE chalayein. Iske baad users register karein; pehle banaye users ka profile auto-create nahi hoga.
5. Project Connect dialog / API settings se Project URL aur PUBLIC publishable key (ya legacy anon key) copy karein. Secret/service_role key browser mein bilkul use na karein.
6. `.env.example` ki copy `.env` banayein. Dono placeholder values replace karein. Yeh file `package.json` ke saath root folder mein honi chahiye.
7. Run:
   ```powershell
   npm.cmd run dev
   ```
8. Terminal ka localhost link kholein. `.env` change karne ke baad server Ctrl+C se stop karke dobara start karein.
9. Auth email confirmation enabled ho to apni email confirm karein, phir login. Supabase Auth URL Configuration mein local URL aur baad mein deployed URL configure karein. Shared demos ke liye confirmed, disposable test accounts banayein.

If npm fails in PowerShell, use `npm.cmd` as shown. No PowerShell security-policy change is required.

## Demonstration accounts (create these yourself)
- Customer: register a test email as Customer.
- Provider: use a separate test email as Provider; dashboard mein service profile complete karein.
- Use separate browser profiles or an incognito window to keep both signed in simultaneously.
- For six REAL bookable professionals, register six provider accounts, one per category. Sample cards are just placeholders.
- Record ONLY disposable demo email/password pairs in your private submission sheet; no personal credentials. This project does not ship real credentials.

## End-to-end demo / acceptance checklist
- Browse six service categories. Search by name/location and filter category; test no-results state.
- Create and confirm a customer, and a separate provider. Log out/in; refresh to verify sessions.
- Provider publishes profile (name, category, area, experience, price, description); customer can see it.
- Customer opens provider details, picks FUTURE date/time, valid address and description; submits booking.
- Verify UUID booking ID, service and price snapshot, Pending status; refresh page to verify persistence.
- Provider dashboard: click Refresh bookings to get new requests (manual refresh, no realtime subscription).
- Accept -> Start work -> Mark completed. Customer clicks Refresh after each step.
- Review form appears ONLY after Completed. Submit 1–5 stars plus comment. Rating appears on provider profile/home after reload.
- A second review for the same booking must fail (database UNIQUE constraint).
- Make a second booking; reject it. Verify no Start work action and database rejects transition.
- Completed/rejected records cannot be edited through workflow.
- An unrelated third account cannot read others' bookings or update another provider's status.
- Test required fields, whitespace-only values, past appointments, phone layout, invalid login and database errors.

## Database / security
Tables: profiles, providers, bookings, reviews. A signup trigger creates immutable-role profiles. Public provider signup is intentional for this marketplace; role cannot later be switched by editing user metadata. Each provider owns ONE public listing. Customers own their bookings. Only assigned providers can update status. Database triggers enforce transitions and authoritative service/price snapshots. RLS restricts access, column grants restrict booking updates to status, and duplicate reviews are prevented by a unique booking_id. Reviews are public and include internal UUIDs; no customer emails are public.

Transitions:
Pending -> Accepted -> In Progress -> Completed
Pending -> Rejected

Appointment inputs use the browser's local timezone; stored timestamps are UTC. No payment collection, slot collision prevention, cancellation, admin moderation, image upload or notifications included; these are outside this focused MVP. Ratings use real completed-booking reviews only.

## Project files
- src/App.jsx — routes, discovery, auth, provider detail, booking/dashboard UI.
- src/client.js — Supabase client, sample service cards, helpers.
- src/style.css — responsive design, no CSS framework required.
- supabase/schema.sql — tables, grants, RLS, triggers and workflow rules.
- .env.example — public client configuration template.

## Build and deploy
```powershell
npm.cmd run build
npm.cmd run preview
```
Upload to a GitHub repository, excluding node_modules, dist and .env. Import the repository into your chosen Vite-compatible host (for example Vercel or Netlify). Build command: `npm run build`; output directory: `dist`. Add both VITE_ variables in hosting environment settings and rebuild. HashRouter is used so routes survive page reloads on static hosting without rewrite rules. Add your final site URL to Supabase Auth settings.

## Submission checklist
- GitHub repository link
- Working hosted application link
- This README with YOUR deployment details
- Two working disposable demo accounts (customer/provider)
- Short demo: browse -> login -> request -> accept -> in progress -> complete -> review
- AI declaration: “OpenAI ChatGPT assisted with code generation, UI design, SQL schema and testing guidance. I configured and reviewed the project and can explain its workflow.” Adjust this statement truthfully to reflect your own work.

## References
https://supabase.com/docs/guides/getting-started/quickstarts/reactjs
https://supabase.com/docs/guides/auth/quickstarts/react
https://vite.dev/guide/

## Verification performed
- `npm run build`: passed (React Router emits harmless use-client directive bundling warnings).
- PostgreSQL-compatible PGlite tests: passed schema setup, signup profile trigger, authoritative service/price, row isolation, immutable role/booking fields, valid transitions, premature/duplicate-review rejection, and completed/rejected terminal-state protection.
- Reproduce database tests: `npm.cmd run test:db`. These simulate Supabase auth context locally and do not test hosted Supabase Auth.
- Browser visual/interaction checks were attempted but could not run because the environment had no browser binary and the browser download failed. Responsive CSS is included; check desktop/mobile layout using the acceptance checklist.
- Live Supabase auth, email confirmations, cross-browser booking interaction and deployed site remain to be tested after configuration.
