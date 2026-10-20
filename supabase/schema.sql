-- Run ONCE in a fresh Supabase project's SQL Editor before registering users.
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null check (length(trim(name)) between 2 and 100),
 role text not null check (role in ('customer','provider'))
);
create table public.providers (
 id uuid primary key references public.profiles(id) on delete cascade,
 name text not null check (length(trim(name)) between 2 and 100),
 category text not null check(category in ('Plumbing','Electrical','Cleaning','AC Repair','Painting','Carpentry')),
 location text not null check(length(trim(location)) between 2 and 200),
 experience integer not null default 0 check(experience between 0 and 80),
 price numeric not null check(price > 0 and price <= 10000000),
 description text not null check(length(trim(description)) between 10 and 1500)
);
create table public.bookings (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.profiles(id),
 provider_id uuid not null references public.providers(id),
 service text not null,
 scheduled_at timestamptz not null,
 location text not null check(length(trim(location)) between 5 and 300),
 description text not null check(length(trim(description)) between 10 and 1500),
 price numeric not null,
 status text not null default 'Pending' check(status in ('Pending','Accepted','Rejected','In Progress','Completed')),
 created_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid unique not null references public.bookings(id),
 customer_id uuid not null references public.profiles(id),
 provider_id uuid not null references public.providers(id),
 rating integer not null check(rating between 1 and 5),
 comment text not null check(length(trim(comment)) between 3 and 1000),
 created_at timestamptz not null default now()
);
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,name,role) values(new.id,trim(new.raw_user_meta_data->>'name'),new.raw_user_meta_data->>'role');
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Database-level workflow guards: UI cannot bypass transitions or review rules.
create function public.guard_booking() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if TG_OP='INSERT' then
  if new.customer_id is distinct from auth.uid() or not exists(select 1 from profiles where id=auth.uid() and role='customer') then raise exception 'Customer login required'; end if;
  if new.status <> 'Pending' or new.scheduled_at <= now() then raise exception 'Choose a future appointment'; end if;
  select category,price into new.service,new.price from providers where id=new.provider_id;
  if new.service is null then raise exception 'Provider unavailable'; end if;
  new.created_at := now();
 else
  if old.provider_id is distinct from auth.uid() then raise exception 'Only the assigned provider can update status'; end if;
  if (to_jsonb(new)-'status') is distinct from (to_jsonb(old)-'status') then raise exception 'Booking details cannot be edited'; end if;
  if not ((old.status='Pending' and new.status in ('Accepted','Rejected')) or (old.status='Accepted' and new.status='In Progress') or (old.status='In Progress' and new.status='Completed')) then raise exception 'Invalid status transition'; end if;
 end if;
 return new;
end; $$;
create trigger validate_booking before insert or update on public.bookings for each row execute function public.guard_booking();
create function public.guard_review() returns trigger language plpgsql security definer set search_path=public as $$
declare b public.bookings;
begin
 select * into b from bookings where id=new.booking_id;
 if b.id is null or b.customer_id is distinct from auth.uid() or b.status <> 'Completed' then raise exception 'You can only review your completed booking'; end if;
 new.customer_id:=auth.uid(); new.provider_id:=b.provider_id; new.created_at:=now();
 return new;
end; $$;
create trigger validate_review before insert on public.reviews for each row execute function public.guard_review();
alter table public.profiles enable row level security;
alter table public.providers enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;
revoke all on public.profiles,public.providers,public.bookings,public.reviews from anon,authenticated;
grant select on public.providers,public.reviews to anon,authenticated;
grant select on public.profiles,public.bookings to authenticated;
grant insert,update on public.providers to authenticated;
grant insert on public.bookings,public.reviews to authenticated;
grant update(status) on public.bookings to authenticated;
create policy own_profile on public.profiles for select to authenticated using(id=auth.uid());
create policy browse_providers on public.providers for select using(true);
create policy create_provider on public.providers for insert to authenticated with check(id=auth.uid() and exists(select 1 from profiles where id=auth.uid() and role='provider'));
create policy edit_provider on public.providers for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy view_bookings on public.bookings for select to authenticated using(customer_id=auth.uid() or provider_id=auth.uid());
create policy new_booking on public.bookings for insert to authenticated with check(customer_id=auth.uid() and exists(select 1 from profiles where id=auth.uid() and role='customer'));
create policy update_booking on public.bookings for update to authenticated using(provider_id=auth.uid()) with check(provider_id=auth.uid());
create policy public_reviews on public.reviews for select using(true);
create policy add_review on public.reviews for insert to authenticated with check(customer_id=auth.uid());
revoke execute on function public.handle_new_user(),public.guard_booking(),public.guard_review() from public,anon,authenticated;
