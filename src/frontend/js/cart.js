// frontend/js/cart.js
const API_URL = "http://localhost:8080/api/cart";
const token = localStorage.getItem('token');

if (!token) {
  alert("Debes iniciar sesión antes de acceder al carrito");
  window.location.href = "login.html";
}

async function loadCart() {
  try {
    const res = await fetch(API_URL, {
      headers: { Authorization: `Bearer ${token}` }
    });

    const items = await res.json();
    console.log("🛍️ Carrito recibido:", items);

    const cartContainer = document.getElementById("cartItems");
    cartContainer.innerHTML = "";

    if (!items || items.length === 0) {
      cartContainer.innerHTML = "<p>Tu carrito está vacío 🛒</p>";
      document.getElementById("cartTotal").textContent = "$0";
      return;
    }

    let total = 0;
    items.forEach(item => {
      const product = item.product;
      if (!product) return;

      const subtotal = product.price * item.quantity;
      total += subtotal;

      const div = document.createElement("div");
      div.className = "product";
      div.innerHTML = `
        <img src="${product.image}" alt="${product.name}">
        <h3>${product.name}</h3>
        <p>Precio: $${product.price}</p>
        <p>Cantidad: ${item.quantity}</p>
        <button class="btn" onclick="removeFromCart(${product.id})">❌ Quitar</button>
      `;
      cartContainer.appendChild(div);
    });

    document.getElementById("cartTotal").textContent = `$${total.toFixed(2)}`;
  } catch (err) {
    console.error("❌ Error al cargar el carrito:", err);
    alert("Error al cargar el carrito");
  }
}

async function removeFromCart(productId) {
  try {
    const res = await fetch(`${API_URL}/${productId}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${token}` }
    });

    const data = await res.json();
    alert(data.message);
    loadCart();
  } catch (err) {
    console.error("❌ Error al eliminar producto:", err);
  }
}

async function checkout() {
  alert("✅ Simulación de pago completada. ¡Gracias por tu compra!");
  // Aquí podrías limpiar el carrito en backend si lo deseas
}

loadCart();