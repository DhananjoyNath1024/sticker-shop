-- Run in Supabase > SQL Editor. Then: Auth > Users > create ONE admin user, and turn OFF "Allow new users to sign up".
create table products(id uuid primary key default gen_random_uuid(),name text not null,category text,description text,price numeric not null,compare_price numeric,stock int not null default 0,badge text,images text[] default '{}',active bool default true,created_at timestamptz default now());
create table reviews(id uuid primary key default gen_random_uuid(),product_id uuid references products on delete cascade,name text not null,rating int check(rating between 1 and 5),comment text,approved bool default false,created_at timestamptz default now());
create table orders(id uuid primary key default gen_random_uuid(),order_no bigint generated always as identity,name text,phone text,email text,address text,city text,state text,pincode text,notes text,items jsonb,subtotal numeric,delivery_fee numeric,total numeric,payment text,status text default 'pending',source text default 'website',created_at timestamptz default now());
create table settings(key text primary key,value text);
alter table products enable row level security;alter table reviews enable row level security;alter table orders enable row level security;alter table settings enable row level security;
create policy p_read on products for select using(active);
create policy p_adm on products for all to authenticated using(true) with check(true);
create policy r_read on reviews for select using(approved);
create policy r_add on reviews for insert with check(approved=false);
create policy r_adm on reviews for all to authenticated using(true) with check(true);
create policy s_read on settings for select using(true);
create policy s_adm on settings for all to authenticated using(true) with check(true);
create policy o_adm on orders for all to authenticated using(true) with check(true);

-- Orders are placed through this function: prices, stock and delivery fee are computed on the server.
create or replace function place_order(p_name text,p_phone text,p_email text,p_address text,p_city text,p_state text,p_pincode text,p_notes text,p_payment text,p_items jsonb,p_fee numeric default null,p_status text default 'pending',p_source text default 'website')
returns json language plpgsql security definer set search_path=public as $$
declare it jsonb;r products;sub numeric:=0;fee numeric;lines jsonb:='[]';oid uuid;ono bigint;adm bool:=auth.uid() is not null;q int;
begin
 if coalesce(p_name,'')='' or coalesce(p_phone,'')='' or coalesce(p_address,'')='' then raise exception 'Name, phone and address are required'; end if;
 for it in select jsonb_array_elements(p_items) loop
  q:=(it->>'qty')::int;
  select * into r from products where id=(it->>'id')::uuid and (active or adm) for update;
  if not found or q<1 then raise exception 'Sticker not available'; end if;
  if r.stock<q then raise exception '% has only % left',r.name,r.stock; end if;
  update products set stock=stock-q where id=r.id;
  sub:=sub+r.price*q;
  lines:=lines||jsonb_build_array(jsonb_build_object('id',r.id,'name',r.name,'price',r.price,'qty',q,'image',r.images[1]));
 end loop;
 if jsonb_array_length(lines)=0 then raise exception 'Cart is empty'; end if;
 fee:=case when adm and p_fee is not null then p_fee
  when sub>=coalesce((select value::numeric from settings where key='free_delivery_above'),0) then 0
  else coalesce((select value::numeric from settings where key='delivery_fee'),0) end;
 insert into orders(name,phone,email,address,city,state,pincode,notes,items,subtotal,delivery_fee,total,payment,status,source)
 values(p_name,p_phone,p_email,p_address,p_city,p_state,p_pincode,p_notes,lines,sub,fee,sub+fee,p_payment,case when adm then p_status else 'pending' end,case when adm then p_source else 'website' end)
 returning id,order_no into oid,ono;
 return json_build_object('id',oid,'order_no',ono,'total',sub+fee);
end $$;
grant execute on function place_order to anon,authenticated;

insert into settings values('store_name','StickyBits'),('announcement','Free delivery above ₹499'),('hero_title','Stick it. Love it. Repeat.'),('hero_subtitle','Waterproof vinyl stickers for laptops, bottles and bikes.'),('hero_button','Shop stickers'),('currency','₹'),('delivery_fee','49'),('free_delivery_above','499'),('low_stock_threshold','5'),('low_stock_text','Only {n} left!'),('payment_note','Cash on Delivery available. For UPI we will share details on call.'),('contact','WhatsApp +91 90000 00000');

-- Image uploads from the admin panel
insert into storage.buckets(id,name,public) values('stickers','stickers',true) on conflict do nothing;
create policy st_adm on storage.objects for all to authenticated using(bucket_id='stickers') with check(bucket_id='stickers');
