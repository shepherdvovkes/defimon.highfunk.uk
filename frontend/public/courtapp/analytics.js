// Vercel Analytics
(function() {
    if (typeof window !== 'undefined' && window.location.hostname !== 'localhost') {
        // Only load analytics in production
        const script = document.createElement('script');
        script.src = 'https://va.vercel-scripts.com/v1/script.debug.js';
        script.defer = true;
        document.head.appendChild(script);
    }
})();

