## tailscale-aws

### Templates

### Contributing

Run the lint utilities to ensure the CloudFormation/YAML stays tidy

```
# Once per project
python3 -m venv ./venv
pip install -r requirements.txt

# Once per session
. ./venv/bin/activate

# When you want to check
make lint
```
