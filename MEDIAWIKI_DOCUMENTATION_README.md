# DEFIMON Project MediaWiki Documentation

This directory contains comprehensive MediaWiki documentation for the entire DEFIMON project, including all major components, architecture, and technical specifications.

## 📁 Documentation Files

### Main Documentation
- **`DEFIMON_PROJECT_DOCUMENTATION.wiki`** - Complete project documentation in MediaWiki format
- **`DEFIMON_PROJECT_INDEX.wiki`** - Comprehensive index and navigation structure
- **`DEFIMON_TEMPLATES.wiki`** - Reusable templates for consistent formatting

### PDF Architectural Documents
The main architectural documents are referenced from the `/pdfs` folder:
- **`defimon_architecture_overleaf.pdf`** - Primary architecture overview
- **`defimon_architecture_overleaf-2.pdf`** - Extended architecture overview

## 🚀 How to Import into MediaWiki

### Method 1: Manual Import via Special:Import

1. **Access MediaWiki Admin Panel**
   - Navigate to `Special:Import` in your MediaWiki installation
   - Ensure you have import permissions

2. **Import Main Documentation**
   - Upload `DEFIMON_PROJECT_DOCUMENTATION.wiki`
   - Set target namespace (recommended: `Project:`)
   - Import with full history

3. **Import Index and Templates**
   - Upload `DEFIMON_PROJECT_INDEX.wiki`
   - Upload `DEFIMON_TEMPLATES.wiki`
   - Set appropriate namespaces

4. **Upload PDF Documents**
   - Navigate to `Special:Upload`
   - Upload both PDF files from the `/pdfs` folder
   - Set appropriate categories and descriptions

### Method 2: Command Line Import (Advanced)

```bash
# Using MediaWiki maintenance scripts
cd /path/to/mediawiki/maintenance

# Import main documentation
php importTextFile.php --user=Admin --namespace=100 DEFIMON_PROJECT_DOCUMENTATION.wiki

# Import index
php importTextFile.php --user=Admin --namespace=100 DEFIMON_PROJECT_INDEX.wiki

# Import templates
php importTextFile.php --user=Admin --namespace=10 DEFIMON_TEMPLATES.wiki
```

### Method 3: Database Direct Import

```sql
-- Insert main documentation page
INSERT INTO page (page_namespace, page_title, page_is_redirect, page_is_new, page_random, page_touched, page_links_updated, page_latest, page_len, page_content_model, page_lang)
VALUES (100, 'DEFIMON_PROJECT_DOCUMENTATION', 0, 0, RAND(), NOW(), NOW(), 1, 0, 'wikitext', 'en');

-- Insert revision
INSERT INTO revision (rev_page, rev_text_id, rev_comment, rev_user, rev_user_text, rev_timestamp, rev_len, rev_parent_id, rev_sha1, rev_content_model, rev_content_format)
VALUES (LAST_INSERT_ID(), 1, 'Initial import of DEFIMON documentation', 1, 'Admin', NOW(), 0, 0, '', 'wikitext', 'text/x-wiki');
```

## 🔧 MediaWiki Configuration Requirements

### Required Extensions
```php
// LocalSettings.php
$wgEnableUploads = true;
$wgFileExtensions[] = 'pdf';
$wgPdfInfo = '/usr/bin/pdfinfo';
$wgPdfRenderer = '/usr/bin/pdftotext';

// Enable categories
$wgUseCategoryLinks = true;

// Enable templates
$wgUseTemplateCache = true;

// Enable search
$wgSearchType = 'SearchMySQL'; // or appropriate search backend
```

### Namespace Configuration
```php
// Define custom namespaces
define('NS_PROJECT', 100);
define('NS_PROJECT_TALK', 101);

$wgExtraNamespaces[NS_PROJECT] = 'Project';
$wgExtraNamespaces[NS_PROJECT_TALK] = 'Project_talk';
```

### Upload Configuration
```php
// Allow PDF uploads
$wgFileExtensions[] = 'pdf';

// Set maximum upload size for PDFs
$wgMaxUploadSize = 50 * 1024 * 1024; // 50MB

// Configure PDF handling
$wgPdfInfo = '/usr/bin/pdfinfo';
$wgPdfRenderer = '/usr/bin/pdftotext';
```

## 📚 Documentation Structure

