# `ps` Command Usage Guide

The `ps` (process status) command is used to display information about active processes on a Unix or Linux system.

## Basic Syntax

```
ps [options]
```

## Commonly Used Options

| Option         | Description                                                  |
|----------------|--------------------------------------------------------------|
| `-e` or `-A`   | Show all processes                                           |
| `-f`           | Full-format listing                                          |
| `-u <user>`    | Display processes for a specific user                        |
| `-U <user>`    | Select by real user ID (RUID)                                |
| `-p <pid>`     | Show information for specific PID(s)                         |
| `-o <format>`  | Customize output format (e.g., `pid,comm,%cpu,%mem`)        |
| `x`            | Include processes without a controlling terminal             |
| `--sort`       | Sort output (e.g., `--sort=-%mem`)                           |

## Common Usage Examples

### 1. Show all running processes

```
ps -e
```

### 2. Show all processes with full formatting

```
ps -ef
```

### 3. Show processes for the current user

```
ps -u $USER
```

### 4. Show processes by PID

```
ps -p 1234
```

### 5. Show custom format output

```
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu
```

### 6. Show all processes including those without TTY

```
ps aux
```

### 7. Tree view of processes

```
ps -ejH
```

### 8. Find the PID of the unresponsive process or application.

```
ps -A | grep -i stress
```

### 9.  process tree for a given process 

```
ps -f --forest -C sshd
```

## Custom Output Fields

Use the `-o` option to display specific fields. Common fields include:

- `pid`: Process ID  
- `ppid`: Parent process ID  
- `user`: User name  
- `comm`: Command name  
- `args`: Command with all its arguments  
- `%cpu`: CPU usage  
- `%mem`: Memory usage  
- `etime`: Elapsed time  

**Example:**

```
ps -eo pid,user,comm,etime,%cpu,%mem
```


## Find top running processes by highest memory and CPU usage in Linux.
```
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
```

## Tips

- Combine `ps` with `grep` to filter:

  ```
  ps -ef | grep nginx
  ```

- Use `watch` to monitor in real-time:

  ```
  watch -n 2 'ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head'
  ```


## References

- `man ps`  
- [Linux ps command documentation](https://man7.org/linux/man-pages/man1/ps.1.html)
