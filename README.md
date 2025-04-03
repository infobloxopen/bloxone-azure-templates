# Test
# Bloxone Azure Templates

## Getting Started
 
To prepare ARM templates for QA team use patch-for-qa.sh script from utils directory:
```
$ utils/patch-for-qa.sh accessPortal="" configServer="" notificationServer=""
```

To create zip archive use archive.sh script from utils directory:
```
$ utils/archive.sh imageOffer="" imagePublisher="" imageSku="" imageVersion="" trackingId=""
```

You can get `imageOffer`, `imagePublisher`, `imageSku` and `imageVersion` in your virtual machine offer.

You can get `trackingId` in your application offer.
