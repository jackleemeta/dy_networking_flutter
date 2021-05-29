# dy_networking

网络中心

## Usage

- 注册setHeader服务

```
NetClientConfig.fetchHeadersForbaseUrl = (String baseUrl) {
    switch (baseUrl) {
      case URLS.dev:
        return Future.value({"cookie": "PHPSESSID=xxxxx"});
        break;
      case URLS.production:
        return Future.value({"cookie": "PHPSESSID=xxxxx"});
        break;
    }
    return null;
  };
```


