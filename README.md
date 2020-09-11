# Cordova plugin for the Adyen SDK

## Installation

Latest stable version from npm:
```
$ cordova plugin add cordova-plugin-adyen-sdk
```

`Adyen.js` is brought in automatically.
It adds a global `Adyen` object which you can use to interact with the plugin.

## Usage

Check the [demo code](demo/index.html) for all the tricks in the book, or read on for some copy-pasteable samples.

Make sure to wait for `deviceready` before using any of these functions.

## API

### `selection`
Use selection feedback generators to indicate a change in selection.

```js
Adyen.foo();
```
