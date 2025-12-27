document.addEventListener('DOMContentLoaded', function() {
    const navbar = document.querySelector('.navbar');
    let lastScroll = 0;

    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;

        if (currentScroll > 100) {
            navbar.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.boxShadow = 'none';
        }

        lastScroll = currentScroll;
    });

    const navLinks = document.querySelectorAll('.nav-links a');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const offsetTop = targetSection.offsetTop - 80;
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });

    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    const animateElements = document.querySelectorAll('.feature-card, .step, .screenshot-item, .tech-item');
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });

    const screenshotsSlider = document.querySelector('.screenshots-slider');
    if (screenshotsSlider) {
        let isDown = false;
        let startX;
        let scrollLeft;

        screenshotsSlider.addEventListener('mousedown', (e) => {
            isDown = true;
            screenshotsSlider.style.cursor = 'grabbing';
            startX = e.pageX - screenshotsSlider.offsetLeft;
            scrollLeft = screenshotsSlider.scrollLeft;
        });

        screenshotsSlider.addEventListener('mouseleave', () => {
            isDown = false;
            screenshotsSlider.style.cursor = 'grab';
        });

        screenshotsSlider.addEventListener('mouseup', () => {
            isDown = false;
            screenshotsSlider.style.cursor = 'grab';
        });

        screenshotsSlider.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();
            const x = e.pageX - screenshotsSlider.offsetLeft;
            const walk = (x - startX) * 2;
            screenshotsSlider.scrollLeft = scrollLeft - walk;
        });
    }

    const ctaButtons = document.querySelectorAll('.primary-button, .secondary-button, .cta-button');
    ctaButtons.forEach(button => {
        button.addEventListener('click', function() {
            const ripple = document.createElement('span');
            ripple.classList.add('ripple');
            this.appendChild(ripple);

            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            ripple.style.width = ripple.style.height = size + 'px';

            setTimeout(() => ripple.remove(), 600);
        });
    });

    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            if (href !== '#') {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    const offsetTop = target.offsetTop - 80;
                    window.scrollTo({
                        top: offsetTop,
                        behavior: 'smooth'
                    });
                }
            }
        });
    });
});
