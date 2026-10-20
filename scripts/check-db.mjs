import {PGlite} from '@electric-sql/pglite';import fs from 'node:fs';
const db=new PGlite();
await db.exec(`create role anon; create role authenticated; create schema auth; create table auth.users(id uuid primary key,raw_user_meta_data jsonb); create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$; grant usage on schema public,auth to anon,authenticated; grant execute on function auth.uid() to anon,authenticated;`);
await db.exec(fs.readFileSync(new URL('../supabase/schema.sql',import.meta.url),'utf8'));
const c='00000000-0000-0000-0000-000000000001',p='00000000-0000-0000-0000-000000000002',x='00000000-0000-0000-0000-000000000003';
for(const [id,role] of [[c,'customer'],[p,'provider'],[x,'customer']])await db.query(`insert into auth.users values($1,$2)`,[id,JSON.stringify({name:'Test user',role})]);
async function as(id){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec('set role authenticated')}
async function fails(sql,args=[]){let failed=false;try{await db.query(sql,args)}catch{failed=true}if(!failed)throw Error('Expected rejection: '+sql)}
await as(p);await db.query("insert into providers values($1,'Test Provider','Plumbing','Karachi',5,1500,'Reliable home plumbing services')",[p]);await as(c);
const insert="insert into bookings(customer_id,provider_id,scheduled_at,location,description) values($1,$2,now()+interval '1 day','123 Test Street','Please fix the leaking tap') returning *";
let b=(await db.query(insert,[c,p])).rows[0];if(b.service!=='Plumbing'||Number(b.price)!==1500)throw Error('Snapshot failed');
await fails("insert into reviews(booking_id,customer_id,provider_id,rating,comment) values($1,$2,$3,5,'Excellent')",[b.id,c,p]);
await as(x);if((await db.query('select * from bookings')).rows.length)throw Error('RLS leak');await fails('update profiles set role=\'provider\' where id=$1',[x]);
await as(p);await fails("update bookings set status='Completed' where id=$1",[b.id]);await fails("update bookings set description='changed' where id=$1",[b.id]);
for(const s of ['Accepted','In Progress','Completed'])await db.query('update bookings set status=$1 where id=$2',[s,b.id]);await fails("update bookings set status='In Progress' where id=$1",[b.id]);
await as(c);await db.query("insert into reviews(booking_id,customer_id,provider_id,rating,comment) values($1,$2,$3,5,'Excellent')",[b.id,c,p]);await fails("insert into reviews(booking_id,customer_id,provider_id,rating,comment) values($1,$2,$3,4,'Again')",[b.id,c,p]);
let b2=(await db.query(insert,[c,p])).rows[0];await as(p);await db.query("update bookings set status='Rejected' where id=$1",[b2.id]);await fails("update bookings set status='In Progress' where id=$1",[b2.id]);
console.log('PASS: schema, profile trigger, price/service snapshot, row isolation, field permissions, full workflow, premature + duplicate reviews blocked, terminal states protected. PGlite simulated auth, not live Supabase.');await db.close();
