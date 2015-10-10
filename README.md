# hubot-observe

A hubot script that checks a json resource and notifies the channel if something changed.

See [`src/observe.coffee`](src/observe.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-observe --save`

Then add **hubot-observe** to your `external-scripts.json`:

```json
[
  "hubot-observe"
]
```

## Example

![example](https://raw.githubusercontent.com/filipre/hubot-observe/master/example.png)

Following JSON could your app provide to notify your channel every time when someone registers for your app:

```json
{
  "text": "Newest user is foobar. There are 123 users."
}
```

To register hubot for that json, simply write

```
hubot observe:add http://url-to-the-json.com/
```

## Error Case

If the URL is not available (or does not provide a JSON with a text property), Hubot will try to access it two other times before notifying the user once (to prevent spam):

![error](https://raw.githubusercontent.com/filipre/hubot-observe/master/error.png)

## Commands


- `hubot observe[:help]`: Show commands
- `hubot observe:add <url> [interval=<interval>]`: Add a job that observes a json with an optional interval (default is minutely)
- `hubot observe:remove <url>`: Remove a job by url
- `hubot observe:list [all]`: List all jobs in the room (or of all rooms)
