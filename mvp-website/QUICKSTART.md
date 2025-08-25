# 🚀 Quick Start Guide - DEFIMON MVP Website

## Prerequisites

- **Node.js** 18+ (Download from [nodejs.org](https://nodejs.org))
- **npm** (comes with Node.js)

## Quick Start

### Option 1: Automated Script (Recommended)

```bash
# Navigate to the project directory
cd mvp-website

# Make the script executable (if not already)
chmod +x start.sh

# Run the start script
./start.sh
```

### Option 2: Manual Steps

```bash
# Navigate to the project directory
cd mvp-website

# Install dependencies
npm install

# Start development server
npm run dev
```

## Access the Website

Once the server starts, open your browser and navigate to:
**http://localhost:3000**

## Features You'll See

### 🎨 Visual Elements
- **3D Particle Background**: Constellation-like particles moving in 3D space
- **Glass Morphism**: Modern glass-like UI elements with blur effects
- **Smooth Animations**: Framer Motion powered animations
- **Gradient Text**: Beautiful gradient text effects

### 📱 Sections
1. **Hero Section**: Main landing with animated background
2. **Video Hero**: Interactive video placeholder with controls
3. **Features**: 8 key features with icons and descriptions
4. **Networks**: Supported blockchain networks (50+)
5. **Analytics Preview**: Advanced analytics capabilities
6. **Footer**: Links and social media

### 🎯 Interactive Elements
- **Navigation**: Responsive header with dropdown menu
- **Video Controls**: Play/pause and mute buttons
- **Hover Effects**: Scale and color transitions
- **Scroll Animations**: Elements animate as you scroll

## Customization

### Change Colors
Edit `tailwind.config.js`:
```javascript
colors: {
  primary: {
    500: '#your-color', // Change primary color
  }
}
```

### Update Content
- **Hero Text**: `app/page.tsx` (lines 25-30)
- **Features**: `components/Features.tsx` (lines 15-60)
- **Networks**: `components/Networks.tsx` (lines 8-50)

### Modify 3D Particles
Edit `components/ParticleField.tsx`:
- Change particle count (line 8)
- Adjust movement speed (lines 40-42)
- Modify colors (line 48)

## Troubleshooting

### Common Issues

**Port 3000 already in use:**
```bash
# Kill the process using port 3000
lsof -ti:3000 | xargs kill -9
```

**Dependencies not installing:**
```bash
# Clear npm cache
npm cache clean --force
# Reinstall
rm -rf node_modules package-lock.json
npm install
```

**Build errors:**
```bash
# Check TypeScript errors
npx tsc --noEmit
```

## Performance Tips

- The 3D particles are optimized for performance
- Images are lazy-loaded
- Animations use hardware acceleration
- CSS is purged for production builds

## Deployment

### Vercel (Recommended)
1. Push to GitHub
2. Connect to Vercel
3. Deploy automatically

### Build for Production
```bash
npm run build
npm run start
```

---

**🎉 Your DEFIMON MVP website is ready!**
