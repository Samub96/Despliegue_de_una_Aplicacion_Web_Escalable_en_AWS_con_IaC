// Login y registro
document.getElementById && (function () {
  const loginForm = document.getElementById('loginForm');
  const regForm = document.getElementById('regForm');
  const message = document.getElementById('message');

  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const username = document.getElementById('loginUser').value.trim();
      const password = document.getElementById('loginPass').value.trim();
      try {
        const res = await apiFetch('/auth/login', { method: 'POST', body: { username, password }});
        setToken(res.token);
        message.style.color = 'green';
        message.innerText = 'Ingreso exitoso. Redirigiendo...';
        setTimeout(() => window.location = 'index.html', 700);
      } catch (err) {
        console.error('Error login', err);
        message.style.color = '#b00';
        message.innerText = (err && err.error) ? err.error : 'Error al iniciar sesión.';
      }
    });
  }

  if (regForm) {
    regForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const username = document.getElementById('regUser').value.trim();
      const password = document.getElementById('regPass').value.trim();
      try {
        await apiFetch('/auth/register', { method: 'POST', body: { username, password }});
        message.style.color = 'green';
        message.innerText = 'Usuario creado. Inicia sesión.';
      } catch (err) {
        console.error('Error registro', err);
        message.style.color = '#b00';
        message.innerText = (err && err.error) ? err.error : 'Error al registrar.';
      }
    });
  }
})();