### Main Documentation (`DEFIMON_PROJECT_DOCUMENTATION.wiki`)
- **Project Overview** - Complete project description and features
- **System Architecture** - Detailed architecture layers and infrastructure pools
- **Technology Stack** - Complete technology breakdown by component
- **Supported Blockchains** - All supported networks with priorities
- **API Documentation** - Complete API endpoints and usage
- **Deployment Guides** - Local development and production deployment
- **Performance Characteristics** - Benchmarks and system requirements

### Index (`DEFIMON_PROJECT_INDEX.wiki`)
- **Quick Navigation** - Fast access to key sections
- **Documentation Categories** - Organized by topic and function
- **Project Structure Overview** - High-level component breakdown
- **Quick Reference** - Ports, URLs, and system requirements
- **External Resources** - Links to official resources

### Templates (`DEFIMON_TEMPLATES.wiki`)
- **Information Boxes** - Project, service, and blockchain info boxes
- **Navigation Templates** - Breadcrumbs, related pages, TOC
- **Code Block Templates** - Command line, configuration, API endpoints
- **Status Templates** - Service status, system status, alerts
- **Performance Templates** - Metrics, benchmarks, deployment status

## 🎯 Key Features

### Comprehensive Coverage
- **Complete Project Documentation** - All aspects of the DEFIMON platform
- **Multi-Blockchain Support** - Ethereum, Cosmos, Polkadot, and more
- **Infrastructure Details** - Google Cloud, Hetzner, Kubernetes
- **Technology Stack** - Frontend, backend, AI/ML, blockchain
- **Deployment Guides** - Multiple deployment scenarios and environments

### MediaWiki Integration
- **Proper Formatting** - Uses MediaWiki syntax and formatting
- **Internal Links** - Cross-references between documentation sections
- **Categories** - Proper categorization for easy navigation
- **Templates** - Reusable components for consistent formatting
- **Media Integration** - PDF documents as main architectural references

### Navigation & Search
- **Structured Navigation** - Logical flow through documentation
- **Quick Reference** - Fast access to key information
- **Cross-References** - Links between related sections
- **Search Optimization** - Proper categorization and keywords

## 🔍 Post-Import Tasks

### 1. Verify Import
- Check all pages imported correctly
- Verify internal links work properly
- Test template functionality
- Confirm PDF uploads are accessible

### 2. Configure Search
- Rebuild search index
- Test search functionality
- Verify category searches work

### 3. Set Permissions
- Configure access permissions
- Set up user groups if needed
- Test access from different user levels

### 4. Customize Appearance
- Adjust MediaWiki skin if desired
- Configure navigation menus
- Set up custom CSS if needed

## 📖 Usage Examples

### Viewing Documentation
1. Navigate to the main documentation page
2. Use the index for quick navigation
3. Follow internal links to explore topics
4. Use search to find specific information

### Using Templates
1. Copy template code from the templates page
2. Customize parameters for your use case
3. Paste into new or existing pages
4. Update content as needed

### Adding New Content
1. Create new pages using MediaWiki syntax
2. Use appropriate templates for consistency
3. Link to existing documentation
4. Add proper categories

## 🛠️ Maintenance

### Regular Updates
- Update documentation when project changes
- Add new features and components
- Update performance metrics and benchmarks
- Maintain link validity

### Version Control
- Keep MediaWiki files in version control
- Tag releases with documentation versions
- Maintain change logs for major updates

### Backup
- Regular backups of MediaWiki database
- Export documentation pages periodically
- Backup uploaded files and media

## 🆘 Troubleshooting

### Common Issues
- **Import Failures** - Check file permissions and MediaWiki configuration
- **Template Errors** - Verify template syntax and parameters
- **Link Issues** - Check internal link formatting
- **PDF Display** - Verify PDF extension configuration

### Support Resources
- MediaWiki documentation: https://www.mediawiki.org/wiki/Documentation
- DEFIMON project repository: https://github.com/your-username/defimon.highfunk.uk
- Project documentation: https://docs.defimon.com

## 📄 License

This documentation is provided under the MIT License, same as the main DEFIMON project.

---

**Note**: This documentation is designed to be imported into a MediaWiki installation. The `.wiki` files contain MediaWiki markup syntax and should be imported rather than viewed as plain text files.
