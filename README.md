# action-lambda-python-zip
GitHub Action to make zip deployment to AWS Lambda with requirements in a separate layer.

## Description
This action automatically looks for lambda configurations, installs requirements, zips and deploys the code including the dependencies as a separate layer.

#### Python 3.8 is supported

### Pre-requisites
In order for the Action to have access to the code, you must use the `actions/checkout@master` job before it. 

### Structure
- Lambda code should be `lambda_function.py`** unless you want to have a customized file name.
- **Dependencies must be stored in a `requirements.txt`**

### Environment variables
Storing credentials as secret is strongly recommended. 

- **AWS Credentials**  
    `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` are required.

### Inputs
- `lambda_function_prefix`  
    The Lambda function name prefix, e.g. `scopingAPI`.
- `lambda_function_suffix`
    The suffix of the lambda function, can specify env here e.g. `dev`.
- `lambda_configs_path`
    The path to the lambda configurations, e.g. `aws_lambda/functions/`
    
### Output
- `all_functions`
    String containing all lambda function urls that were created

### Lambda configuration
Each lambda function should have its own directory containing a `config.yml` and `Pipfile`.

```yaml
entrypoint: 'NAME_OF_FUNCTION'
settings:
  role: 'ROLE ARN'
  memory: '512'
  timeout: '300'
  runtime: 'python3.8'
  handler: 'LAMBDA_FUNCTION_HANDLER'
```

### Example Workflow
```yaml
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@master
    - name: Deploy code to Lambda
      uses: klydo/action-lambda-python-zip@v2.0
      with:
        lambda_function_prefix: 'scopingAPI'
        lambda_function_suffix: ${{ github.ref }}
        lambda_configs_path: 'aws_lambda/functions/'
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: ${{ secrets.AWS_REGION }}
```
