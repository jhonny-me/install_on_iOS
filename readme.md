## description

This is a bash script for install app into many iphones and android phones.

## dependency

- [mobiledevice](https://github.com/imkira/mobiledevice)
- [adb](https://developer.android.com/studio/command-line/adb.html)

## usage
Put `ios` file and your app in the same folder for install ipa to ihpone.
Put `and` file and your app in the same folder for install apk to android phone.

#### install

```
./ios install appname.ipa
./and install appname.apk
```
#### uninstall

```
./ios uninstall <yourapp's Identifier>
./and uninstall <yourapp's Identifier>
```
