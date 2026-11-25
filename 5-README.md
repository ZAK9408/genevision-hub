# GeneVision Hub

Interactive molecular biology simulations (PCR, CRISPR-Cas9, Transcription and Translation) plus a student and researcher project showcase with a project builder and structured peer review. English UI. Every project and every comment waits for the site owner's approval before it is public.

Stack: React + TypeScript + Vite + Tailwind CSS + Framer Motion + Lucide. Database and logins: Supabase (free plan). Without Supabase keys the site runs in **demo mode** (data stays in the visitor's own browser).

## Run locally
    npm install
    npm run dev        # development
    npm run build      # production build in dist/

## A. Set up the shared database (once, about 10 minutes)
1. Create a free account at supabase.com and a new project. Save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, click **Run**.
3. Open **Project Settings > API**. Copy the **Project URL** and the **anon public key**.
4. Optional but recommended: **Authentication > Providers > Email**. If you turn off "Confirm email", new users can sign in right after signing up. If you keep it on, they must click the link in the email first.
5. In **Authentication > URL Configuration**, set the Site URL to your live site address (after step B).

## B. Publish for free (pick one)
Set these two environment variables on the host (copy `.env.example`): `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. The anon key is meant to be public; the database rules (row level security in schema.sql) protect the data.

- **Netlify**: push the folder to GitHub, then "Add new site > Import from Git". Build command `npm run build`, publish directory `dist`. Add the two variables in Site settings > Environment variables, then redeploy.
- **Vercel**: import the GitHub repo. Framework Vite is detected. Add the two variables, deploy.
- **Cloudflare Pages**: connect the repo. Build command `npm run build`, output directory `dist`. Add the variables.
- **GitHub Pages**: add the two variables as repository secrets and publish `dist` with a GitHub Action, or build locally and push `dist` to a `gh-pages` branch. The site uses hash routing, so it works on subpaths.

To update later: change the code, push to GitHub, and the host rebuilds by itself.

## C. Become the owner (admin)
1. Open your live site, click **Sign in > Create a new account**, and sign up with YOUR email.
2. In Supabase **SQL Editor** run (put your email):

        insert into public.admins (user_id, email)
        select id, email from auth.users where email = 'YOUR-EMAIL@example.com';

3. Reload the site and sign in. An **Admin** button appears in the top bar.

## D. How to control everything as admin
- **Admin > Projects**: filter by Pending. For each project: Approve (it appears in the showcase), Reject, Delete, or Block author. Click the title to read the full project first.
- **Admin > Reviews & comments**: same actions for questions, notes and ideas. Nothing shows publicly until you approve it.
- **Blocked users**: users you blocked cannot submit projects or comments. Unblock them from the Blocked users tab.
- Users see only approved items plus their own pending ones. Editing an approved project sends it back to pending.
- **Add another admin**: run the insert above with their email.
- **Remove an admin**: `delete from public.admins where email = 'their@email.com';`
- **See users**: Supabase > Authentication > Users (you can delete or ban accounts there too).
- **Edit data directly**: Supabase > Table Editor > projects / reviews.
- **Emergency**: in Table Editor set a project's `status` to `rejected` to hide it immediately.
- The six built-in sample projects are illustrative examples in the code (`src/data/projects.ts`). Edit or delete them there.

## Notes
- Simulations are simplified educational models and are not lab-validated predictions.
- Demo mode (no Supabase keys): sign in with `admin@demo.local` to try the admin panel. It only affects that browser.
