# Contributing to capistrano-sidekiq

We love pull requests from everyone. By participating in this project, you agree to abide by our code of conduct (coming soon).

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone git@github.com:your-username/capistrano-sidekiq.git`
3. Set up your development environment: `bundle install`
4. Create a feature branch: `git checkout -b my-new-feature`

## Making Changes

1. Make your changes
2. Add tests for your changes
3. Run the test suite: `bundle exec rake test`
4. Update documentation if necessary
5. Update CHANGELOG.md with your changes

## Code Style

- Follow Ruby community style guidelines
- Keep code simple and readable
- Add comments for complex logic
- Use meaningful variable and method names

## Testing

- Write tests for any new functionality
- Ensure all tests pass before submitting
- Test with different Ruby versions if possible
- Test with Docker: `bundle exec rake test`

## Submitting Changes

1. Push to your fork: `git push origin my-new-feature`
2. Create a pull request
3. Describe your changes in the PR description
4. Reference any related issues

## Pull Request Guidelines

- Keep PRs focused on a single feature or fix
- Update documentation for any changed behavior
- Add entries to CHANGELOG.md
- Ensure CI passes
- Be responsive to feedback

## Reporting Issues

- Use the GitHub issue tracker
- Check if the issue already exists
- Include reproduction steps
- Provide system information:
  - Ruby version
  - Capistrano version
  - Sidekiq version
  - Systemd version (if relevant)

## Development Setup

```bash
# Clone the repo
git clone https://github.com/seuros/capistrano-sidekiq.git
cd capistrano-sidekiq

# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run tests in Docker
docker build -t capistrano-sidekiq-test test/
docker run capistrano-sidekiq-test
```

## Release Process

Releases are managed by maintainers. The process is:

1. Update version in `lib/capistrano/sidekiq/version.rb`
2. Update CHANGELOG.md
3. Run tests
4. Build gem: `bundle exec rake build`
5. Release: `bundle exec rake release`

## Questions?

Feel free to open an issue for any questions about contributing.