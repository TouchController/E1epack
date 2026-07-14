# UniF-Logger

## Usage

Before it, you must tag yourself `unif.debug`.

And following is a log example.
```TXT
[0:1000] [INFO] (NAMESPACE) MESSAGE
```

- `[0:1000]` is the time of the game. It means that the log was printed at the time of 1000 on day 1 of the game.
- `[INFO]` is the level of the log. There are a total of 5 levels, ALL < DEBUG < INFO < WARN < ERROR.
- `(Namespace)` is the namespace of the logger.

After logging but logging of DEBUG, all logging will record into stoarge `unif.logger:logs`,
and there are also 4 stoarges: `unif.logger:debug_logs`, `unif.logger:info_logs`, `unif.logger:warn_logs`,
`unif.logger:error_logs`.

When the logs is going to be too big, it will auto delete the last log in logs.

### Logger

This is a simple example to print a info log.

```mcfunction
function #unif.logger:logger/v1/debug {"msg": 'Here\'s some messages!', "namespace": "Test"}
```

And then, it will print a log.

![](https://z1.ax1x.com/2023/09/22/pPo6Qw4.png)

### Injected Logger

This is a simple example to print a injected info log.

**Warning: Injected Logger can inject clickable JSON fields like clickEvent.**.

```mcfunction
function #unif.logger:injected_logger/v1/info {"msg": "{\"text\":\"Injected Info Test\"}", "namespace": "Test"}
```

![](https://z1.ax1x.com/2023/09/22/pPoHYLj.png)

```mcfunction
function #unif.logger:injected_logger/v1/info {"msg":"{\"text\":\"Injected Info Test\",\"hoverEvent\":{\"action\":\"show_text\",\"contents\":\"aa\"}}","namespace":"UniF-Logger"}
```

![](https://z1.ax1x.com/2023/09/22/pPoH0YV.png)

### Logs

#### Read logs
You can use the following functions to read logs in the past.

```MCFUNCTION
function #unif.logger:logs/v1/read_all
function #unif.logger:logs/v1/read_debug
function #unif.logger:logs/v1/read_info
function #unif.logger:logs/v1/read_warn
function #unif.logger:logs/v1/read_error
```

#### Clear logs

You can use the following functions to clear logs.

```MCFUNCTION
function #unif.logger:logs/v1/clear_all
function #unif.logger:logs/v1/clear_debug
function #unif.logger:logs/v1/clear_info
function #unif.logger:logs/v1/clear_warn
function #unif.logger:logs/v1/clear_error
```