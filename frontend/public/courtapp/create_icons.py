from PIL import Image
import os

def create_icons():
    sizes = {
        'favicon-16x16.png': 16,
        'favicon-32x32.png': 32,
        'apple-touch-icon.png': 180,
        'android-chrome-192x192.png': 192,
        'android-chrome-512x512.png': 512
    }
    
    for logo_file in ['logolx_dark.png', 'logolx_light.png']:
        if os.path.exists(logo_file):
            img = Image.open(logo_file)
            
            prefix = 'dark-' if 'dark' in logo_file else 'light-'
            
            for filename, size in sizes.items():
                output_name = prefix + filename
                resized = img.resize((size, size), Image.Resampling.LANCZOS)
                resized.save(output_name)
                print(f'Created: {output_name} ({size}x{size})')
    
    dark_img = Image.open('logolx_dark.png')
    dark_img.resize((32, 32), Image.Resampling.LANCZOS).save('favicon.ico', format='ICO', sizes=[(32, 32), (16, 16)])
    print('Created: favicon.ico')

if __name__ == '__main__':
    create_icons()
    print('All icons created successfully!')
