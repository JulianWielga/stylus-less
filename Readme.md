## Installation

```bash
$ npm install stylus-less-plugin
```

## JavaScript API

 Below is an example of how to utilize stylus-less and stylus with the connect framework (or express).

```javascript
var connect = require('connect')
  , stylus = require('stylus')
  , plugin = require('stylus-less-plugin');

var server = connect();

function compile(str, path) {
  return stylus(str)
	.set('filename', path)
	.set('compress', true)
	.use(plugin());
}

server.use(stylus.middleware({
	src: __dirname
  , compile: compile
}));
```

## Stylus API

  To gain access to everything stylus-less has to offer, simply add:

  ```css
  importLess('pathTo.less')
  ```

## Testing

 You will first need to install the dependencies:

 ```bash
    $ npm install -d
 ```

 Run the automated test cases:

 ```bash
    $ npm test
 ```

## Contributors

### Less to stylus compilation
  - [Andrey Popp](https://github.com/andreypopp/less2stylus)

### Project skeleton from nib
  - [TJ Holowaychuk](https://github.com/tj) (Original Creator)
  - [Sean Lang](https://github.com/slang800) (Current Maintainer)
  - [Isaac Johnston](https://github.com/superstructor)
  - [Everyone Else](https://github.com/tj/nib/contributors)
