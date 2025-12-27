# LexApp Website

Professional business-style website for LexApp - a legal assistance application for court case management.

## Overview

This website showcases LexApp, a comprehensive mobile application that helps users manage court cases, prepare documents, and receive professional legal consultations.

## Features

- **Modern Design**: Clean, professional business-style layout with gradient accents
- **Responsive**: Fully responsive design that works on desktop, tablet, and mobile devices
- **Smooth Animations**: Intersection Observer API for scroll-based animations
- **Interactive Elements**: Smooth scrolling navigation and interactive UI components
- **Screenshot Gallery**: Horizontal scrollable gallery showcasing app screenshots
- **Professional Branding**: Uses official LexApp logos for consistent brand identity

## Structure

```
web/
├── index.html          # Main HTML file
├── styles.css          # CSS styles with responsive design
├── script.js           # JavaScript for interactions and animations
├── logolex_dark.png    # Main logo (dark version) for navbar
├── logolex_light.png   # Main logo (light version) for footer
├── logolx_dark.png     # App icon (dark version) for favicon
├── logolx_light.png    # App icon (light version)
└── README.md           # This file
```

## Sections

1. **Hero Section**: Eye-catching introduction with app overview and key statistics
2. **Features**: Six key features of the application with icons and descriptions
3. **How It Works**: Step-by-step guide showing the user journey
4. **Screenshots**: Gallery of app interface screenshots from mockups
5. **Tech Stack**: Technologies used in the application
6. **CTA Section**: Call-to-action for app downloads
7. **Footer**: Links and company information

## Technologies Used

- **HTML5**: Semantic markup
- **CSS3**: Modern styling with flexbox and grid
- **JavaScript (ES6+)**: Interactive features and animations
- **Google Fonts**: Inter font family for clean typography

## Branding

### Logos

- **logolex_dark.png**: Full "LEX" logo with dark background - used in navbar
- **logolex_light.png**: Full "LEX" logo with light/transparent background - used in footer
- **logolx_dark.png**: Compact "LX" icon - used for favicon and app icons
- **logolx_light.png**: Compact "LX" icon with light background

## Key Features

### Design Elements

- Gradient color scheme (Blue: #4A90E2 to #357ABD)
- Professional business aesthetic
- Card-based layout for features
- Smooth hover effects and transitions

### Functionality

- Smooth scroll navigation
- Scroll-based animations using Intersection Observer
- Draggable screenshot gallery
- Responsive navigation bar with blur effect
- Mobile-friendly hamburger menu (ready for implementation)

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest) - includes vendor prefixes for backdrop-filter
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Setup

1. Open `index.html` in a web browser
2. No build process or dependencies required
3. All assets are included in the web folder

## Customization

### Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --primary-color: #4A90E2;
    --primary-dark: #357ABD;
    --secondary-color: #2C3E50;
    /* ... */
}
```

### Content

- Edit text content directly in `index.html`
- Replace screenshot images in the mockups folder
- Update links in navigation and footer

## Screenshots Source

Screenshots are sourced from `../mockups/version2/images/` directory, showcasing:

- Welcome screen
- Authentication
- Case type selection
- Document upload
- Consultation interface
- Progress tracking
- Results and delivery

## Future Enhancements

- [ ] Add mobile hamburger menu
- [ ] Implement language switcher (Ukrainian/English)
- [ ] Add video demo section
- [ ] Integrate contact form
- [ ] Add testimonials section
- [ ] Implement dark mode toggle
- [ ] Add pricing section
- [ ] SEO optimization

## License

Part of the COURTAPP project.

## Contact

For more information about LexApp, visit the main repository or contact the development team.
