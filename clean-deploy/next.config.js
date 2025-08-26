/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    domains: ['images.unsplash.com', 'via.placeholder.com'],
  },
  webpack: (config) => {
    config.externals = [...config.externals, { canvas: 'canvas' }];
    return config;
  },
  // Force cache busting
  generateBuildId: async () => {
    return `build-${Date.now()}`
  },
  // Disable static optimization for dynamic content
  experimental: {
    optimizeCss: false,
  },
}

module.exports = nextConfig
