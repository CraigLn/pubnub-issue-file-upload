# pubnub-issue-file-upload

This is a sample application that reproduces an issue we're seeing with slow file uploads to AWS S3 instances when making multipart requests using a URLSession configured with [background](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1407496-background) vs [default](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411560-default).

![Example of Timings](/docs/file-upload-final-timings.png)
