# Changelog

All notable changes to the Linux Security Baseline InSpec profile will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Database security controls (PostgreSQL, MySQL, MongoDB)
- Kubernetes security controls
- Container runtime security validation
- Cloud-specific controls (AWS, Azure, GCP)
- Integration with external vulnerability databases

-----

## [1.0.0] - 2025-10-14

### Added

- Initial release of Linux Security Baseline profile
- 100 security controls across 5 categories:
  - Filesystem Security (10 controls)
  - User Management (15 controls)
  - Service Hardening (20 controls)
  - Network Security (20 controls)
  - Application Security (20 controls)
- Support for Ubuntu 20.04, 22.04, CentOS 8, Debian 11
- Comprehensive README with usage instructions
- TESTING.md guide for various testing scenarios
- Docker Compose test environment
- Multi-environment test script
- CI/CD integration examples for Jenkins, GitLab, Azure DevOps, GitHub Actions
- Waiver file system for exception management
- Custom input parameters for flexibility
- Helper library for reusable functions
- Quick Start guide for new users
- Contributing guidelines

### Security Controls Highlights

- SSH configuration hardening (Protocol 2, root login disabled, strong ciphers/MACs)
- File permission validation for sensitive system files
- User account security (no empty passwords, UID validation, password policies)
- Network hardening (IP forwarding, packet routing, firewall configuration)
- Service security (unnecessary services disabled, critical services running)
- Docker security configuration
- Web server security headers
- Mandatory Access Control (SELinux/AppArmor) validation
- Audit daemon configuration
- ASLR and exploit mitigation checks

### Documentation

- Complete API documentation for all controls
- Testing scenarios and examples
- CI/CD pipeline integration templates
- Troubleshooting guide
- Best practices documentation

### Infrastructure

- Docker-based test environment with 5 distributions
- Automated testing scripts
- Report generation in multiple formats (CLI, JSON, HTML)
- GitHub Actions workflow examples
- Jenkins, GitLab CI, and Azure DevOps templates

-----

## [0.9.0-beta] - 2025-10-01

### Added

- Beta release for community feedback
- Core filesystem and user management controls (50 controls)
- Basic documentation
- Local testing support

### Changed

- Refined control impact levels based on CIS Benchmark alignment
- Updated control descriptions for clarity

### Fixed

- SSH cipher validation now handles custom configurations
- File permission checks handle symbolic links correctly
- Service status checks compatible with systemd and init systems

-----

## [0.5.0-alpha] - 2025-09-15

### Added

- Alpha release for internal testing
- Initial set of 30 security controls
- Basic InSpec profile structure
- Local testing capabilities

### Known Issues

- Limited OS support (Ubuntu only)
- Some controls need refinement for edge cases
- Documentation incomplete

-----

## Version History Summary

|Version    |Date      |Controls|Features        |Status|
|-----------|----------|--------|----------------|------|
|1.0.0      |2025-10-14|100     |Full feature set|Stable|
|0.9.0-beta |2025-10-01|50      |Core controls   |Beta  |
|0.5.0-alpha|2025-09-15|30      |Basic profile   |Alpha |

-----

## Upgrade Guide

### Upgrading from 0.9.0-beta to 1.0.0

**Breaking Changes:**

- None. This release is fully backward compatible.

**New Features:**

- Additional 50 controls for network and application security
- Multi-environment testing support
- CI/CD integration examples
- Waiver system

**Migration Steps:**

```bash
# 1. Pull latest version
git pull origin main

# 2. Validate profile
inspec check .

# 3. Review new controls
cat controls/04_network_security.rb
cat controls/05_application_security.rb

# 4. Run with existing inputs (fully compatible)
inspec exec . --input-file inputs.yml

# 5. Update CI/CD pipelines if desired
# (See CI-CD-Integration-Examples.md)
```

### Upgrading from 0.5.0-alpha to 1.0.0

**Breaking Changes:**

