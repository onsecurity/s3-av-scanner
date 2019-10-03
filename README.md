# s3-av-scanner

Anti-virus scanning (using clamav) files on an s3 bucket/several s3 buckets in a directory.

## Getting Started

Build the image

```
cd s3-av-scanner
sudo docker build -t myimage/name .
sudo docker run -d myimage/name
sudo docker run -e AWS_ACCESS_KEY_ID=mykey -e AWS_SECRET_ACCESS_KEY=mysecret -e AWS_DEFAULT_REGION=eu-west-2 -e S3_FILES_DIRECTORY=/files/
```

## Environment variables

Review the top of `Dockerfile` for the list of environment variables.

## Authors

* **Tom Lindley** - *Development* - [OnSecurity](https://www.onsecurity.co.uk/)

## License

This project is licensed under the GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details.