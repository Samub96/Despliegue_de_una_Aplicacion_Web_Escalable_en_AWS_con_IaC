const API_URL = 'http://localhost:8080/api';
const token = localStorage.getItem('token');

async function loadProducts() {
  const res = await fetch(`${API_URL}/products`);
  const data = await res.json();

  const container = document.getElementById('products');
  container.innerHTML = data.map(p => `
    <div class="product">
      <img src="${p.image}" alt="${p.name}">
      <h3>${p.name}</h3>
      <p>$${p.price}</p>
      <button onclick="addToCart(${p.id})">Agregar al carrito</button>
    </div>
  `).join('');
}

async function addToCart(productId) {
  if (!token) {
    alert('Debes iniciar sesión para agregar productos');
    return;
  }

  const res = await fetch(`${API_URL}/cart`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({ productId, quantity: 1 })
  });

  if (res.ok) {
    alert('Producto agregado al carrito 🛒');
  } else {
    alert('Error al agregar al carrito');
  }
}

loadProducts();