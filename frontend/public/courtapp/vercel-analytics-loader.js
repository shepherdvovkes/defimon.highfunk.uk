// Loader for Vercel Analytics in static HTML
(function() {
    // Create a simple module loader for CommonJS
    var module = { exports: {} };
    var exports = module.exports;
    
    // Load the analytics script
    var script = document.createElement('script');
    script.src = 'vercel-analytics.js';
    script.onload = function() {
        // The script will populate module.exports
        // We need to access it after it loads
        setTimeout(function() {
            if (module.exports && typeof module.exports.inject === 'function') {
                module.exports.inject();
            } else if (typeof inject === 'function') {
                inject();
            }
        }, 100);
    };
    document.head.appendChild(script);
})();

