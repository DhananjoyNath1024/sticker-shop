const SUPABASE_URL='https://looildlcezzxmzlfkqqo.supabase.co',SUPABASE_KEY='sb_publishable_mIFEtsm-pVtX_iatXkRyRQ_GduFF8NZ';
const sb=supabase.createClient(SUPABASE_URL,SUPABASE_KEY);
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>'&#'+c.charCodeAt(0)+';');
let S={};
const money=n=>(S.currency||'₹')+Number(n||0).toLocaleString('en-IN');
const stars=n=>'★'.repeat(n)+'☆'.repeat(5-n);
const cart={get(){try{return JSON.parse(localStorage.cart||'{}')}catch{return{}}},set(c){localStorage.cart=JSON.stringify(c);const e=$('#cc');if(e)e.textContent=Object.values(c).reduce((a,b)=>a+b,0)},add(id,q){const c=this.get();c[id]=(c[id]||0)+q;this.set(c)}};
const toast=m=>{const t=document.createElement('div');t.className='toast';t.textContent=m;document.body.append(t);setTimeout(()=>t.remove(),2400)};
async function loadS(){const{data}=await sb.from('settings').select('*');S=Object.fromEntries((data||[]).map(r=>[r.key,r.value]))}
async function init(){
 await loadS();
 document.body.insertAdjacentHTML('afterbegin',(S.announcement?`<div class="bar">${esc(S.announcement)}</div>`:'')+`<header class="nav"><div class="wrap"><a class="logo" href="index.html">${esc(S.store_name||'Stickers')}</a><a class="btn s" href="checkout.html">Cart (<span id="cc">0</span>)</a></div></header>`);
 document.body.insertAdjacentHTML('beforeend',`<footer><div class="wrap">${esc(S.store_name)} · ${esc(S.contact)} · <a href="admin.html">Admin</a></div></footer>`);
 cart.set(cart.get());
}
// "Only 5 left!" text + threshold are editable in Admin > Settings
const tag=p=>p.stock<=0?'<span class="tag out">Sold out</span>':p.stock<=+(S.low_stock_threshold||5)?`<span class="tag low">${esc((S.low_stock_text||'Only {n} left!').replace('{n}',p.stock))}</span>`:p.badge?`<span class="tag">${esc(p.badge)}</span>`:'';
const off=p=>p.compare_price>p.price?Math.round(100-p.price/p.compare_price*100):0;
const price=p=>`<b>${money(p.price)}</b> ${p.compare_price>p.price?`<s>${money(p.compare_price)}</s>`:''}`;
const card=p=>`<a class="card" href="product.html?id=${p.id}"><img class="stk" loading="lazy" src="${esc(p.images?.[0]||'')}" alt="${esc(p.name)}">${tag(p)}<h3>${esc(p.name)}</h3><div class="price">${price(p)}</div></a>`;
