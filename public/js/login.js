function toggleForms() {
    var loginForm = document.getElementById('loginForm');
    var registerForm = document.getElementById('registerForm');
    var loginLink = document.getElementById('loginLink');
    var registerLink = document.getElementById('registerLink');

    if (loginForm.classList.contains('active')) {
        loginForm.classList.remove('active');
        registerForm.classList.add('active');
        loginLink.classList.remove('active');
        registerLink.classList.add('active');
    } else {
        loginForm.classList.add('active');
        registerForm.classList.remove('active');
        loginLink.classList.add('active');
        registerLink.classList.remove('active');
    }
}