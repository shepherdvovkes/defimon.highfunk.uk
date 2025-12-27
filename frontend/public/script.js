document.addEventListener('DOMContentLoaded', function() {
    const navbar = document.querySelector('.navbar');
    const hamburger = document.querySelector('.hamburger');
    const mobileMenu = document.querySelector('.mobile-menu');
    const mobileNavLinks = document.querySelectorAll('.mobile-nav-links a');
    let lastScroll = 0;

    // Hamburger menu toggle
    if (hamburger && mobileMenu) {
        hamburger.addEventListener('click', function() {
            hamburger.classList.toggle('active');
            mobileMenu.classList.toggle('active');
            document.body.style.overflow = mobileMenu.classList.contains('active') ? 'hidden' : '';
        });

        // Close menu when clicking on a link or button
        mobileNavLinks.forEach(link => {
            link.addEventListener('click', function() {
                hamburger.classList.remove('active');
                mobileMenu.classList.remove('active');
                document.body.style.overflow = '';
            });
        });

        const mobileCtaButton = document.querySelector('.mobile-cta-button');
        if (mobileCtaButton) {
            mobileCtaButton.addEventListener('click', function() {
                hamburger.classList.remove('active');
                mobileMenu.classList.remove('active');
                document.body.style.overflow = '';
            });
        }

        // Close menu when clicking outside
        document.addEventListener('click', function(event) {
            const isClickInsideNav = navbar.contains(event.target);
            if (!isClickInsideNav && mobileMenu.classList.contains('active')) {
                hamburger.classList.remove('active');
                mobileMenu.classList.remove('active');
                document.body.style.overflow = '';
            }
        });
    }

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
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Animate fade-in-up elements
    document.querySelectorAll('.fade-in-up').forEach(el => {
        observer.observe(el);
    });

    const animateElements = document.querySelectorAll('.feature-card, .step, .screenshot-item, .tech-item, .advantage-card-new, .ai-model-card');
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

    const ctaButtons = document.querySelectorAll('.primary-button, .secondary-button, .cta-button, .mobile-cta-button');
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

    // Contact form handling
    const contactForm = document.getElementById('contactForm');
    const formMessage = document.getElementById('formMessage');

    if (contactForm) {
        contactForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = new FormData(contactForm);
            const data = {
                name: formData.get('name'),
                email: formData.get('email'),
                phone: formData.get('phone'),
                subject: formData.get('subject'),
                message: formData.get('message')
            };

            // Show loading state
            const submitButton = contactForm.querySelector('button[type="submit"]');
            const originalText = submitButton.innerHTML;
            submitButton.disabled = true;
            submitButton.innerHTML = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" style="animation: spin 1s linear infinite;"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" stroke-dasharray="31.416" stroke-dashoffset="31.416"><animate attributeName="stroke-dasharray" dur="2s" values="0 31.416;15.708 15.708;0 31.416;0 31.416" repeatCount="indefinite"/><animate attributeName="stroke-dashoffset" dur="2s" values="0;-15.708;-31.416;-31.416" repeatCount="indefinite"/></circle></svg> Відправка...';

            // Simulate form submission (replace with actual API call)
            try {
                // Here you would make an actual API call to your backend
                // For now, we'll simulate a successful submission
                await new Promise(resolve => setTimeout(resolve, 1500));

                // Show success message
                formMessage.className = 'form-message success';
                formMessage.textContent = 'Дякуємо! Ваше повідомлення відправлено. Ми зв\'яжемося з вами найближчим часом.';
                formMessage.style.display = 'block';

                // Reset form
                contactForm.reset();

                // Scroll to message
                formMessage.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

                // Hide message after 5 seconds
                setTimeout(() => {
                    formMessage.style.display = 'none';
                }, 5000);

            } catch (error) {
                // Show error message
                formMessage.className = 'form-message error';
                formMessage.textContent = 'Помилка відправки. Будь ласка, спробуйте ще раз або зв\'яжіться з нами безпосередньо.';
                formMessage.style.display = 'block';

                // Scroll to message
                formMessage.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            } finally {
                // Reset button
                submitButton.disabled = false;
                submitButton.innerHTML = originalText;
            }
        });
    }

    // Add spin animation for loading spinner
    const style = document.createElement('style');
    style.textContent = `
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
    `;
    document.head.appendChild(style);

    // Initialize Lucide icons
    if (typeof lucide !== 'undefined') {
        lucide.createIcons();
    } else {
        // Fallback: retry after a short delay if Lucide hasn't loaded yet
        setTimeout(() => {
            if (typeof lucide !== 'undefined') {
                lucide.createIcons();
            }
        }, 100);
    }

    // Parallax effect (disabled on mobile for performance)
    if (window.innerWidth > 768) {
        let ticking = false;
        
        function updateParallax() {
            const scrolled = window.pageYOffset;
            const parallaxElements = document.querySelectorAll('.parallax-item, .parallax-text, .parallax-image, .parallax-bg');
            
            parallaxElements.forEach(element => {
                const rect = element.getBoundingClientRect();
                const elementTop = rect.top + scrolled;
                const windowHeight = window.innerHeight;
                
                // Check if element is in viewport
                if (rect.bottom >= -100 && rect.top <= windowHeight + 100) {
                    const speed = parseFloat(element.getAttribute('data-speed')) || 0.5;
                    const scrolledPast = scrolled - elementTop + windowHeight;
                    const yPos = -scrolledPast * speed;
                    
                    if (element.classList.contains('parallax-bg')) {
                        element.style.transform = `translateY(${yPos * 0.3}px)`;
                    } else if (element.classList.contains('parallax-text')) {
                        element.style.transform = `translateY(${yPos * 0.2}px)`;
                    } else if (element.classList.contains('parallax-image')) {
                        element.style.transform = `translateY(${yPos * 0.4}px)`;
                    } else {
                        element.style.transform = `translateY(${yPos}px)`;
                    }
                }
            });
            
            ticking = false;
        }
        
        function requestTick() {
            if (!ticking) {
                window.requestAnimationFrame(updateParallax);
                ticking = true;
            }
        }
        
        window.addEventListener('scroll', requestTick, { passive: true });
        window.addEventListener('resize', requestTick);
        
        // Initial parallax update
        updateParallax();
    }
});
