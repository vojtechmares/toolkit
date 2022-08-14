# CI Toolkit

Docker image containing all the smart stuff.

## Usage

Do not forget that the image is inside a private registry and requires authentication.

### GitLab CI

```yaml
# .gitlab-ci.yml

default:
  image: registry.mareshq.com/mareshq/ci-toolkit:latest

# ...
```
