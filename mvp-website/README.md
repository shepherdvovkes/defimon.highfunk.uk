# DEFIMON MVP Website

A modern, responsive MVP website for the DEFIMON DeFi Analytics Platform built with Next.js, TypeScript, and Tailwind CSS.

## 🚀 Features

- **Modern Design**: Clean, professional design with glass morphism effects
- **3D Particle Background**: Interactive constellation-like particles using Three.js
- **Video Hero Section**: Attractive video placeholder with controls
- **Responsive Layout**: Fully responsive design for all devices
- **Smooth Animations**: Framer Motion animations for enhanced UX
- **Performance Optimized**: Lightweight and fast loading
- **SEO Ready**: Meta tags and structured data

## 🛠️ Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Animations**: Framer Motion
- **3D Graphics**: Three.js with React Three Fiber
- **Icons**: Lucide React
- **Fonts**: Inter (Google Fonts)

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mvp-website
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Run the development server**
   ```bash
   npm run dev
   ```

4. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 🏗️ Project Structure

```
mvp-website/
├── app/
│   ├── globals.css          # Global styles and animations
│   ├── layout.tsx           # Root layout with metadata
│   └── page.tsx             # Main page component
├── components/
│   ├── Header.tsx           # Navigation header
│   ├── VideoHero.tsx        # Video hero section
│   ├── Features.tsx         # Features showcase
│   ├── Networks.tsx         # Supported networks
│   ├── Footer.tsx           # Footer with links
│   └── ParticleField.tsx    # 3D particle background
├── public/                  # Static assets
├── package.json             # Dependencies and scripts
├── tailwind.config.js       # Tailwind configuration
├── next.config.js           # Next.js configuration
└── tsconfig.json            # TypeScript configuration
```

## 🎨 Design Features

### Color Scheme
- **Primary**: Blue gradient (#3b82f6 to #1d4ed8)
- **Accent**: Purple gradient (#d946ef to #a21caf)
- **Background**: Dark theme (#0f172a to #1e293b)
- **Text**: White and gray variations

### Animations
- **Page Transitions**: Smooth fade-in animations
- **Hover Effects**: Scale and color transitions
- **Scroll Animations**: Intersection Observer based
- **3D Particles**: Constellation-like movement

### Components
- **Glass Morphism**: Backdrop blur effects
- **Gradient Text**: CSS gradient text effects
- **Responsive Grid**: CSS Grid layouts
- **Interactive Elements**: Hover and focus states

## 📱 Responsive Design

The website is fully responsive with breakpoints:
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

## 🚀 Deployment

### Vercel (Recommended)
1. Push your code to GitHub
2. Connect your repository to Vercel
3. Deploy automatically

### Netlify
1. Build the project: `npm run build`
2. Upload the `out` folder to Netlify

### Manual Deployment
```bash
npm run build
npm run start
```

## 🔧 Customization

### Colors
Edit `tailwind.config.js` to customize the color scheme:
```javascript
colors: {
  primary: {
    500: '#your-color',
    // ... other shades
  }
}
```

### Content
Update the content in each component file:
- `components/Features.tsx` - Feature descriptions
- `components/Networks.tsx` - Network lists
- `app/page.tsx` - Hero text and CTAs

### 3D Particles
Modify `components/ParticleField.tsx` to adjust:
- Particle count
- Movement speed
- Colors and sizes
- Constellation patterns

## 📊 Performance

- **Lighthouse Score**: 95+ (Performance, Accessibility, Best Practices, SEO)
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1

## 🔍 SEO

- Meta tags for social sharing
- Structured data markup
- Semantic HTML
- Optimized images
- Fast loading times

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

---

**Built with ❤️ for the DeFi community**
