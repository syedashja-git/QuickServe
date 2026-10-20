import { createClient } from '@supabase/supabase-js';
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
export const db = url && key && !url.includes('YOUR_PROJECT') ? createClient(url,key) : null;
export const categories = ['Plumbing','Electrical','Cleaning','AC Repair','Painting','Carpentry'];
export const symbols = {'Plumbing':'◉','Electrical':'ϟ','Cleaning':'✧','AC Repair':'❄','Painting':'◒','Carpentry':'▥'};
export const samples = categories.map((category,i)=>({id:`sample-${i}`,name:['Ali Home Services','Bright Electric','Fresh Space','CoolCare','Color & Co.','Woodworks'][i],category,location:'Karachi',experience:[8,6,4,7,5,9][i],price:[1500,1800,2500,3000,2000,2200][i],description:'This is a sample listing. Connect Supabase and register a provider to enable real bookings.',sample:true}));
export const money = value => `Rs ${Number(value).toLocaleString('en-PK')}`;
export const unwrap = ({data,error}) => {if(error) throw error; return data;};
