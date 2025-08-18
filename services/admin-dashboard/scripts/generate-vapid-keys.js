#!/usr/bin/env node

const webpush = require('web-push');

console.log('🔑 Generating VAPID keys for push notifications...\n');

try {
    const vapidKeys = webpush.generateVAPIDKeys();
    
    console.log('✅ VAPID keys generated successfully!\n');
    console.log('📋 Add these keys to your .env file:\n');
    console.log(`PUSH_VAPID_PUBLIC_KEY=${vapidKeys.publicKey}`);
    console.log(`PUSH_VAPID_PRIVATE_KEY=${vapidKeys.privateKey}\n`);
    
    console.log('🔧 Configuration instructions:');
    console.log('1. Copy the keys above to your .env file');
    console.log('2. Make sure PUSH_SUBJECT is set to your email (e.g., mailto:admin@defimon.highfunk.uk)');
    console.log('3. Restart the admin dashboard service');
    console.log('4. Push notifications will be automatically enabled\n');
    
    console.log('⚠️  Security notes:');
    console.log('- Keep the private key secret and secure');
    console.log('- The public key can be shared safely');
    console.log('- Rotate keys periodically for security\n');
    
} catch (error) {
    console.error('❌ Failed to generate VAPID keys:', error.message);
    process.exit(1);
}
