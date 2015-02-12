# Usage

## Inner Pipe

```html
<script src="framepipe.js"></script>
<script>
  var inside = new FramePipe(parent, 'WistiaVideo');
  inside.listen('greetingListener', function(data) {
    if (data === 'hey') {
      inside.post('hi');
    }
  });
</script>
```

## Outer Pipe

```html
<script src="framepipe.js"></script>
<script>
  FramePipe.onFind('WistiaVideo', function(pipe) {
    pipe.post('hey');
    greetingAcknowledged = false;
    pipe.listen('greetingListener', function(data) {
      if (data === 'hi') {
        greetingAcknowledged = true;
      }
    });
  });
</script>
```

# Compiling and Running Specs

Just run `foreman start` in the framepipe directory. You'll need the foreman
ruby gem, python, and coffeescript installed locally.

Also, add this line to your /etc/hosts so that specs can test CORS properly.

    127.0.0.1 differenthost.dev

Then you can access specs at http://localhost:8454/SpecRunner.html.

# Known Issues

- Specs sometimes fail due to some race condition when accessing
  frame.contentWindow before CORS allows it.
- Still many TODOs listed in code.
- Need to test the Usage examples