- Control IDs renumbered for better organization
- Some control names changed for clarity

**Migration:**

- Review control mapping document: `docs/control-migration.md`
- Update any custom waivers with new control IDs
- Update CI/CD scripts referencing specific controls

-----

## Deprecation Notices

### Deprecated in 1.0.0

- None

### Planned Deprecations

- None currently planned

-----

## Security Advisories

### None

No security vulnerabilities have been identified in this profile. If you discover a security issue, please report it privately to security@example.com.

-----

## Contributors

### Core Team

- **Willem van Heemstra** - Initial work, architecture, and all controls - [Email](mailto:wvanheemstra@icloud.com)

### Community Contributors

We welcome contributions! See <CONTRIBUTING.md> for guidelines.

-----

## Release Process

### Versioning Strategy

**Major Version (X.0.0)**

- Breaking changes to control IDs or structure
- Significant architectural changes
- Major feature additions requiring migration

**Minor Version (1.X.0)**

- New controls added
- New features that are backward compatible
- Significant enhancements to existing controls

**Patch Version (1.0.X)**

- Bug fixes
- Documentation updates
- Minor improvements to existing controls

### Release Checklist

Before releasing a new version:

1. **Testing**
- [ ] All controls pass on supported platforms
- [ ] Multi-environment tests complete successfully
- [ ] No regressions in existing functionality
- [ ] New features tested in isolation and integration
1. **Documentation**
- [ ] CHANGELOG.md updated
- [ ] README.md reflects new features
- [ ] Version number updated in inspec.yml
- [ ] Migration guide written (if applicable)
1. **Quality**
- [ ] Code reviewed
- [ ] `inspec check .` passes without errors
- [ ] No TODOs or FIXMEs in production code
- [ ] Performance benchmarks acceptable
1. **Community**
- [ ] Release notes drafted
- [ ] Contributors acknowledged
- [ ] Announcement prepared

### How to Release

```bash
# 1. Update version in inspec.yml
vim inspec.yml  # Update version: 1.1.0

# 2. Update CHANGELOG.md
vim CHANGELOG.md  # Add release notes

# 3. Commit changes
git add inspec.yml CHANGELOG.md
git commit -m "Release version 1.1.0"

# 4. Create tag
git tag -a v1.1.0 -m "Version 1.1.0 - Description of changes"

# 5. Push to repository
git push origin main --tags

# 6. Create GitHub release
# Go to GitHub → Releases → Draft a new release
# - Tag: v1.1.0
# - Title: Linux Security Baseline v1.1.0
# - Description: Copy from CHANGELOG.md

# 7. Announce
# - Post to discussions
# - Update documentation site
# - Notify users via email/slack
```

-----

## Roadmap

### Version 1.1.0 (Q1 2026)

- Database security controls
- Container security enhancements
- Cloud provider specific controls
- Performance optimizations

### Version 1.2.0 (Q2 2026)

- Kubernetes security controls
- Integration with vulnerability databases
- Automated remediation suggestions
- Enhanced reporting dashboards

### Version 2.0.0 (Q3 2026)

- Major architecture refactoring
- Plugin system for custom controls
- Real-time monitoring integration
- Machine learning-based risk scoring

-----

## Support

### Supported Versions

|Version|Supported|Notes                      |
|-------|---------|---------------------------|
|1.0.x  |✅        |Current stable release     |
|0.9.x  |⚠️        |Beta - upgrade recommended |
|0.5.x  |❌        |Alpha - no longer supported|

### Getting Help

- **Documentation**: <README.md>, <TESTING.md>
- **Issues**: [GitHub Issues](https://github.com/yourusername/learning-inspec/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/learning-inspec/discussions)
- **Security**: Email security@example.com

-----

## License

This project is licensed under the MIT License - see the <LICENSE> file for details.

-----

**Maintained by**: Willem van Heemstra  
**Status**: Active Development  
**Last Updated**: October 14, 2025
