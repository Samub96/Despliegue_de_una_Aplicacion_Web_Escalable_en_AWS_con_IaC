// frontend/js/cart.js
const API_URL = "http://localhost:8080/api/cart";
const token = localStorage.getItem('token');

if (!token) {
  alert("Debes iniciar sesión antes de acceder al carrito");
  window.location.href = "login.html";
}

async function loadCart() {
  const cartArea = document.getElementById('cartArea');
  try {
    const items = await apiFetch('/cart', { headers: authHeaders() });
    if (!items || items.length === 0) {
      cartArea.innerHTML = '<p>Tu carrito está vacío.</p>';
      document.getElementById('checkoutArea').innerHTML = '';
      return;
    }

    let rows = items.map(i => {
      const p = i.Product;
      const line = Number(p.price) * i.quantity;
      return `<tr>
        <td>${escapeHtml(p.name)}</td>
        <td>$${Number(p.price).toFixed(2)}</td>
        <td>${i.quantity}</td>
        <td>$${line.toFixed(2)}</td>
        <td><button class="btn" onclick="removeItem(${i.id})">Quitar</button></td>
      </tr>`;
    }).join('');

    const total = items.reduce((s,i)=> s + (i.Product.price * i.quantity), 0);
    cartArea.innerHTML = `
      <table style="width:100%;border-collapse:collapse">
        <thead><tr><th>Producto</th><th>Precio</th><th>Cantidad</th><th>Total</th><th></th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
      <h3>Total: $${Number(total).toFixed(2)}</h3>
    `;
    document.getElementById('checkoutArea').innerHTML = `<button class="btn" onclick="checkout()">Pagar</button>`;
  } catch (err) {
    console.error('Error cargando carrito', err);
    if (err && (err.error === 'no auth header' || err.error === 'invalid token')) {
      cartArea.innerHTML = '<p>Debes <a href="login.html">iniciar sesión</a> para ver el carrito.</p>';
    } else {
      cartArea.innerHTML = '<p>Error cargando carrito.</p>';
    }
  }
}

async function removeItem(id) {
  if (!confirm('¿Quitar este item del carrito?')) return;
  try {
    await apiFetch('/cart/remove', { method: 'POST', headers: authHeaders(), body: { id } });
    await loadCart();
  } catch (err) {
    console.error('Error al quitar item', err);
    alert('No se pudo quitar el item.');
  }
}

async function checkout() {
  if (!confirm('Confirmar pago simulado del carrito?')) return;
  try {
    const res = await apiFetch('/checkout/process', { method: 'POST', headers: authHeaders() });
    alert('Pago simulado correcto. Order ID: ' + res.orderId + ' — Total: $' + Number(res.total).toFixed(2));
    await loadCart();
  } catch (err) {
    console.error('Error en checkout', err);
    alert('Error en checkout: ' + (err.error || JSON.stringify(err)));
  }
}

function escapeHtml(str){
  if (!str) return '';
  return String(str).replace(/[&<>"']/g, s => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[s]);
}

window.addEventListener('load', loadCart);
